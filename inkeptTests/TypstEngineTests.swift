import CoreGraphics
import Foundation
import Testing
@testable import inkept

struct TypstEngineTests {
    @Test func drawsMathTrimmedToItsInk() async throws {
        let image = try await TypstEngine.shared.render(
            "$ integral_0^1 x^2 dif x = 1/3 $",
            width: 320, fontSize: 17, handwritten: true, folder: nil, scale: 2, dark: false
        )
        #expect(image.width > 40 && image.width < 640)
        #expect(image.height > 20)
    }

    @Test func everyTemplateCompilesOffline() async throws {
        #expect(!TypstTemplate.all.isEmpty)
        for template in TypstTemplate.all {
            let image = try await TypstEngine.shared.render(
                template.source, width: 330, fontSize: 15, handwritten: true, folder: nil, scale: 1, dark: true
            )
            #expect(image.width > 0, "\(template.id)")
        }
    }

    @Test func mistakesComeBackAsMessages() async {
        do {
            _ = try await TypstEngine.shared.render(
                "#import \"@preview/not-shipped:0.1.0\": *",
                width: 320, fontSize: 17, handwritten: false, folder: nil, scale: 2, dark: false
            )
            Issue.record("a missing package should fail")
        } catch let failure as TypstEngine.Failure {
            #expect(failure.message.contains("not-shipped"))
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }
}
