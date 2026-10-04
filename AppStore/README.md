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

In App Store Connect and the developer account (by hand):

- [ ] Certificates, Identifiers & Profiles: the App ID `com.chemical-pink.inkept` has iCloud (CloudKit support not needed — iCloud Documents only) with the container `iCloud.com.chemical-pink.inkept`
- [ ] A new app record for iOS and macOS with that bundle identifier, primary language English, and Russian added as a localisation
- [ ] Archive the `inkept` scheme for Any iOS Device and for My Mac in Xcode (Product → Archive) and upload both builds
- [ ] Paste the text below for each language, add the screenshots, set the URLs, answer the questionnaires
- [ ] Price: free, all territories
- [ ] Submit both platforms for review together

## URLs

| Field | URL |
| --- | --- |
| Privacy Policy URL | https://github.com/outsideness-x/remn/blob/main/PRIVACY.md |
| Support URL | https://github.com/outsideness-x/remn/blob/main/SUPPORT.md |
| Marketing URL | https://github.com/outsideness-x/remn |

## Categories, age rating, privacy

- **Primary category:** Education. **Secondary:** Productivity.
- **Age rating:** 4+. Every questionnaire answer is "None" or "No". There's no unrestricted web access: links open in the system browser, not inside the app.
- **App Privacy:** Data Not Collected.
- **Content rights:** the app doesn't show third-party content from the internet. Its bundled fonts and Typst packages are open source and credited in [ACKNOWLEDGEMENTS.md](../ACKNOWLEDGEMENTS.md).
- **Copyright:** 2026 chemical-pink

## App Review notes

> inkept needs no account and no network connection. When it asks where to keep everything, choose "on this device" — it works straight away (iCloud Drive works too, when the device is signed in to iCloud).
>
> Notes tab: write a note; select some text and tap the card button to make a flashcard from it. The list / board / graph / timeline switch at the top shows the notes in different ways — the graph is the map of how notes link.
> Cards tab: create a subject and a deck, add cards, and study them; ratings schedule the next review with FSRS.
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

**Keywords** (100)
```
anki,fsrs,study,memorize,obsidian,latex,math,vocabulary,exam,learn,srs,memory,typst,revise,quiz
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

**What's new**
```
The first release of inkept.
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

**Ключевые слова** (100)
```
anki,учить,запомнить,повторение,markdown,obsidian,экзамен,слова,формулы,latex,память,флешкарты
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

**Что нового**
```
Первый выпуск inkept.
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
- The repository is still called `remn`; GitHub redirects the old address if it's renamed, so the links in the app keep working.
