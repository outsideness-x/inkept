import XCTest
@testable import inkept

@MainActor
final class SearchTests: XCTestCase {
    func testSearchIsCaseAndDiacriticInsensitiveAcrossAllFields() {
        let (_, _, card) = TestStore.makeCard(
            subjectName: "Matemáticas",
            deckName: "Álgebra Lineal",
            front: "Что такое ВЕКТОР?",
            back: "Direction and magnitude"
        )
        XCTAssertTrue(CardSearch.matches(card, query: "вектор"))
        XCTAssertTrue(CardSearch.matches(card, query: "algebra"))
        XCTAssertTrue(CardSearch.matches(card, query: "matematicas"))
        XCTAssertTrue(CardSearch.matches(card, query: "MAGNITUDE"))
        XCTAssertFalse(CardSearch.matches(card, query: "topology"))
    }
}

