import Foundation

extension Flashcard {
    var deckContext: String {
        [deck?.subject?.name, deck?.name]
            .compactMap { $0 }
            .joined(separator: " / ")
    }
}

