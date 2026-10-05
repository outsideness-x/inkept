# inkept on the App Store

Everything App Store Connect asks for, ready to paste, and the screenshots in [`Screenshots`](Screenshots). The app is one universal purchase for iPhone, iPad and Mac: bundle identifier `com.chemical-pink.inkept`, iCloud container `iCloud.com.chemical-pink.inkept`.

## Release checklist

In the repository (done):

- [x] Icon as an Icon Composer document, with light, dark and tinted appearances (`inkept/Resources/AppIcon.icon`)
- [x] Privacy manifest (`inkept/Resources/PrivacyInfo.xcprivacy`): no tracking, no data collected; the required-reason APIs it uses are user defaults (CA92.1) and file dates (C617.1, 3B52.1, DDA9.1)
- [x] `ITSAppUsesNonExemptEncryption` = NO, so uploads don't ask about export compliance
- [x] Photo library usage text in English and Russian (`inkept/Resources/InfoPlist.xcstrings`)
- [x] Mac: App Sandbox and Hardened Runtime on; only the entitlements the app uses — iCloud Documents and files the person chooses (no network)
- [x] [Privacy policy](../PRIVACY.md), [help page](../SUPPORT.md), [license](../LICENSE) and [acknowledgements](../ACKNOWLEDGEMENTS.md), linked from Settings → about
- [x] Version 1.0 (build 1)
- [ ] A contact email on the [help page](../SUPPORT.md): App Store Connect's help says the Support URL has to lead to contact details, and opening an issue takes a GitHub account
- [ ] The iPad and Mac screenshots made again (`Scripts/aso-screenshots.sh ipad mac`): in `1-study` the card's formula `\det A \neq 0` shows as a lone `0`, which `CardContentView` now fixes

In App Store Connect and the developer account (by hand):

- [ ] Certificates, Identifiers & Profiles: the App ID `com.chemical-pink.inkept` has iCloud (CloudKit support not needed — iCloud Documents only) with the container `iCloud.com.chemical-pink.inkept`
- [ ] Business → Digital Services Act: the account's trader status (a non-trader, for a free app with no business behind it). Submissions wait on it, and without it the app stays out of the EU
- [ ] A new app record for iOS and macOS with that bundle identifier, primary language English, and Russian added as a localisation
- [ ] Archive the `inkept` scheme for Any iOS Device and for Any Mac in Xcode (Product → Archive) and upload both builds
- [ ] Before submitting, install both builds from TestFlight and go through the review notes below on an iPhone or iPad and on the Mac, starting from a fresh install
- [ ] Paste the text below for each language, add the screenshots, set the URLs, answer the questionnaires
- [ ] App Privacy: "No, we do not collect data from this app", then **Publish** — a submission waits on it
- [ ] Price: free, all territories. If App Store Connect asks for an ICP filing number for China mainland, leave China mainland out
- [ ] Apple Vision Pro: untick "Make this app available" under Pricing and Availability, unless it's been tried there — the iPad app goes to Vision Pro by default
- [ ] App Review Information: sign-in not required; a name, phone and email for the reviewer; the notes below
- [ ] Version release: manual, so the iPhone, iPad and Mac versions go out together
- [ ] Submit both platforms for review together

## URLs

| Field | URL |
| --- | --- |
| Privacy Policy URL | https://github.com/outsideness-x/inkept/blob/main/PRIVACY.md |
| Support URL | https://github.com/outsideness-x/inkept/blob/main/SUPPORT.md |
| Marketing URL | https://github.com/outsideness-x/inkept |

## Categories, age rating, privacy

- **Primary category:** Education. **Secondary:** Productivity.
- **Age rating:** 4+. Every questionnaire answer is "None" or "No". There's no unrestricted web access: links open in the system browser, not inside the app.
- **App Privacy:** Data Not Collected.
- **Content rights:** yes, it contains third-party content — the open-source fonts and Typst packages it ships, credited in [ACKNOWLEDGEMENTS.md](../ACKNOWLEDGEMENTS.md) — and yes, it has the rights to use it. Nothing comes from the internet.
- **Copyright:** 2026 chemical-pink

## App Review notes

> inkept needs no account and no network connection. When it first asks where to keep everything:
> - on iPhone and iPad, choose "on this device" — it works straight away;
> - on the Mac, choose "choose a folder…" and pick or make any folder, for example in Documents;
> - iCloud Drive works on all of them when the device is signed in to iCloud.
>
> Notes: write a note; select some text and tap the card button (or ⇧⌘K) to make a flashcard from it. The list / board / graph / timeline switch at the top shows the notes in different ways — the graph is the map of how notes link.
> Cards: create a subject and a deck, add cards, and study them; ratings schedule the next review with FSRS.
> Settings → about links to the privacy policy, license, source code and help page.

## English

**Name** (30)
```
inkept: Flashcards & Notes
```

**Subtitle** (30)
```
Spaced repetition & Markdown
```

**Promotional text** (170)
```
Write notes in Markdown, turn any passage into a flashcard, and review it just before you'd forget. Free, open source, no account — your notes stay plain files.
```

**Keywords** (100 bytes)
```
fsrs,study,memorize,latex,math,vocabulary,exam,learn,srs,memory,typst,revise,quiz,recall,wiki,cards
```

