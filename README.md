# remn

remn is a focused, free and open-source flashcard app for iPhone, iPad and Mac. It does one thing:

> create knowledge → review knowledge → remember knowledge

It has two sides: **cards**, reviewed with FSRS, and **notes**, written in a live Markdown editor and kept as plain `.md` files in a folder you choose — so Obsidian or any other editor can open them too. Select a passage in a note to turn it into a card.

There is no account, subscription, advertising, analytics, tracking, or backend. Study data lives in a local SwiftData store and syncs between your devices through your own private iCloud database; remn itself never talks to any server.

## Requirements

- Xcode 26 or newer
- iOS 18 or newer, macOS 15 or newer
- Swift 6
- Rust through [rustup](https://rustup.rs), for the built-in Typst engine:

  ```sh
  rustup target add aarch64-apple-ios aarch64-apple-ios-sim aarch64-apple-darwin x86_64-apple-darwin
  ```

  Xcode builds the engine itself (`Scripts/build-typst.sh`); the first build takes several minutes.

## Build

1. Open `remn.xcodeproj` in Xcode.
2. Let Swift Package Manager resolve the pinned dependencies.
3. Select the `remn` scheme and an iOS 18+ iPhone or iPad, or My Mac.
4. Build and run.

remn is one multiplatform target: the same SwiftUI code runs natively on iOS and macOS.

The project file is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen). The checked-in project is ready to open; regenerating it is optional.

From the command line:

```sh
xcodegen generate
xcodebuild -project remn.xcodeproj -scheme remn \
  -destination 'platform=iOS Simulator,name=<installed iPhone>' test
```

## Sync

Cards, decks, subjects, review history and study sessions sync through CloudKit via SwiftData. The schema is versioned, and every shipped version is kept frozen so existing libraries migrate: `RemnSchemaV1` is the original local-only schema, `RemnSchemaV2` the CloudKit-compatible one (no unique constraints, defaults everywhere, optional relationships), and `RemnSchemaV3` gives each subject an icon. Sync follows the system iCloud settings for the app.

## Scheduling

remn uses FSRS-6 through the Open Spaced Repetition project's `swift-fsrs` package. It intentionally uses the canonical FSRS-6 default parameter vector, 90% desired retention, a 100-year maximum interval, 1-minute and 10-minute learning steps, and a 10-minute relearning step.

Every rating creates a persistent review log. The log stores the full schedule before and after the review so Undo can restore state exactly and future optimizers can use the complete history. Changing desired retention affects subsequent schedules without rewriting history.

## Card syntax

Cards are stored as plain Markdown. Supported content includes:

- paragraphs, headings, emphasis, and lists
- inline code and fenced code blocks with syntax highlighting
- inline math: `$x^2 + y^2 = z^2$`
- display math:

  ```text
  $$
  \nabla_\theta \mathcal{L}(\theta)
  $$
  ```

- fenced code:

  ````text
  ```swift
  actor Cache {
      private var values: [String: Data] = [:]
  }
  ```
  ````

Rendering is native SwiftUI via Textual. The editor keeps Markdown as the source of truth and includes insertion controls for the most useful syntax.

## Notes

Notes are Markdown files in a folder: iCloud Drive (`iCloud Drive/remn`, shared by every device on the same account), a folder on the device, or any folder you pick, such as an Obsidian vault. Folders are subjects and can nest. Front matter holds `tags` and the note's `font`; every other key is kept as it was.

The editor is one live field in the spirit of Obsidian's Live Preview: Markdown punctuation disappears away from the cursor, formulas are typeset, pictures are shown, and each comes back as source when the cursor enters it. It's TextKit 1 underneath (`remn/Notes/Editor`): the text storage always holds the exact Markdown, and hidden characters, pictures and folded lines are handled at the glyph and line-fragment level.

Pictures pasted, dropped or picked go into an `attachments` folder beside the note. Obsidian's `![[image.png]]` embeds work too.

A folder's notes can be shown four ways: as a **list**; as a **board** of pages, each opening with the note's first picture, formula, Typst drawing or code; as a **graph** of how they link, in the manner of Obsidian's — `[[wiki links]]` and Markdown links between notes, links to notes not written yet, the folders they sit in and, if you like, their tags; and as a **timeline** of notes by the day they were written, under twelve weeks of writing rhythm. Beside an open note, **links** shows the notes round it on a small graph, the notes that link to it with the line each link is written in, the notes it links to, and the ones it names that don't exist yet.

A folder can wear an icon from remn's own hand-drawn set — sciences, humanities, technologies, flags for the languages you learn, everyday things — suggested from the folder's name as you type it. The icon is kept in a hidden `.remn.json` inside the folder, so it syncs and moves with the folder, and Obsidian passes it by. Card subjects take icons from the same set.

### Typst

A fenced ` ```typst ` block is compiled on the device by the real [Typst](https://typst.app) compiler (Rust, in `Typst/`, called through a small C interface) and drawn in the note. Everything works offline: fonts are built in, and a curated set of `@preview` packages — CeTZ and cetz-plot, fletcher, quill, timeliney, lilaq, mannot, physica and more — ships inside the app (`remn/Resources/TypstPackages`, refreshed by `Scripts/fetch-typst-packages.py`). Paths in a block are relative to the note's folder, so `#image("attachments/plot.png")` works.

## Backups

Settings → Data can export and import a portable JSON backup. The current schema identifier is `remn-backup-v1`.

A backup preserves subjects, decks, Markdown source, complete FSRS scheduling state, immutable review logs, desired retention, and appearance. Import validates the entire archive before changing the store, then merges objects by UUID. Invalid archives leave the existing library untouched.

Card detail can also render a dedicated high-resolution card layout and save it to Photos.

## Privacy

remn has no remote data layer of its own. The card library is mirrored to the signed-in user's private CloudKit database (container `iCloud.com.chemical-pink.remn`), which only that user can read; without an iCloud account everything stays on the device. Content otherwise leaves the device only when the user explicitly exports a backup or saves a card image.

## License

remn is available under the [MIT License](LICENSE). Dependency acknowledgements are in [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md).

