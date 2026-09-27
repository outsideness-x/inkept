# Dependency acknowledgements

remn uses the following open-source Swift packages:

- [swift-fsrs](https://github.com/open-spaced-repetition/swift-fsrs), an FSRS-6 implementation from the Open Spaced Repetition ecosystem — MIT License.
- [Textual](https://github.com/gonzalezreal/textual), native SwiftUI Markdown, math, code, and structured-text rendering — MIT License.
- Textual's transitive dependencies, [SwiftUI Math](https://github.com/gonzalezreal/swiftui-math) and [Swift Concurrency Extras](https://github.com/pointfreeco/swift-concurrency-extras), under their respective repository licenses.
- [Neucha](https://github.com/google/fonts/tree/main/ofl/neucha) by Jovanny Lemonad — SIL Open Font License 1.1. The complete license is bundled at `remn/Resources/Fonts/OFL-Neucha.txt`.

## Subject icons

The subject icons (`remn/SubjectIcons`) are drawn for remn in its own ink-and-pencil hand. Some sketch the marks of the products, languages and countries a subject can be about — flags, and logos such as Apple's, Android's, Claude's, Python's or Git's — only to label notes and cards on those subjects. The marks belong to their owners, who don't endorse remn.

- The Android robot is reproduced or modified from work created and shared by Google and used according to terms described in the [Creative Commons 3.0 Attribution License](https://creativecommons.org/licenses/by/3.0/).
- The [Git logo](https://git-scm.com/downloads/logos) is by Jason Long, licensed under CC BY 3.0.
- The [HTML5 logo](https://www.w3.org/html/logo/) is by the W3C, licensed under CC BY 3.0.
- Tux, the Linux penguin, was first drawn by Larry Ewing with the GIMP.

## Typst

- [Typst](https://github.com/typst/typst), the typesetting compiler built into the notes editor (`Typst/`) — Apache License 2.0. Its bundled fonts come from [typst-assets](https://github.com/typst/typst-assets): Libertinus Serif, New Computer Modern and New Computer Modern Math (SIL Open Font License 1.1) and DejaVu Sans Mono (Bitstream Vera license).
- Typst packages shipped for offline use in `remn/Resources/TypstPackages`, each with its license in its folder:
  - [CeTZ](https://github.com/cetz-package/cetz) and [cetz-plot](https://github.com/cetz-package/cetz-plot) — GNU LGPL 3.0 or later, shipped as their unmodified Typst sources.
  - cetz-venn, chronos — Apache License 2.0.
  - alchemist, curryst, diagraph-layout, finite, fletcher, gentle-clues, komet, lilaq, linguify, lovelace, mannot, physica, quill, showybox, suiji, t4t, tablem, tidy, timeliney, tiptoe, unify, valkyrie, zero — MIT License.
  - elembic, oxifmt 1.0 — MIT or Apache 2.0; oxifmt 0.2 — MIT No Attribution.

The exact resolved versions are recorded in `remn.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
