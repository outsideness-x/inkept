import Testing
@testable import inkept

struct LatexCompatibilityTests {
    @Test func operatorNamesBecomeUprightWithTheirSpace() {
        #expect(LatexCompatibility.rewritten(#"\operatorname{rank} T"#) == #"\mathrm{rank}\, T"#)
        #expect(LatexCompatibility.rewritten(#"\dim V = \operatorname{rank}T + 1"#) == #"\dim V = \mathrm{rank}\, T + 1"#)
    }

    @Test func noSpaceBeforeBracketsLimitsOrTheEnd() {
        #expect(LatexCompatibility.rewritten(#"\operatorname{rank}(A)"#) == #"\mathrm{rank}(A)"#)
        #expect(LatexCompatibility.rewritten(#"\operatorname*{argmax}_x f"#) == #"\mathrm{argmax}_x f"#)
        #expect(LatexCompatibility.rewritten(#"\operatorname{tr}"#) == #"\mathrm{tr}"#)
        #expect(LatexCompatibility.rewritten(#"\operatorname{tr}\left(A\right)"#) == #"\mathrm{tr}\left(A\right)"#)
    }

    @Test func otherLatexIsLeftAlone() {
        #expect(LatexCompatibility.rewritten(#"\frac{a}{b} + \det A"#) == #"\frac{a}{b} + \det A"#)
    }
}
