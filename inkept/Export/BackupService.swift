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
            subjects: subjects.map(BackupSubject.init),
            decks: decks.compactMap(BackupDeck.init),
            cards: cards.compactMap(BackupCard.init),
            reviewLogs: logs.compactMap(BackupReviewLog.init)
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
                    subject.update(from: value)
                } else {
                    let subject = SubjectModel(value)
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
                    deck.update(from: value, subject: subject)
                } else {
                    let deck = Deck(value, subject: subject)
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
                    card.update(from: value, deck: deck)
                } else {
                    let card = Flashcard(value, deck: deck)
                    context.insert(card)
                    cards[value.id] = card
                }
            }

            let existingLogIDs = Set(try context.fetch(FetchDescriptor<ReviewLogEntry>()).map(\.id))
            for value in archive.reviewLogs where !existingLogIDs.contains(value.id) {
                guard let card = cards[value.cardID], let log = ReviewLogEntry(value, card: card) else {
                    throw BackupError.brokenRelationship
                }
                context.insert(log)
            }
            try context.save()
            return archive.settings
        } catch {
            context.rollback()
            throw error
        }
    }

    static func validate(_ archive: BackupArchive) throws {
        guard BackupArchive.readableSchemas.contains(archive.schema) else { throw BackupError.unsupportedSchema }
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
}
