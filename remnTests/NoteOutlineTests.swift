import Foundation
import Testing
@testable import remn

struct NoteOutlineTests {
    @Test func linksAreReadOnceAndCodeIsLeftAlone() {
        let outline = NoteOutline("""
        See [[Vector spaces]], [[Eigenvalues#Why it matters|why]] and [[Vector spaces]] again.
        Also [the basis](Linear%20Algebra/Basis.md#definition), [a site](https://example.com/page.md) and ![[Proof]].
        `[[not a link]]`
        ```
        [[also not]]
        ```
        """)
        #expect(outline.links == [
            NoteLink(kind: .wiki, target: "Vector spaces"),
            NoteLink(kind: .wiki, target: "Eigenvalues"),
            NoteLink(kind: .wiki, target: "Proof"),
            NoteLink(kind: .path, target: "Linear Algebra/Basis.md"),
        ])
    }

    @Test func theFirstFigureIsTheCover() {
        #expect(NoteOutline("Words\n\n![](attachments/cell.png)\n\n$$\nx\n$$").cover == .image("attachments/cell.png"))
        #expect(NoteOutline("Words\n\n![[plot.png]]").cover == .image("plot.png"))
        #expect(NoteOutline("$$\nA v = \\lambda v\n$$\n![](a.png)").cover == .math("A v = \\lambda v"))
        #expect(NoteOutline("$$e^{i\\pi} = -1$$").cover == .math("e^{i\\pi} = -1"))
        #expect(NoteOutline("```typst\n$ x^2 $\n```").cover == .typst("$ x^2 $"))
        #expect(NoteOutline("```swift\nactor A {}\n```").cover == .code(language: "swift", lines: ["actor A {}"]))
        #expect(NoteOutline("```\n\n```\nplain").cover == nil)
        #expect(NoteOutline("Just words.").cover == nil)
    }

    @Test func theExcerptReadsLikeText() {
        let outline = NoteOutline("""
        # Eigenvalues

        A **non-zero** vector $v$ is an eigenvector of [[Matrix|a matrix]] when $A v = \\lambda v$.

        - diagonalisation
        - [x] read chapter 5
        > the trace is the sum
        """)
        #expect(outline.excerpt == """
        A non-zero vector v is an eigenvector of a matrix when A v = λ v.
        • diagonalisation
        • read chapter 5
        the trace is the sum
        """)
        #expect(NoteOutline(String(repeating: "word ", count: 100), excerptLimit: 20).excerpt.count == 21)
    }

    @Test func tagsALineEndsWithAreLeftOffPreviews() {
        #expect(NoteText.plain("Energy is conserved. #physics #exam") == "Energy is conserved.")
        #expect(NoteText.plain("#physics") == "")
        #expect(NoteText.plain("A #physics note, in C# and #1") == "A #physics note, in C# and #1")
        #expect(NoteOutline("Rank decides it. #linear-algebra\n#exam").excerpt == "Rank decides it.")
    }

    @Test func longNotesAreReadQuickly() {
        let paragraph = "A line of plain words about eigenvectors, with a [[link]] now and then and $x^2$ in it.\n"
        let note = String(repeating: "Plain words, nothing to find here at all.\n", count: 3_000) + String(repeating: paragraph, count: 500)
        let elapsed = ContinuousClock().measure { _ = NoteOutline(note) }
        #expect(elapsed < .seconds(1))
    }

    @Test func formulasReadAsTheyWouldOnPaper() {
        #expect(NoteText.readable(latex: #"\lambda^2 \le \frac{a}{b}"#) == "λ² ≤ a/b")
        #expect(NoteText.readable(latex: #"A^{-1}"#) == "A⁻¹")
        #expect(NoteText.readable(latex: #"x_1 + x_2"#) == "x₁ + x₂")
        #expect(NoteText.readable(latex: #"\mathbb{R}^n"#) == "ℝⁿ")
        #expect(NoteText.readable(latex: #"\det(A - \lambda I) = 0"#) == "det(A - λ I) = 0")
        #expect(NoteText.readable(latex: #"\operatorname{rank} T"#) == "rank T")
        #expect(NoteText.readableMath(in: "costs $5 and $x^2$") == "costs $5 and x²")
        #expect(NoteText.snippet(of: "An eigenvector $v$ of $A$") == "An eigenvector v of A")
    }
}
