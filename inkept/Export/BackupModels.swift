import Foundation

struct BackupArchive: Codable, Equatable, Sendable {
    static let currentSchema = "remn-backup-v1"

    var schema: String
    var exportedAt: Date
    var settings: BackupSettings
    var subjects: [BackupSubject]
    var decks: [BackupDeck]
    var cards: [BackupCard]
    var reviewLogs: [BackupReviewLog]
}

struct BackupSettings: Codable, Equatable, Sendable {
    var desiredRetention: Double
    var appearanceMode: String
}

struct BackupSubject: Codable, Equatable, Sendable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var manualSortOrder: Int
    /// Missing from backups made before subjects had icons.
    var icon: String?
}

struct BackupDeck: Codable, Equatable, Sendable {
    var id: UUID
    var subjectID: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var manualSortOrder: Int
}

struct BackupCard: Codable, Equatable, Sendable {
    var id: UUID
    var deckID: UUID
    var frontMarkdown: String
    var backMarkdown: String
    var createdAt: Date
    var updatedAt: Date
    var schedule: ScheduleSnapshot
}

struct BackupReviewLog: Codable, Equatable, Sendable {
    var id: UUID
    var cardID: UUID
    var timestamp: Date
    var ratingRaw: Int
    var elapsedInterval: Double
    var scheduledInterval: Double
    var previous: ScheduleSnapshot
    var resulting: ScheduleSnapshot
}

