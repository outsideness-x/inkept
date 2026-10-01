import Foundation
import SwiftData

@Model
final class StudySessionRecord: Identifiable {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var isActive: Bool = true
    var subjectIDs: [UUID] = []
    var deckID: UUID?
    var admittedCardIDs: [UUID] = []
    var queueCardIDs: [UUID] = []
    var lastReviewLogID: UUID?
    var reviewedCount: Int = 0
    var initialNewCount: Int = 0

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        subjectIDs: [UUID],
        deckID: UUID?,
        admittedCardIDs: [UUID],
        initialNewCount: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isActive = true
        self.subjectIDs = subjectIDs
        self.deckID = deckID
        self.admittedCardIDs = admittedCardIDs
        self.queueCardIDs = admittedCardIDs
        self.reviewedCount = 0
        self.initialNewCount = initialNewCount
    }
}
