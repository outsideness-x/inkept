#if DEBUG
import Foundation
import ImageIO
import SwiftData
import SwiftUI

/// A small, believable library in memory, for design reviews and App Store screenshots.
/// Launch with `-demoLibrary`; the real store on the device is never touched.
@MainActor
enum DemoLibrary {
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-demoLibrary")
    }

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: InkeptSchemaV3.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: InkeptMigrationPlan.self,
            configurations: [configuration]
        )
        seed(ModelContext(container))
        return container
    }

    /// A notes folder in a temporary directory, filled with a few believable notes.
    static func makeVault() -> Vault {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("inkept-demo-notes", isDirectory: true)
        try? FileManager.default.removeItem(at: root)
        let russian = Locale.preferredLanguages.first?.hasPrefix("ru") == true
        let notes = russian ? russianNotes + russianWeb : englishNotes + englishWeb
        for (index, (path, text)) in notes.enumerated() {
            let url = root.appendingPathComponent(path)
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? text.write(to: url, atomically: true, encoding: .utf8)
            // Written over the last couple of months, more of it lately, so the timeline has a rhythm.
            let written = Date.now.addingTimeInterval(-Double(writtenDaysAgo[index % writtenDaysAgo.count]) * 86_400 - Double(index % 5) * 3_700)
            try? FileManager.default.setAttributes([.creationDate: written, .modificationDate: written], ofItemAtPath: url.path)
        }
        let cellFolder = root.appendingPathComponent(russian ? "Биология/attachments" : "Biology/attachments")
        try? FileManager.default.createDirectory(at: cellFolder, withIntermediateDirectories: true)
        try? cellPicture()?.write(to: cellFolder.appendingPathComponent("cell.png"))
        let icons = russian
            ? ["Линейная алгебра": "matrix", "Программирование": "code", "Биология": "cell", "Физика": "atom", "Испанский": "flag-es"]
            : ["Linear Algebra": "matrix", "Programming": "code", "Biology": "cell", "Physics": "atom", "Spanish": "flag-es"]
        for (folder, icon) in icons {
            try? VaultFolderInfo.setIcon(icon, in: root.appendingPathComponent(folder, isDirectory: true))
        }
        return Vault(rootURL: root, watches: true)
    }

    /// A soft, textbook-style drawing of a cell for the biology note.
    private static func cellPicture() -> Data? {
        let view = ZStack {
            Ellipse().fill(Color(red: 0.93, green: 0.86, blue: 0.74))
            Ellipse().stroke(Color(red: 0.55, green: 0.38, blue: 0.25), lineWidth: 6)
            Circle().fill(Color(red: 0.62, green: 0.42, blue: 0.62)).frame(width: 120).offset(x: -30, y: -10)
            Circle().fill(Color(red: 0.45, green: 0.28, blue: 0.47)).frame(width: 40).offset(x: -20, y: -20)
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(Color(red: 0.86, green: 0.47, blue: 0.36))
                    .frame(width: 70, height: 30)
                    .rotationEffect(.degrees(Double(index) * 37))
                    .offset(x: [150, 110, -150, 60, 170][index], y: [70, -95, 70, 100, -20][index])
            }
        }
        .frame(width: 560, height: 340)
        .padding(20)
        .background(Color(red: 0.98, green: 0.97, blue: 0.94))
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }

    private static let englishNotes: [(String, String)] = [
        ("Linear Algebra/Eigenvalues.md", """
        ---
        tags: [linear-algebra, exam]
        ---

        # Eigenvalues

        A non-zero vector $v$ is an **eigenvector** of $A$ when $A$ only stretches it:

        $$
        A v = \\lambda v
        $$

        The scalars $\\lambda$ are the roots of the *characteristic polynomial* $\\det(A - \\lambda I) = 0$. See also [[Vector spaces]].

        ## Why it matters

        - diagonalisation: $A = PDP^{-1}$
        - powers get cheap: $A^n = P D^n P^{-1}$
        - the ==spectral theorem== for symmetric matrices

        > The trace is the sum of the eigenvalues; the determinant is their product.

        - [x] read chapter 5
        - [ ] solve problems 5.1–5.12
        """),
        ("Linear Algebra/Vector spaces.md", "# Vector spaces\n\nA **basis** is a linearly independent set that spans the space.\n\nRank–nullity: $\\dim V = \\operatorname{rank} T + \\operatorname{nullity} T$ #linear-algebra\n"),
        ("Programming/Swift concurrency.md", """
        ---
        tags: [swift]
        font: sfPro
        ---

        # Actors

        An `actor` protects its mutable state: only one task touches it at a time.

        ```swift
        actor Counter {
            private var value = 0
            func increment() -> Int {
                value += 1 // serialised
                return value
            }
        }
        ```

        `Task` inherits the actor it was created on; `Task.detached` does not.
        """),
        ("Biology/The cell.md", "# The cell\n\n**ATP synthase** turns the proton gradient into ATP.\n\n![](attachments/cell.png)\n\n---\n\nRibosomes read mRNA three bases at a time. #biology\n"),
        ("Linear Algebra/Pictures.md", """
        # Pictures in Typst

        A sine and a cosine, drawn by the Typst engine inside inkept:

        ```typst
        #import "@preview/cetz:0.5.2": canvas
        #import "@preview/cetz-plot:0.1.4": plot
        #align(center, canvas({
          plot.plot(size: (7, 3.5), x-tick-step: 1, y-tick-step: 1, legend: "inner-north-east", {
            plot.add(domain: (0, 6.28), samples: 120, x => calc.sin(x), label: $sin x$, style: (stroke: 1.4pt + red))
            plot.add(domain: (0, 6.28), samples: 120, x => calc.cos(x), label: $cos x$, style: (stroke: 1.4pt + blue))
          })
        }))
        ```

        And a diagram:

        ```typst
        #import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
        #align(center, diagram(spacing: (10mm, 7mm), node-stroke: 1pt, node-corner-radius: 4pt,
          node((0, 0), [Input], fill: red.lighten(75%)), edge("-|>"),
          node((1, 0), [Attention], fill: orange.lighten(65%)), edge("-|>"),
          node((2, 0), [Output], fill: green.lighten(60%))))
        ```
        """),
        ("Reading list.md", "# Reading list\n\n- [ ] *Gödel, Escher, Bach*\n- [x] *The Art of Doing Science and Engineering*\n"),
    ]

    private static let russianNotes: [(String, String)] = [
        ("Линейная алгебра/Собственные значения.md", """
        ---
        tags: [линал, экзамен]
        ---

        # Собственные значения

        Ненулевой вектор $v$ — **собственный** для $A$, если $A$ его только растягивает:

        $$
        A v = \\lambda v
        $$

        Числа $\\lambda$ — корни *характеристического многочлена* $\\det(A - \\lambda I) = 0$. См. также [[Векторные пространства]].

        ## Зачем это нужно

        - диагонализация: $A = PDP^{-1}$
        - степени считаются быстро: $A^n = P D^n P^{-1}$
        - ==спектральная теорема== для симметричных матриц

        > След равен сумме собственных значений, определитель — их произведению.

        - [x] прочитать главу 5
        - [ ] решить задачи 5.1–5.12
        """),
        ("Линейная алгебра/Векторные пространства.md", "# Векторные пространства\n\n**Базис** — линейно независимая система, порождающая всё пространство.\n\nТеорема о ранге и дефекте: $\\dim V = \\operatorname{rank} T + \\dim \\ker T$ #линал\n"),
        ("Программирование/Конкурентность в Swift.md", """
        ---
        tags: [swift]
        font: sfPro
        ---

        # Акторы

        `actor` защищает своё изменяемое состояние: к нему обращается одна задача за раз.

        ```swift
        actor Counter {
            private var value = 0
            func increment() -> Int {
                value += 1 // по очереди
                return value
            }
        }
        ```

        `Task` наследует актор места создания, `Task.detached` — нет.
        """),
        ("Биология/Клетка.md", "# Клетка\n\n**АТФ-синтаза** превращает протонный градиент в АТФ.\n\n![](attachments/cell.png)\n\n---\n\nРибосомы читают мРНК по три нуклеотида. #биология\n"),
        ("Линейная алгебра/Картинки.md", """
        # Картинки на Typst

        Синус и косинус — их рисует Typst прямо внутри inkept:

        ```typst
        #import "@preview/cetz:0.5.2": canvas
        #import "@preview/cetz-plot:0.1.4": plot
        #align(center, canvas({
          plot.plot(size: (7, 3.5), x-tick-step: 1, y-tick-step: 1, legend: "inner-north-east", {
            plot.add(domain: (0, 6.28), samples: 120, x => calc.sin(x), label: $sin x$, style: (stroke: 1.4pt + red))
            plot.add(domain: (0, 6.28), samples: 120, x => calc.cos(x), label: $cos x$, style: (stroke: 1.4pt + blue))
          })
        }))
        ```

        И схема:

        ```typst
        #import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
        #align(center, diagram(spacing: (10mm, 7mm), node-stroke: 1pt, node-corner-radius: 4pt,
          node((0, 0), [Вход], fill: red.lighten(75%)), edge("-|>"),
          node((1, 0), [Внимание], fill: orange.lighten(65%)), edge("-|>"),
          node((2, 0), [Выход], fill: green.lighten(60%))))
        ```
        """),
        ("Что почитать.md", "# Что почитать\n\n- [ ] *Гёдель, Эшер, Бах*\n- [x] *Искусство научной и инженерной работы*\n"),
    ]

    private static let writtenDaysAgo = [0, 1, 1, 2, 3, 5, 6, 8, 9, 12, 13, 15, 16, 19, 22, 23, 26, 30, 33, 37, 41, 44, 48, 52, 57, 61, 66, 72, 78]

    /// Short notes that link to one another, and across subjects, the way a term's notes do.
    private static let englishWeb: [(String, String)] = [
        ("Linear Algebra/Matrices.md", "# Matrices\n\nA matrix is a [[Linear maps|linear map]] written in a basis. Its [[Determinant]] says whether it can be undone. #linear-algebra\n"),
        ("Linear Algebra/Determinant.md", "# Determinant\n\n$\\det(AB) = \\det A \\det B$. Zero exactly when the columns of a [[Matrices|matrix]] are dependent; see [[Eigenvalues]].\n"),
        ("Linear Algebra/Linear maps.md", "# Linear maps\n\nMaps between [[Vector spaces]] that keep sums and scalings. In a basis, each is one of the [[Matrices]]; its [[Rank]] is the dimension of the image.\n"),
        ("Linear Algebra/Rank.md", "# Rank\n\nThe number of independent columns. Decides whether [[Systems of equations]] have solutions. See [[Linear maps]].\n"),
        ("Linear Algebra/Spectral theorem.md", "---\ntags: [linear-algebra, exam]\n---\n\n# Spectral theorem\n\n[[Symmetric matrices]] have real [[Eigenvalues]] and an orthonormal basis of eigenvectors.\n"),
        ("Physics/Mechanics.md", "# Mechanics\n\nStarts from [[Newton's laws]]; most problems come down to [[Energy]] or momentum. #physics\n"),
        ("Physics/Newton's laws.md", "# Newton's laws\n\n$F = m a$. The ground floor of [[Mechanics]].\n"),
        ("Physics/Energy.md", "# Energy\n\n$E_k = \\frac{m v^2}{2}$, and it's conserved. Carries on into [[Thermodynamics]]. See [[Mechanics]].\n"),
        ("Physics/Waves.md", """
        # Waves

        Light is an electric and a magnetic field, each pushing the other along, at right angles:

        ```typst
        #import "@preview/cetz:0.5.2": canvas, draw
        #align(center, canvas({
          import draw: *
          ortho(x: 15deg, y: -35deg, {
            let wave(x) = calc.sin(x * calc.pi / 2)
            let steps = range(0, 81).map(i => i / 10)
            on-xz(grid((0, -1.4), (8, 1.4), step: 1, stroke: gray.lighten(40%) + .4pt))
            line(..steps.map(x => (x, wave(x) * 1.4, 0)), (8, 0, 0), (0, 0, 0), close: true, fill: blue.transparentize(65%), stroke: 1pt + black)
            line(..steps.map(x => (x, 0, wave(x) * 1.4)), (8, 0, 0), (0, 0, 0), close: true, fill: red.transparentize(65%), stroke: 1pt + black)
          })
        }))
        ```

        $$
        E(x, t) = E_0 \\sin(kx - \\omega t), \\qquad c = \\lambda f
        $$

        A damped spring swings the same way, and dies away — see [[Oscillations]]:

        ```typst
        #import "@preview/cetz:0.5.2": canvas
        #import "@preview/cetz-plot:0.1.4": plot
        #align(center, canvas({
          plot.plot(size: (7, 3), x-tick-step: 2, y-tick-step: 1, legend: "inner-north-east", {
            plot.add(domain: (0, 12), samples: 160, x => calc.exp(-x / 6) * calc.sin(2 * x), label: $x(t)$, style: (stroke: 1.4pt + blue))
            plot.add(domain: (0, 12), samples: 60, x => calc.exp(-x / 6), label: $e^(-t slash tau)$, style: (stroke: (paint: red, thickness: 1pt, dash: "dashed")))
          })
        }))
        ```
        """),
        ("Physics/Oscillations.md", "# Oscillations\n\nSmall swings trade [[Energy]] back and forth. Coupled ones are solved with [[Eigenvalues]] — linear algebra again.\n"),
        ("Programming/Actors.md", "# Actors\n\nThe safe home for shared state in [[Swift concurrency]]. What crosses into one has to be [[Sendable]]. #swift\n"),
        ("Programming/Sendable.md", "# Sendable\n\nValues safe to hand between tasks and [[Actors]].\n"),
        ("Programming/Async and await.md", "# Async and await\n\nWaiting without blocking a thread; every await is a point where [[Tasks]] can take turns. See [[Swift concurrency]].\n"),
        ("Programming/Tasks.md", "# Tasks\n\nUnits of async work. They often end up talking to [[Actors]].\n"),
        ("Programming/Algorithms/Quicksort.md", "# Quicksort\n\nPick a pivot, split, recurse: $O(n \\log n)$ on average. See [[Complexity]].\n"),
        ("Programming/Algorithms/Complexity.md", "# Complexity\n\nHow work grows with input. [[Quicksort]] and [[Graphs]] are the classic examples.\n"),
        ("Programming/Algorithms/Graphs.md", "# Graphs\n\nNodes and edges; stored as an adjacency list or as one of the [[Matrices]]. Searching one is a question of [[Complexity]].\n"),
        ("Biology/DNA.md", "# DNA\n\nThe instructions every [[The cell|cell]] carries, read out into [[Proteins]]. #biology\n"),
        ("Biology/Proteins.md", "# Proteins\n\nFolded chains of amino acids, built by [[Ribosomes]] from [[DNA]].\n"),
        ("Biology/Mitochondria.md", "# Mitochondria\n\nWhere [[The cell|a cell]] makes most of its [[ATP]].\n"),
        ("Spanish/Verbs.md", "# Verbs\n\n*tener*, *quedar*, *soler* — and how they change with [[Conjugation]].\n"),
        ("Spanish/Conjugation.md", "# Conjugation\n\n*tengo, tienes, tiene*. Most irregular [[Verbs]] follow a handful of patterns.\n"),
    ]

    private static let russianWeb: [(String, String)] = [
        ("Линейная алгебра/Матрицы.md", "# Матрицы\n\nМатрица — это [[Линейные отображения|линейное отображение]], записанное в базисе. [[Определитель]] говорит, можно ли его обратить. #линал\n"),
        ("Линейная алгебра/Определитель.md", "# Определитель\n\n$\\det(AB) = \\det A \\det B$. Равен нулю ровно тогда, когда столбцы [[Матрицы|матрицы]] зависимы; см. [[Собственные значения]].\n"),
        ("Линейная алгебра/Линейные отображения.md", "# Линейные отображения\n\nОтображения между [[Векторные пространства|векторными пространствами]], сохраняющие сложение и умножение на число. В базисе это [[Матрицы]]; [[Ранг]] — размерность образа.\n"),
        ("Линейная алгебра/Ранг.md", "# Ранг\n\nЧисло независимых столбцов. Решает, разрешимы ли [[Системы уравнений]]. См. [[Линейные отображения]].\n"),
        ("Линейная алгебра/Спектральная теорема.md", "---\ntags: [линал, экзамен]\n---\n\n# Спектральная теорема\n\nУ [[Симметричные матрицы|симметричных матриц]] вещественные [[Собственные значения]] и ортонормированный базис из собственных векторов.\n"),
        ("Физика/Механика.md", "# Механика\n\nНачинается с [[Законы Ньютона|законов Ньютона]]; большинство задач сводится к [[Энергия|энергии]] или импульсу. #физика\n"),
        ("Физика/Законы Ньютона.md", "# Законы Ньютона\n\n$F = m a$. Фундамент [[Механика|механики]].\n"),
        ("Физика/Энергия.md", "# Энергия\n\n$E_k = \\frac{m v^2}{2}$, и она сохраняется. Дальше — [[Термодинамика]]. См. [[Механика]].\n"),
        ("Физика/Волны.md", """
        # Волны

        Свет — это электрическое и магнитное поля, которые толкают друг друга вперёд под прямым углом:

        ```typst
        #import "@preview/cetz:0.5.2": canvas, draw
        #align(center, canvas({
          import draw: *
          ortho(x: 15deg, y: -35deg, {
            let wave(x) = calc.sin(x * calc.pi / 2)
            let steps = range(0, 81).map(i => i / 10)
            on-xz(grid((0, -1.4), (8, 1.4), step: 1, stroke: gray.lighten(40%) + .4pt))
            line(..steps.map(x => (x, wave(x) * 1.4, 0)), (8, 0, 0), (0, 0, 0), close: true, fill: blue.transparentize(65%), stroke: 1pt + black)
            line(..steps.map(x => (x, 0, wave(x) * 1.4)), (8, 0, 0), (0, 0, 0), close: true, fill: red.transparentize(65%), stroke: 1pt + black)
          })
        }))
        ```

        $$
        E(x, t) = E_0 \\sin(kx - \\omega t), \\qquad c = \\lambda f
        $$

        Пружина с трением качается так же и затухает — см. [[Колебания]]:

        ```typst
        #import "@preview/cetz:0.5.2": canvas
        #import "@preview/cetz-plot:0.1.4": plot
        #align(center, canvas({
          plot.plot(size: (7, 3), x-tick-step: 2, y-tick-step: 1, legend: "inner-north-east", {
            plot.add(domain: (0, 12), samples: 160, x => calc.exp(-x / 6) * calc.sin(2 * x), label: $x(t)$, style: (stroke: 1.4pt + blue))
            plot.add(domain: (0, 12), samples: 60, x => calc.exp(-x / 6), label: $e^(-t slash tau)$, style: (stroke: (paint: red, thickness: 1pt, dash: "dashed")))
          })
        }))
        ```
        """),
        ("Физика/Колебания.md", "# Колебания\n\nМалые колебания перекачивают [[Энергия|энергию]] туда и обратно. Связанные решаются через [[Собственные значения]] — снова линал.\n"),
        ("Программирование/Акторы.md", "# Акторы\n\nБезопасный дом для общего состояния в [[Конкурентность в Swift|конкурентном Swift]]. Всё, что попадает внутрь, должно быть [[Sendable]]. #swift\n"),
        ("Программирование/Sendable.md", "# Sendable\n\nЗначения, которые безопасно передавать между задачами и [[Акторы|акторами]].\n"),
        ("Программирование/Async и await.md", "# Async и await\n\nОжидание без блокировки потока; каждый await — место, где [[Задачи]] уступают друг другу. См. [[Конкурентность в Swift]].\n"),
        ("Программирование/Задачи.md", "# Задачи\n\nЕдиницы асинхронной работы. Часто общаются с [[Акторы|акторами]].\n"),
        ("Программирование/Алгоритмы/Быстрая сортировка.md", "# Быстрая сортировка\n\nВыбрать опорный, разделить, повторить: в среднем $O(n \\log n)$. См. [[Сложность алгоритмов]].\n"),
        ("Программирование/Алгоритмы/Сложность алгоритмов.md", "# Сложность алгоритмов\n\nКак растёт работа с размером входа. Классика — [[Быстрая сортировка]] и [[Графы]].\n"),
        ("Программирование/Алгоритмы/Графы.md", "# Графы\n\nВершины и рёбра; хранятся списком смежности или как одна из [[Матрицы|матриц]]. Обход — вопрос [[Сложность алгоритмов|сложности]].\n"),
        ("Биология/ДНК.md", "# ДНК\n\nИнструкция, которую несёт каждая [[Клетка]], переводится в [[Белки]]. #биология\n"),
        ("Биология/Белки.md", "# Белки\n\nСвёрнутые цепочки аминокислот; их собирают [[Рибосомы]] по [[ДНК]].\n"),
        ("Биология/Митохондрии.md", "# Митохондрии\n\nЗдесь [[Клетка]] получает большую часть [[АТФ]].\n"),
        ("Испанский/Глаголы.md", "# Глаголы\n\n*tener*, *quedar*, *soler* — и как они меняются при [[Спряжение|спряжении]].\n"),
        ("Испанский/Спряжение.md", "# Спряжение\n\n*tengo, tienes, tiene*. Большинство неправильных [[Глаголы|глаголов]] укладываются в несколько схем.\n"),
    ]

    private enum Plan {
        /// Never studied.
        case new
        /// Studied before and due right now.
        case due
        /// Studied before and coming back later.
        case later
    }

    private struct DemoCard {
        let front: String
        let back: String
        let plan: Plan
    }

    private struct DemoDeck {
        let name: String
        let cards: [DemoCard]
    }

    private struct DemoSubject {
        let name: String
        var icon: String?
        let decks: [DemoDeck]
    }

    private static func seed(_ context: ModelContext, now: Date = .now) {
        let russian = Locale.preferredLanguages.first?.hasPrefix("ru") == true
        let scheduler = FSRSSchedulerService()
        for (subjectIndex, subjectPlan) in (russian ? russianLibrary : englishLibrary).enumerated() {
            let subject = SubjectModel(name: subjectPlan.name, manualSortOrder: subjectIndex, icon: subjectPlan.icon)
            context.insert(subject)
            for (deckIndex, deckPlan) in subjectPlan.decks.enumerated() {
                let deck = Deck(subject: subject, name: deckPlan.name, manualSortOrder: deckIndex)
                context.insert(deck)
                for (cardIndex, cardPlan) in deckPlan.cards.enumerated() {
                    let created = now.addingTimeInterval(-Double(40 - cardIndex) * 86_400)
                    let card = Flashcard(
                        deck: deck,
                        frontMarkdown: cardPlan.front,
                        backMarkdown: cardPlan.back,
                        createdAt: created,
                        updatedAt: created
                    )
                    context.insert(card)
                    if cardPlan.plan != .new {
                        study(card, plan: cardPlan.plan, seed: cardIndex, scheduler: scheduler, context: context, now: now)
                    }
                }
            }
        }
        try? context.save()
    }

    /// Plays a few past reviews through FSRS so history, intervals and due dates are real.
    private static func study(
        _ card: Flashcard,
        plan: Plan,
        seed: Int,
        scheduler: FSRSSchedulerService,
        context: ModelContext,
        now: Date
    ) {
        var time = card.createdAt.addingTimeInterval(3_600)
        let ratings: [StudyRating] = [.good, seed % 3 == 0 ? .hard : .good, .good, .easy]
        for rating in ratings.prefix(2 + seed % 3) {
            guard time < now,
                  let candidate = try? scheduler.candidates(for: card.scheduleSnapshot, at: time, desiredRetention: 0.9)[rating]
            else { break }
            let previous = card.scheduleSnapshot
            card.scheduleSnapshot = candidate.schedule
            context.insert(
                ReviewLogEntry(
                    card: card,
                    timestamp: time,
                    rating: rating,
                    previous: previous,
                    resulting: candidate.schedule,
                    elapsedInterval: candidate.elapsedDays,
                    scheduledInterval: candidate.scheduledDays
                )
            )
            time = candidate.schedule.due
        }
        switch plan {
        case .due:
            card.due = now.addingTimeInterval(-Double(seed + 1) * 3_600)
        case .later:
            card.due = now.addingTimeInterval(Double(seed + 2) * 86_400)
        case .new:
            break
        }
    }

    // MARK: - Content

    private static let englishLibrary: [DemoSubject] = [
        DemoSubject(name: "Linear Algebra", icon: "matrix", decks: [
            DemoDeck(name: "Eigen things", cards: [
                DemoCard(
                    front: "What is an **eigenvector** of a linear map $T$?",
                    back: "A non-zero vector $v$ that $T$ only stretches:\n\n$$T v = \\lambda v$$\n\nThe scalar $\\lambda$ is its eigenvalue.",
                    plan: .due
                ),
                DemoCard(
                    front: "The determinant of a 2 × 2 matrix",
                    back: "$$\\det\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix} = ad - bc$$",
                    plan: .due
                ),
                DemoCard(
                    front: "The trace of a matrix equals…",
                    back: "…the sum of its eigenvalues, counted with multiplicity.",
                    plan: .later
                ),
                DemoCard(
                    front: "What does the spectral theorem promise?",
                    back: "A real symmetric matrix has an orthonormal basis of eigenvectors:\n\n$$A = Q \\Lambda Q^{\\top}$$",
                    plan: .new
                ),
            ]),
            DemoDeck(name: "Vector spaces", cards: [
                DemoCard(front: "Define a *basis*.", back: "A linearly independent set that spans the space.", plan: .due),
                DemoCard(front: "Rank–nullity theorem", back: "$$\\dim V = \\operatorname{rank} T + \\operatorname{nullity} T$$", plan: .later),
            ]),
        ]),
        DemoSubject(name: "Spanish", icon: "flag-es", decks: [
            DemoDeck(name: "Everyday verbs", cards: [
                DemoCard(front: "aprovechar", back: "to make the most of\n\n> *Aprovecha el día.*", plan: .due),
                DemoCard(front: "tener", back: "to have — *tengo, tienes, tiene*", plan: .later),
                DemoCard(front: "quedar", back: "to remain; to arrange to meet\n\n- *quedamos a las ocho*\n- *no queda pan*", plan: .due),
                DemoCard(front: "echar de menos", back: "to miss someone or something", plan: .new),
                DemoCard(front: "soler", back: "to usually do — *suelo leer por la noche*", plan: .new),
            ]),
        ]),
        DemoSubject(name: "Swift", icon: "swift", decks: [
            DemoDeck(name: "Concurrency", cards: [
                DemoCard(
                    front: "What does an `actor` protect?",
                    back: "Its mutable state — only one task touches it at a time.\n\n```swift\nactor Counter {\n    private var value = 0\n    func increment() { value += 1 }\n}\n```",
                    plan: .due
                ),
                DemoCard(front: "What makes a type `Sendable`?", back: "It is safe to share across concurrency domains without data races.", plan: .later),
                DemoCard(front: "`Task` vs `Task.detached`", back: "`Task` inherits the actor and priority it was created on; `Task.detached` inherits neither.", plan: .new),
            ]),
        ]),
        DemoSubject(name: "Biology", icon: "dna", decks: [
            DemoDeck(name: "The cell", cards: [
                DemoCard(front: "What does ATP synthase make?", back: "**ATP**, driven by protons flowing back across the inner mitochondrial membrane.", plan: .later),
                DemoCard(front: "Where does translation happen?", back: "On ribosomes — free in the cytoplasm or on the rough ER.", plan: .later),
            ]),
        ]),
    ]

    private static let russianLibrary: [DemoSubject] = [
        DemoSubject(name: "Линейная алгебра", icon: "matrix", decks: [
            DemoDeck(name: "Собственные векторы", cards: [
                DemoCard(
                    front: "Что такое **собственный вектор** линейного оператора $T$?",
                    back: "Ненулевой вектор $v$, который $T$ только растягивает:\n\n$$T v = \\lambda v$$\n\nЧисло $\\lambda$ — его собственное значение.",
                    plan: .due
                ),
                DemoCard(
                    front: "Определитель матрицы 2 × 2",
                    back: "$$\\det\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix} = ad - bc$$",
                    plan: .due
                ),
                DemoCard(front: "След матрицы равен…", back: "…сумме её собственных значений с учётом кратности.", plan: .later),
                DemoCard(
                    front: "Что утверждает спектральная теорема?",
                    back: "У вещественной симметричной матрицы есть ортонормированный базис из собственных векторов:\n\n$$A = Q \\Lambda Q^{\\top}$$",
                    plan: .new
                ),
            ]),
            DemoDeck(name: "Векторные пространства", cards: [
                DemoCard(front: "Что такое *базис*?", back: "Линейно независимая система, порождающая всё пространство.", plan: .due),
                DemoCard(front: "Теорема о ранге и дефекте", back: "$$\\dim V = \\operatorname{rank} T + \\dim \\ker T$$", plan: .later),
            ]),
        ]),
        DemoSubject(name: "Испанский", icon: "flag-es", decks: [
            DemoDeck(name: "Глаголы на каждый день", cards: [
                DemoCard(front: "aprovechar", back: "воспользоваться, использовать с толком\n\n> *Aprovecha el día.*", plan: .due),
                DemoCard(front: "tener", back: "иметь — *tengo, tienes, tiene*", plan: .later),
                DemoCard(front: "quedar", back: "оставаться; договориться о встрече\n\n- *quedamos a las ocho*\n- *no queda pan*", plan: .due),
                DemoCard(front: "echar de menos", back: "скучать по кому-то или чему-то", plan: .new),
                DemoCard(front: "soler", back: "обычно что-то делать — *suelo leer por la noche*", plan: .new),
            ]),
        ]),
        DemoSubject(name: "Swift", icon: "swift", decks: [
            DemoDeck(name: "Конкурентность", cards: [
                DemoCard(
                    front: "Что защищает `actor`?",
                    back: "Своё изменяемое состояние: к нему обращается только одна задача за раз.\n\n```swift\nactor Counter {\n    private var value = 0\n    func increment() { value += 1 }\n}\n```",
                    plan: .due
                ),
                DemoCard(front: "Когда тип `Sendable`?", back: "Когда его безопасно передавать между доменами конкурентности без гонок данных.", plan: .later),
                DemoCard(front: "`Task` и `Task.detached`", back: "`Task` наследует актор и приоритет места создания, `Task.detached` — нет.", plan: .new),
            ]),
        ]),
        DemoSubject(name: "История", icon: "scroll", decks: [
            DemoDeck(name: "Книгопечатание", cards: [
                DemoCard(front: "Когда напечатана Библия Гутенберга?", back: "Около **1455** года, в Майнце.", plan: .later),
                DemoCard(front: "Первая точно датированная русская печатная книга", back: "«Апостол» Ивана Фёдорова, **1564** год.", plan: .later),
            ]),
        ]),
    ]
}
#endif
