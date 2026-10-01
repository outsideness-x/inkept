import Foundation
import SwiftData

enum BackupError: LocalizedError {
    case unsupportedSchema
    case duplicateIdentifiers
    case brokenRelationship
    case invalidSetting

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema: String(localized: "backup.error.schema")
        case .duplicateIdentifiers: String(localized: "backup.error.duplicates")
        case .brokenRelationship: String(localized: "backup.error.relationships")
        case .invalidSetting: String(localized: "backup.error.settings")
        }
    }
}

@MainActor
enum BackupService {
    static func export(
        context: ModelContext,
        settings: BackupSettings,
        at date: Date = .now
    ) throws -> Data {
        let subjects = try context.fetch(FetchDescriptor<SubjectModel>())
        let decks = try context.fetch(FetchDescriptor<Deck>())
        let cards = try context.fetch(FetchDescriptor<Flashcard>())
        let logs = try context.fetch(FetchDescriptor<ReviewLogEntry>())

        let archive = BackupArchive(
            schema: BackupArchive.currentSchema,
            exportedAt: date,
            settings: settings,
            subjects: subjects.map {
                BackupSubject(
                    id: $0.id,
                    name: $0.name,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
                    manualSortOrder: $0.manualSortOrder,
                    icon: $0.icon
                )
            },
            decks: decks.compactMap { deck in
                guard let subjectID = deck.subject?.id else { return nil }
                return BackupDeck(
                    id: deck.id,
                    subjectID: subjectID,
                    name: deck.name,
                    createdAt: deck.createdAt,
                    updatedAt: deck.updatedAt,
                    manualSortOrder: deck.manualSortOrder
                )
            },
            cards: cards.compactMap { card in
                guard let deckID = card.deck?.id else { return nil }
                return BackupCard(
                    id: card.id,
                    deckID: deckID,
                    frontMarkdown: card.frontMarkdown,
                    backMarkdown: card.backMarkdown,
                    createdAt: card.createdAt,
                    updatedAt: card.updatedAt,
                    schedule: card.scheduleSnapshot
                )
            },
            reviewLogs: logs.compactMap(makeBackupLog)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(archive)
    }

    static func decode(_ data: Data) throws -> BackupArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let archive = try decoder.decode(BackupArchive.self, from: data)
        try validate(archive)
        return archive
    }

