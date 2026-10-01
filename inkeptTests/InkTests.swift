import SwiftUI
import Testing
@testable import inkept

struct InkTests {
    @Test func randomnessIsRepeatableForASeed() {
        var first = InkRandom(seed: 42)
        var second = InkRandom(seed: 42)
        for _ in 0..<32 {
            #expect(first.next() == second.next())
        }
        var other = InkRandom(seed: 43)
        #expect(InkRandom(seed: 42).peek() != other.next())
    }

    @Test func noiseStaysInRangeAndIsSmooth() {
        var previous = InkNoise.value(0, seed: 7)
        for step in 1...400 {
            let value = InkNoise.value(CGFloat(step) * 0.05, seed: 7)
            #expect(value >= -1 && value <= 1)
            #expect(abs(value - previous) < 0.25)
            previous = value
        }
    }

    @Test func seedsSurviveRelaunches() throws {
        let id = try #require(UUID(uuidString: "5F0C9A52-2B7E-4C41-9D3A-3A0C2E4F9B11"))
        #expect(id.inkSeed == 6_849_018_811_031_374_913)
        #expect("inkept".inkSeed == "inkept".inkSeed)
        #expect("inkept".inkSeed != "inkept.".inkSeed)
    }

    @Test func aHandDrawnBoxKeepsItsShape() {
        let rect = CGRect(x: 0, y: 0, width: 320, height: 180)
        let first = InkRoundedRect(seed: 9).path(in: rect)
        let again = InkRoundedRect(seed: 9).path(in: rect)
        let other = InkRoundedRect(seed: 10).path(in: rect)
        #expect(first.description == again.description)
        #expect(first.description != other.description)
        #expect(first.boundingRect.insetBy(dx: -4, dy: -4).contains(rect))
    }

    @Test func drawingOnGrowsTheStroke() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 10)
        let empty = InkLine(seed: 3, progress: 0).path(in: rect)
        let half = InkLine(seed: 3, progress: 0.5).path(in: rect)
        let full = InkLine(seed: 3, progress: 1).path(in: rect)
        #expect(empty.isEmpty)
        #expect(half.boundingRect.width < full.boundingRect.width)
        #expect(full.boundingRect.width > 190)
    }
}

private extension InkRandom {
    func peek() -> UInt64 {
        var copy = self
        return copy.next()
    }
}