**Description**
```
inkept is a quiet place for the things worth remembering: the notes you write, and the flashcards you review until they stick.

WRITE NOTES
• A live Markdown editor in the spirit of Obsidian: the formatting steps aside as you write and comes back when you touch it.
• Formulas in LaTeX, code with syntax highlighting, pictures, checklists and tables.
• Real Typst, built in: plots, diagrams, circuits and molecules drawn right inside your notes, offline.
• [[Wiki links]] between notes, tags, and folders that wear hand-drawn icons.

SEE HOW IT CONNECTS
• A graph of your notes, like Obsidian's: each subject in its own colour, the links between notes, and a map that glides as you explore it.
• A board of pages, a timeline of what you wrote when, and the links around every note.

REMEMBER IT
• Select a passage in a note and make it a flashcard.
• Reviews are scheduled by FSRS, a modern spaced-repetition algorithm, so each card comes back just before you'd forget it.
• Choose how much you want to remember, undo any rating, and study by subject or deck.

YOURS, ON YOUR DEVICES
• Everything is plain files in a folder you choose: iCloud Drive, your device, or an Obsidian vault you already have.
• Choose the same folder on your iPhone, iPad and Mac and carry on where you left off.
• No account, no subscription, no ads, no tracking. inkept collects nothing.
• Free and open source under the MIT license.

Drawn by hand: the whole app is ink and coloured pencil on paper, in light and in dark.
```

## Русский

**Название** (30)
```
inkept: карточки и конспекты
```

**Подзаголовок** (30)
```
Интервальные повторения FSRS
```

**Рекламный текст** (170)
```
Пишите конспекты в Markdown, превращайте любой фрагмент в карточку и повторяйте её прямо перед тем, как забыли бы. Бесплатно, с открытым кодом, без аккаунта.
```

**Ключевые слова** (100 bytes: a Cyrillic letter takes two)
```
учить,запомнить,слова,экзамен,егэ,формулы,latex,markdown,огэ
```

**Описание**
```
inkept — тихое место для того, что стоит запомнить: конспектов, которые вы пишете, и карточек, которые вы повторяете, пока не запомните.

ПИШИТЕ КОНСПЕКТЫ
• Живой редактор Markdown в духе Obsidian: разметка отходит в сторону, пока вы пишете, и возвращается, когда вы к ней прикасаетесь.
• Формулы на LaTeX, код с подсветкой, картинки, списки дел и таблицы.
• Настоящий Typst внутри: графики, схемы, цепи и молекулы рисуются прямо в конспекте, без интернета.
• [[Вики-ссылки]] между конспектами, теги и папки с нарисованными от руки значками.

СМОТРИТЕ, КАК ВСЁ СВЯЗАНО
• Граф конспектов, как в Obsidian: у каждого предмета свой цвет, видны связи между конспектами, а карта плавно движется, пока вы её исследуете.
• Доска страниц, лента того, что и когда вы написали, и связи вокруг каждого конспекта.

ЗАПОМИНАЙТЕ
• Выделите фрагмент конспекта — и сделайте из него карточку.
• Повторения расписывает FSRS — современный алгоритм интервальных повторений: каждая карточка возвращается прямо перед тем, как вы бы её забыли.
• Выбирайте, сколько хотите помнить, отменяйте любую оценку, учите по предметам или колодам.

ВАШЕ И НА ВАШИХ УСТРОЙСТВАХ
• Всё хранится обычными файлами в папке, которую вы выбрали: в iCloud Drive, на устройстве или в уже существующем хранилище Obsidian.
• Выберите ту же папку на iPhone, iPad и Mac — и продолжайте с того же места.
• Без аккаунта, подписки, рекламы и слежки. inkept ничего не собирает.
• Бесплатно и с открытым кодом, лицензия MIT.

Нарисовано от руки: всё приложение — тушь и цветные карандаши на бумаге, в светлом и в тёмном оформлении.
```

## Screenshots

In English, for every language: a localisation without screenshots of its own shows these. Made from the app itself, running the demo library (`-demoLibrary`), then laid out with a caption in the app's own hand. Each set is at the size App Store Connect asks for, so it covers every smaller display of its kind:

| Folder | Device | Size |
| --- | --- | --- |
| `Screenshots/iphone` | iPhone 6.9″ | 1320 × 2868 |
| `Screenshots/ipad` | iPad 13″ | 2064 × 2752 |
| `Screenshots/mac` | Mac | 2880 × 1800 |

`Scripts/aso-screenshots.sh` makes them again, or `Scripts/aso-screenshots.sh iphone` (or `ipad`, or `mac`) just one set. The iPad set is needed as long as the app runs on iPad: App Store Connect asks for it before the iOS version can go to review.

## Worth knowing before review

- The subject icons include sketches of some trademarks — Apple's and Swift's among them — so that notes about those subjects can be labelled. Apple's guidelines (5.2.1, 5.2.5) don't allow using its marks without permission; if review raises it, the quickest fix is to drop the `apple` and `swift` sketches from `inkept/SubjectIcons/SubjectIcons+Technology.swift` and anything else review names.
- The repository is now `outsideness-x/inkept`, and the app and this listing link there directly; GitHub still redirects the old `remn` addresses.
- Keywords can't name other apps or companies — App Store Connect's help says so — so Anki and Obsidian are left out of them. The description can still say inkept opens an Obsidian vault.
- Keywords are counted in bytes, not letters, so the Russian set is shorter than the English one. Words already in the name or subtitle are left out of both, since they're searched anyway.
- "What's new" isn't asked for the first version, so there's none here until 1.1.
