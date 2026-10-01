import Foundation
import SwiftData
import Testing
@testable import inkept

/// Two devices, each with its own store, sharing one notes folder the way iCloud Drive shares it.
@MainActor
struct LibraryFolderTests {
    private struct Device {
        let library: LibraryFolder
        let context: ModelContext
        let container: ModelContainer
        let defaults: UserDefaults

        var cards: [Flashcard] { (try? context.fetch(FetchDescriptor<Flashcard>())) ?? [] }
        var reviews: [ReviewLogEntry] { (try? context.fetch(FetchDescriptor<ReviewLogEntry>())) ?? [] }
    }

    private func makeDevice(_ name: String) throws -> Device {
        let container = try TestStore.makeContainer()
        let defaults = try #require(UserDefaults(suiteName: "inkept-library-\(UUID().uuidString)"))
        let library = LibraryFolder(context: container.mainContext, device: name, defaults: defaults, indexURL: nil)
        return Device(library: library, context: container.mainContext, container: container, defaults: defaults)
    }

    private func makeFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("inkept-library-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    /// A card made before any folder was open, with a subject, a deck and the note it came from.
    private func addCard(to device: Device) throws -> Flashcard {
        let (subject, deck, card) = TestStore.makeCard()
        subject.icon = "atom"
        card.sourceNotePath = "Maths/Vectors.md"
        device.context.insert(subject)
        device.context.insert(deck)
        device.context.insert(card)
        try device.context.save()
        return card
    }

    @Test func aLibraryMovesIntoItsFolderAndOpensOnAnotherDevice() async throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let mac = try makeDevice("mac")
        defer { mac.library.detach() }
        let card = try addCard(to: mac)

        await mac.library.attach(to: folder, identity: "notes")
        await mac.library.flush()
        #expect(mac.library.status == .ready)
        let file = folder.appendingPathComponent(".inkept/\(LibraryFiles.path(.cards, card.id))")
        #expect(FileManager.default.fileExists(atPath: file.path))

        let phone = try makeDevice("phone")
        defer { phone.library.detach() }
        await phone.library.attach(to: folder, identity: "notes")
        let arrived = try #require(phone.cards.first)
        #expect(phone.cards.count == 1)
        #expect(arrived.id == card.id)
        #expect(arrived.frontMarkdown == card.frontMarkdown)
        #expect(arrived.sourceNotePath == "Maths/Vectors.md")
        #expect(arrived.deck?.subject?.icon == "atom")
    }

    @Test func editsReviewsUndosAndDeletionsGoBetweenDevices() async throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let mac = try makeDevice("mac")
        let phone = try makeDevice("phone")
        defer {
            mac.library.detach()
            phone.library.detach()
        }
        let card = try addCard(to: mac)
        await mac.library.attach(to: folder, identity: "notes")
        await mac.library.flush()
        await phone.library.attach(to: folder, identity: "notes")

        // An edit.
        card.frontMarkdown = "What is a basis?"
        card.updatedAt = .now
        try mac.context.save()
        await mac.library.flush()
        await phone.library.refresh()
        #expect(phone.cards.first?.frontMarkdown == "What is a basis?")

        // A review, in the phone's own log, and its schedule.
        let phoneCard = try #require(phone.cards.first)
        let review = ReviewService()
        let session = StudySessionRecord(subjectIDs: [], deckID: nil, admittedCardIDs: [phoneCard.id], initialNewCount: 1)
        phone.context.insert(session)
        let candidate = try #require(try review.candidates(for: phoneCard, at: .now, desiredRetention: 0.9)[.good])
        try review.apply(.good, candidate: candidate, to: phoneCard, in: session, context: phone.context, at: .now)
        await phone.library.flush()
        let reviews = folder.appendingPathComponent(".inkept/reviews/phone", isDirectory: true)
        #expect((try? FileManager.default.contentsOfDirectory(atPath: reviews.path))?.count == 1)
        await mac.library.refresh()
        #expect(mac.reviews.count == 1)
        #expect(card.state != .new)

        // Taking it back.
        try review.undoLastReview(in: session, context: phone.context)
        await phone.library.flush()
        await mac.library.refresh()
        #expect(mac.reviews.isEmpty)
        #expect(card.state == .new)

        // A deletion.
        mac.context.delete(card)
        try mac.context.save()
        await mac.library.flush()
        await phone.library.refresh()
        #expect(phone.cards.isEmpty)
    }

    @Test func anotherFolderHoldsItsOwnLibrary() async throws {
        let first = try makeFolder()
        let second = try makeFolder()
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }
        let mac = try makeDevice("mac")
        defer { mac.library.detach() }
        _ = try addCard(to: mac)
        await mac.library.attach(to: first, identity: "first")
        await mac.library.flush()

        await mac.library.attach(to: second, identity: "second")
        #expect(mac.cards.isEmpty)

        await mac.library.attach(to: first, identity: "first")
        #expect(mac.cards.count == 1)
    }

    @Test func aFileStillInICloudIsNotTakenForDeleted() async throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let mac = try makeDevice("mac")
        let phone = try makeDevice("phone")
        defer {
            mac.library.detach()
            phone.library.detach()
        }
        let card = try addCard(to: mac)
        await mac.library.attach(to: folder, identity: "notes")
        await mac.library.flush()
        await phone.library.attach(to: folder, identity: "notes")

        // iOS can take a file back to iCloud and leave a stand-in in its place.
        let cards = folder.appendingPathComponent(".inkept/cards", isDirectory: true)
        try FileManager.default.moveItem(
            at: cards.appendingPathComponent("\(card.id.uuidString).json"),
            to: cards.appendingPathComponent(".\(card.id.uuidString).json.icloud")
        )
        await phone.library.refresh()
        #expect(phone.cards.count == 1)
    }

    @Test func desiredRetentionTravelsWithTheFolder() async throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let mac = try makeDevice("mac")
        let phone = try makeDevice("phone")
        defer {
            mac.library.detach()
            phone.library.detach()
        }
        mac.defaults.set(0.85, forKey: LibraryFolder.retentionKey)
        await mac.library.attach(to: folder, identity: "notes")
        await mac.library.flush()

        await phone.library.attach(to: folder, identity: "notes")
        #expect(phone.defaults.double(forKey: LibraryFolder.retentionKey) == 0.85)
    }
}