    static func importArchive(_ archive: BackupArchive, context: ModelContext) throws -> BackupSettings {
        try validate(archive)
        do {
            var subjects = Dictionary(
                uniqueKeysWithValues: try context.fetch(FetchDescriptor<SubjectModel>()).map { ($0.id, $0) }
            )
            for value in archive.subjects {
                if let subject = subjects[value.id] {
                    subject.name = value.name
                    subject.createdAt = value.createdAt
                    subject.updatedAt = value.updatedAt
                    subject.manualSortOrder = value.manualSortOrder
                    subject.icon = value.icon
                } else {
                    let subject = SubjectModel(
                        id: value.id,
                        name: value.name,
                        createdAt: value.createdAt,
                        updatedAt: value.updatedAt,
                        manualSortOrder: value.manualSortOrder,
                        icon: value.icon
                    )
                    context.insert(subject)
                    subjects[value.id] = subject
                }
            }

            var decks = Dictionary(
                uniqueKeysWithValues: try context.fetch(FetchDescriptor<Deck>()).map { ($0.id, $0) }
            )
            for value in archive.decks {
                guard let subject = subjects[value.subjectID] else { throw BackupError.brokenRelationship }
                if let deck = decks[value.id] {
                    deck.subject = subject
                    deck.name = value.name
                    deck.createdAt = value.createdAt
                    deck.updatedAt = value.updatedAt
                    deck.manualSortOrder = value.manualSortOrder
                } else {
                    let deck = Deck(
                        id: value.id,
                        subject: subject,
                        name: value.name,
                        createdAt: value.createdAt,
                        updatedAt: value.updatedAt,
                        manualSortOrder: value.manualSortOrder
                    )
                    context.insert(deck)
                    decks[value.id] = deck
                }
            }

            var cards = Dictionary(
                uniqueKeysWithValues: try context.fetch(FetchDescriptor<Flashcard>()).map { ($0.id, $0) }
            )
            for value in archive.cards {
                guard let deck = decks[value.deckID] else { throw BackupError.brokenRelationship }
                if let card = cards[value.id] {
                    card.deck = deck
                    card.frontMarkdown = value.frontMarkdown
                    card.backMarkdown = value.backMarkdown
                    card.createdAt = value.createdAt
                    card.updatedAt = value.updatedAt
                    card.scheduleSnapshot = value.schedule
                } else {
                    let card = Flashcard(
                        id: value.id,
                        deck: deck,
                        frontMarkdown: value.frontMarkdown,
                        backMarkdown: value.backMarkdown,
                        createdAt: value.createdAt,
                        updatedAt: value.updatedAt
                    )
                    card.scheduleSnapshot = value.schedule
                    context.insert(card)
                    cards[value.id] = card
                }
            }

            let existingLogIDs = Set(try context.fetch(FetchDescriptor<ReviewLogEntry>()).map(\.id))
            for value in archive.reviewLogs where !existingLogIDs.contains(value.id) {
                guard
                    let card = cards[value.cardID],
                    let rating = StudyRating(rawValue: value.ratingRaw)
                else { throw BackupError.brokenRelationship }
                context.insert(
                    ReviewLogEntry(
                        id: value.id,
                        card: card,
                        timestamp: value.timestamp,
                        rating: rating,
                        previous: value.previous,
                        resulting: value.resulting,
                        elapsedInterval: value.elapsedInterval,
                        scheduledInterval: value.scheduledInterval
                    )
                )
            }
            try context.save()
            return archive.settings
        } catch {
            context.rollback()
            throw error
        }
    }

    static func validate(_ archive: BackupArchive) throws {
        guard archive.schema == BackupArchive.currentSchema else { throw BackupError.unsupportedSchema }
        guard (0.70...0.97).contains(archive.settings.desiredRetention),
              AppearanceMode(rawValue: archive.settings.appearanceMode) != nil
        else { throw BackupError.invalidSetting }

        guard unique(archive.subjects.map(\.id)),
              unique(archive.decks.map(\.id)),
              unique(archive.cards.map(\.id)),
              unique(archive.reviewLogs.map(\.id))
        else { throw BackupError.duplicateIdentifiers }

        let subjectIDs = Set(archive.subjects.map(\.id))
        let deckIDs = Set(archive.decks.map(\.id))
        let cardIDs = Set(archive.cards.map(\.id))
        guard archive.decks.allSatisfy({ subjectIDs.contains($0.subjectID) }),
              archive.cards.allSatisfy({ deckIDs.contains($0.deckID) }),
              archive.reviewLogs.allSatisfy({ cardIDs.contains($0.cardID) })
        else { throw BackupError.brokenRelationship }
    }

    private static func unique(_ ids: [UUID]) -> Bool { Set(ids).count == ids.count }

    private static func makeBackupLog(_ log: ReviewLogEntry) -> BackupReviewLog? {
        guard let cardID = log.card?.id else { return nil }
        return BackupReviewLog(
            id: log.id,
            cardID: cardID,
            timestamp: log.timestamp,
            ratingRaw: log.ratingRaw,
            elapsedInterval: log.elapsedInterval,
            scheduledInterval: log.scheduledInterval,
            previous: log.previousSnapshot,
            resulting: ScheduleSnapshot(
                stateRaw: log.resultingStateRaw,
                due: log.resultingDue,
                lastReview: log.resultingLastReview,
                stability: log.resultingStability,
                difficulty: log.resultingDifficulty,
                elapsedDays: log.resultingElapsedDays,
                scheduledDays: log.resultingScheduledDays,
                learningStep: log.resultingLearningStep,
                repetitions: log.resultingRepetitions,
                lapses: log.resultingLapses
            )
        )
    }
}
