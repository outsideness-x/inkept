import Foundation

/// Where inkept lives on the web: its source, and the pages the App Store points people to.
enum InkeptLinks {
    static let repository = URL(string: "https://github.com/outsideness-x/inkept")!
    static let privacy = document("PRIVACY.md")
    static let license = document("LICENSE")
    static let acknowledgements = document("ACKNOWLEDGEMENTS.md")
    static let support = document("SUPPORT.md")

    private static func document(_ name: String) -> URL {
        repository.appending(path: "blob/main/\(name)")
    }
}
