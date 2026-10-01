import Testing
@testable import inkept

@MainActor
struct TypographyTests {
    @Test func bundledDisplayFontIsRegistered() {
        #expect(RemnTypography.isDisplayFontAvailable)
    }
}
