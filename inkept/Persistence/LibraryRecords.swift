import Foundation

// The plain records the library is written down as, in a backup and in the notes folder,
// and how each one is read from the store and put back into it.

extension BackupSubject {
    init(_ subject: SubjectModel) {
        self.init(
            id: subject.id,
            name: subject.name,
            createdAt: subject.createdAt,
            updatedAt: subject.updatedAt,
            manualSortOrder: subject.manualSortOrder,
            icon: subject.icon
        )
    }
}

extension BackupDeck {
    /// Nil for a deck that has lost its subject.
    init?(_ deck: Deck) {
        guard let subjectID = deck.subject?.id else { return nil }
        self.init(
            id: deck.id,
            subjectID: subjectID,
            name: deck.name,
            createdAt: deck.createdAt,
            updatedAt: deck.updatedAt,
            manualSortOrder: deck.manualSortOrder
        )
    }
}

extension BackupCard {
    /// Nil for a card that has lost its deck.
    init?(_ card: Flashcard) {
        guard let deckID = card.deck?.id else { return nil }
        self.init(
            id: card.id,
            deckID: deckID,
            frontMarkdown: card.frontMarkdown,
            backMarkdown: card.backMarkdown,
            createdAt: card.createdAt,
            updatedAt: card.updatedAt,
            schedule: card.scheduleSnapshot,
            sourceNotePath: card.sourceNotePath
        )
    }
}

extension BackupReviewLog {
    /// Nil for a review whose card is gone.
    init?(_ log: ReviewLogEntry) {
        guard let cardID = log.card?.id else { return nil }
        self.init(
            id: log.id,
            cardID: cardID,
            timestamp: log.timestamp,
            ratingRaw: log.ratingRaw,
            elapsedInterval: log.elapsedInterval,
            scheduledInterval: log.scheduledInterval,
            previous: log.previousSnapshot,
            resulting: log.resultingSnapshot
        )
    }
}

extension SubjectModel {
    convenience init(_ record: BackupSubject) {
        self.init(
            id: record.id,
            name: record.name,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            manualSortOrder: record.manualSortOrder,
            icon: record.icon
        )
    }

    func update(from record: BackupSubject) {
        name = record.name
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        manualSortOrder = record.manualSortOrder
        icon = record.icon
    }
}

extension Deck {
    convenience init(_ record: BackupDeck, subject: SubjectModel) {
        self.init(
            id: record.id,
            subject: subject,
            name: record.name,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            manualSortOrder: record.manualSortOrder
        )
    }

    func update(from record: BackupDeck, subject: SubjectModel) {
        self.subject = subject
        name = record.name
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        manualSortOrder = record.manualSortOrder
    }
}

extension Flashcard {
    convenience init(_ record: BackupCard, deck: Deck) {
        self.init(
            id: record.id,
            deck: deck,
            frontMarkdown: record.frontMarkdown,
            backMarkdown: record.backMarkdown,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            sourceNotePath: record.sourceNotePath
        )
        scheduleSnapshot = record.schedule
    }

    func update(from record: BackupCard, deck: Deck) {
        self.deck = deck
        frontMarkdown = record.frontMarkdown
        backMarkdown = record.backMarkdown
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        sourceNotePath = record.sourceNotePath
        scheduleSnapshot = record.schedule
    }
}

extension ReviewLogEntry {
    /// Nil when the record's rating isn't one the app knows.
    convenience init?(_ record: BackupReviewLog, card: Flashcard) {
        guard let rating = StudyRating(rawValue: record.ratingRaw) else { return nil }
        self.init(
            id: record.id,
            card: card,
            timestamp: record.timestamp,
            rating: rating,
            previous: record.previous,
            resulting: record.resulting,
            elapsedInterval: record.elapsedInterval,
            scheduledInterval: record.scheduledInterval
        )
    }
}
