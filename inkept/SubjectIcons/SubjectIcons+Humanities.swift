import CoreGraphics

extension SubjectIcon {
    static let humanities: [SubjectIcon] = letters + arts + society + world

    // MARK: - Reading and writing

    private static let letters: [SubjectIcon] = [
        SubjectIcon("book", .humanities, en: "book", ru: "книга", tint: .red,
                    keys: "literature литератур reading чтени novel роман library библиотек") { art in
            art.shape(.path("M2.8 10.8 L2.8 26.4 C8 25.3 12.6 25.7 16 27.6 C19.4 25.7 24 25.3 29.2 26.4 L29.2 10.8 Z"), .red, width: 1.4)
            let left = EmojiFigure.path("M16 10.8 C12.6 8.7 8.2 8.2 4.6 9 L4.6 24.4 C8.2 23.7 12.6 24.1 16 26 Z")
            art.shape(left, .paper, width: 1.3)
            art.shape(left.mirrored(), .paper, width: 1.3)
            for (index, y) in [CGFloat(12.6), 15.4, 18.2, 21].enumerated() {
                art.fine(.curve(6.6, y - 0.3, 10, y - 0.2, 13.8, y + 0.6), .graphite, opacity: index == 3 ? 0.4 : 0.65)
                art.fine(.curve(18.2, y + 0.6, 22, y - 0.2, 25.4, y - 0.3), .graphite, opacity: index == 0 ? 0.4 : 0.65)
            }
            art.ink(.line(16, 10.8, 16, 26), width: 1.2)
        },
        SubjectIcon("quill", .humanities, en: "quill", ru: "перо", tint: .navy,
                    keys: "writing письм literature литератур poetry поэз essay сочинен calligraphy каллиграф russian русск") { art in
            let feather = EmojiFigure.path("M9.6 18.6 C12 13.4 16.6 7.2 26.8 3.2 C27 8.8 23.6 14.2 16.2 17.8 C14 18.8 11.8 19 9.6 18.6 Z")
            art.fill(feather, .paper)
            art.clip(feather) { inside in
                inside.hatch(.path("M9 19 C16 14 22 9 27 3 L32 3 L32 24 L9 24 Z"), .sky, angle: 35, gap: 1.5, opacity: 0.9)
            }
            art.ink(feather, width: 1.3)
            art.ink(.curve(8.4, 20.8, 13.6, 14.8, 19.4, 9.4, 26.6, 3.6), width: 1.1)
            art.fine(.line(17.4, 12.6, 18.4, 15.6))
            art.fine(.line(21, 9.4, 22.2, 12.4))
            let bottle = EmojiFigure.path("""
            M4.2 23 L4.2 27.4 Q4.2 28.8 5.6 28.8 L13.8 28.8 Q15.2 28.8 15.2 27.4 L15.2 23 \
            Q15.2 21 13.2 20.8 L12.4 20.8 L12.4 18.8 L7 18.8 L7 20.8 L6.2 20.8 Q4.2 21 4.2 23 Z
            """)
            art.shape(bottle, .navy, width: 1.4)
            art.shape(.box(6.2, 23.4, 7, 3.2, r: 0.6), .paper, width: 0.9)
        },
        SubjectIcon("scroll", .humanities, en: "scroll", ru: "свиток", tint: .tan,
                    keys: "history истор archive архив ancient древн document документ manuscript рукопис") { art in
            art.shape(.box(8.2, 6.6, 15.6, 18.8), .tan, width: 1.3)
            for (index, y) in [CGFloat(10.6), 13.4, 16.2, 19].enumerated() {
                art.fine(.curve(10.6, y, 14, y - 0.4, 17.6, y + 0.3, index == 3 ? 17.6 : 21.4, y - 0.1), .brown, opacity: 0.8)
            }
            art.shape(.box(5.8, 3.6, 20.4, 4.6, r: 2.3), .tan, width: 1.4)
            art.fine(.circle(8.2, 5.9, 1.2))
            art.shape(.box(5.8, 23.8, 20.4, 4.6, r: 2.3), .tan, width: 1.4)
            art.fine(.circle(23.8, 26.1, 1.2))
            art.shape(.circle(20.4, 21.2, 2.3), .red, width: 1.1)
            art.fill(.poly(19.2, 22.8, 18.4, 25.6, 19.8, 24.8, 20.6, 25.8, 20.8, 23), .red)
        },
    ]

    // MARK: - The arts

    private static let arts: [SubjectIcon] = [
        SubjectIcon("palette", .humanities, en: "palette", ru: "палитра", tint: .orange,
                    keys: "art искусств painting живопис drawing рисован design дизайн color цвет") { art in
            let board = EmojiFigure.path("""
            M16.4 4.6 C23.8 4.6 28.6 9.4 28.2 15.4 C27.9 19.6 24.6 19.4 22.8 20.2 C21.2 21 21.8 23.4 21.4 25 \
            C20.8 27.2 18.2 27.8 15.2 27.4 C8.8 26.6 3.8 22 3.8 15.8 C3.8 9.4 9.2 4.6 16.4 4.6 Z
            """)
            art.fill(board, .tan)
            art.clip(board) { inside in
                inside.shade(.path("M20 24 C24 21 27 20 28 15 L30 15 L30 30 L18 30 Z"), opacity: 0.2)
            }
            art.ink(board)
            art.shape(.circle(17.2, 22.6, 1.9), .paper, width: 1.1)
            art.shape(.blob(9.4, 12.4, 11.4, 11.2, 12.2, 13.2, 10.6, 14.6, 8.8, 13.8), .red, width: 1)
            art.shape(.blob(14.4, 8.6, 16.6, 7.6, 17.6, 9.6, 15.8, 11, 14, 10.2), .yellow, width: 1)
            art.shape(.blob(20.4, 9.2, 22.8, 8.8, 23.4, 11, 21.4, 12, 19.8, 11), .blue, width: 1)
            art.shape(.blob(9.6, 18.4, 11.8, 17.6, 12.6, 19.8, 10.8, 21, 9, 20), .green, width: 1)
        },
        SubjectIcon("music", .humanities, en: "music", ru: "музыка", tint: .purple,
                    keys: "song песн notes ноты singing пени choir хор solfeggio сольфеджио") { art in
            art.fill(.poly(11.6, 9.8, 25.4, 5.6, 25.4, 8.8, 11.6, 13), .ink)
            art.ink(.poly(11.6, 9.8, 25.4, 5.6, 25.4, 8.8, 11.6, 13), width: 1.3)
            art.ink(.line(11.6, 10, 11.7, 22.6), width: 1.6)
            art.ink(.line(25.4, 6, 25.5, 19.6), width: 1.6)
            art.shape(.oval(8.8, 23.2, 3.3, 2.5, rotation: -22), .purple, width: 1.4)
            art.shape(.oval(22.6, 20.2, 3.3, 2.5, rotation: -22), .purple, width: 1.4)
        },
        SubjectIcon("guitar", .humanities, en: "guitar", ru: "гитара", tint: .orange,
                    keys: "music музык instrument инструмент band группа") { art in
            let tilt: CGFloat = 38
            art.shape(EmojiFigure.box(14.6, 1.8, 2.8, 14, r: 0.6).rotated(tilt), .brown, width: 1.2)
            art.shape(EmojiFigure.box(13.8, 0.4, 4.4, 3.4, r: 1).rotated(tilt), .brown, width: 1.1)
            let body = EmojiFigure.path("""
            M16 12.4 C19.6 12.4 20.8 14.4 20.4 16.8 C20.2 18 21.8 18.8 22.2 21 C23 25.4 20 29.4 16 29.4 \
            C12 29.4 9 25.4 9.8 21 C10.2 18.8 11.8 18 11.6 16.8 C11.2 14.4 12.4 12.4 16 12.4 Z
            """).rotated(tilt)
            art.fill(body, .orange)
            art.clip(body) { inside in
                inside.shade(EmojiFigure.box(17.6, 0, 10, 32).rotated(tilt), opacity: 0.22)
            }
            art.ink(body)
            let hole = EmojiFigure.turn(16, 19.6, tilt)
            art.shape(.circle(hole.x, hole.y, 2.1), .black, width: 1.1)
            art.ink(EmojiFigure.line(16, 3, 16, 25.2).rotated(tilt), .paper, width: 0.6)
            art.shape(EmojiFigure.box(13.4, 24.6, 5.2, 1.6, r: 0.4).rotated(tilt), .brown, width: 0.9)
        },
        SubjectIcon("masks", .humanities, en: "theatre", ru: "театр", tint: .yellow,
                    keys: "theatre театр drama драм acting актёр actor stage сцен performance спектакл") { art in
            let mask = EmojiFigure.path("M-6.2 -5.4 C-5.4 -9.2 5.4 -9.2 6.2 -5.4 C6.8 0.4 4.8 6.2 0 7.8 C-4.8 6.2 -6.8 0.4 -6.2 -5.4 Z")
            let back = mask.rotated(14, around: 0, 0).moved(20.8, 12.6)
            art.shape(back, .sky)
            art.ink(EmojiFigure.curve(-4, -2.4, -2.6, -3.4, -1.2, -2.2).rotated(14, around: 0, 0).moved(20.8, 12.6), width: 1.3)
            art.ink(EmojiFigure.curve(1.2, -2.2, 2.6, -3.4, 4, -2.4).rotated(14, around: 0, 0).moved(20.8, 12.6), width: 1.3)
            art.ink(EmojiFigure.curve(-2.6, 3.8, 0, 2.2, 2.6, 3.8).rotated(14, around: 0, 0).moved(20.8, 12.6), width: 1.3)
            let front = mask.rotated(-12, around: 0, 0).moved(11.4, 17.8)
            art.shape(front, .yellow)
            art.ink(EmojiFigure.curve(-4, -2.2, -2.6, -3.4, -1.2, -2.2).rotated(-12, around: 0, 0).moved(11.4, 17.8), width: 1.3)
            art.ink(EmojiFigure.curve(1.2, -2.2, 2.6, -3.4, 4, -2.2).rotated(-12, around: 0, 0).moved(11.4, 17.8), width: 1.3)
            art.ink(EmojiFigure.curve(-2.8, 2.2, 0, 4.4, 2.8, 2.2).rotated(-12, around: 0, 0).moved(11.4, 17.8), width: 1.3)
            art.dot(8.2, 19.2, 1.1, .rose)
            art.dot(14.6, 17.8, 1.1, .rose)
        },
        SubjectIcon("camera", .humanities, en: "camera", ru: "фотоаппарат", tint: .navy,
                    keys: "photography фотограф photo фото media медиа journalism журналист") { art in
            art.shape(.box(10.4, 6.2, 9.6, 4.8, r: 1.4), .steel, width: 1.3)
            art.shape(.box(3.4, 9.4, 25.2, 16.8, r: 3.2), .navy, width: 1.5)
            art.shape(.box(21.6, 11.6, 4, 2.4, r: 0.6), .yellow, width: 0.9)
            art.shape(.box(5.2, 7.8, 3.6, 1.8, r: 0.6), .red, width: 0.9)
            art.shape(.circle(15.6, 17.8, 6.2), .steel, width: 1.4)
            art.shape(.circle(15.6, 17.8, 3.8), .black, width: 1.2)
            art.fine(.arc(14.6, 16.8, 1.6, from: 190, to: 260), .paper)
        },
        SubjectIcon("film", .humanities, en: "cinema", ru: "кино", tint: .black,
                    keys: "film фильм movie cinema кинематограф video видео media медиа") { art in
            let board = EmojiFigure.box(4, 12.6, 24, 15.4, r: 1.6)
            art.shape(board, .black, width: 1.4)
            art.fine(.line(6.4, 18, 25.6, 18), .white)
            art.fine(.line(6.4, 22.2, 17.4, 22.2), .white)
            art.fine(.line(6.4, 25.2, 21, 25.2), .white)
            let arm = EmojiFigure.box(4, 7.8, 24, 4.2, r: 0.8).rotated(-13, around: 4.4, 12)
            art.fill(arm, .black)
            art.clip(arm) { inside in
                for index in 0..<5 {
                    let x = 6.4 + CGFloat(index) * 5
                    inside.fill(EmojiFigure.poly(x, 7, x + 2.6, 7, x + 0.6, 13, x - 2, 13).rotated(-13, around: 4.4, 12), .white)
                }
            }
            art.ink(arm, width: 1.4)
            art.dot(4.6, 12.2, 1, .steel)
        },
    ]

    // MARK: - Society

    private static let society: [SubjectIcon] = [
        SubjectIcon("scales", .humanities, en: "scales", ru: "весы", tint: .gold,
                    keys: "law прав justice правосуд jurisprudence юриспруденц court суд ethics этик") { art in
            art.ink(.line(16, 5.8, 16, 25.8), width: 1.8)
            art.shape(.box(9.6, 25.4, 12.8, 3, r: 1.2), .gold, width: 1.3)
            art.ink(.line(4.6, 9.4, 27.4, 8.6), width: 1.8)
            art.shape(.circle(16, 5.4, 1.6), .gold, width: 1)
            for x in [CGFloat(6), 26] {
                let y: CGFloat = x < 16 ? 9.4 : 8.6
                art.fine(.line(x, y, x - 3.6, y + 9.2))
                art.fine(.line(x, y, x + 3.6, y + 9.2))
                art.shape(.path("M\(x - 5.4) \(y + 9.2) L\(x + 5.4) \(y + 9.2) C\(x + 4.6) \(y + 13.8) \(x - 4.6) \(y + 13.8) \(x - 5.4) \(y + 9.2) Z"), .gold, width: 1.3)
            }
        },
        SubjectIcon("coins", .humanities, en: "coins", ru: "монеты", tint: .gold,
                    keys: "economics экономик finance финанс money деньг business бизнес accounting бухгалтер investment инвестиц") { art in
            for index in 0..<4 {
                let y = 24.8 - CGFloat(index) * 3.2
                let side = EmojiFigure.path("M3.8 \(y) L3.8 \(y + 1.8) A6 2.1 0 0 0 15.8 \(y + 1.8) L15.8 \(y) Z")
                art.fill(side, .gold)
                art.ink(side, width: 1.1)
                art.shape(.oval(9.8, y, 6, 2.1), .yellow, width: 1.1)
            }
            let coin = EmojiFigure.circle(21.4, 18.8, 7.6)
            art.fill(coin, .yellow)
            art.clip(coin) { inside in
                inside.shade(.path("M22 10 A 8 8 0 0 1 22 27 L32 27 L32 10 Z"), opacity: 0.2)
            }
            art.ink(coin, width: 1.4)
            art.fine(.circle(21.4, 18.8, 5.4))
            art.shape(.star(21.4, 19, 3.2, inner: 1.4), .gold, width: 0.8)
        },
        SubjectIcon("briefcase", .humanities, en: "briefcase", ru: "портфель", tint: .brown,
                    keys: "business бизнес management менеджмент marketing маркетинг career карьер work работ office офис") { art in
            art.ink(.path("M12 10.2 L12 7.8 Q12 6 13.8 6 L18.2 6 Q20 6 20 7.8 L20 10.2"), width: 1.6)
            art.shape(.box(3.6, 10, 24.8, 16.6, r: 2.8), .brown)
            art.fine(.line(3.8, 16.4, 28.2, 16.4))
            art.shape(.box(14, 14.6, 4, 3.6, r: 0.8), .gold, width: 1)
            art.fine(.line(8, 10.2, 8, 26.4), .ink, opacity: 0.5)
            art.fine(.line(24, 10.2, 24, 26.4), .ink, opacity: 0.5)
        },
        SubjectIcon("people", .humanities, en: "people", ru: "люди", tint: .orange,
                    keys: "sociology социолог society обществ social социальн social studies обществознан politics политик community сообществ") { art in
            art.shape(.path("M13 26.8 C13.4 20.4 16.8 17.6 21.4 17.6 C26 17.6 29.4 20.4 29.8 26.8 Z"), .sky)
            art.shape(.circle(21.4, 11.8, 4.2), .sky)
            art.shape(.path("M2.4 28 C2.8 21.4 6.4 18.6 11 18.6 C15.6 18.6 19.2 21.4 19.6 28 Z"), .orange)
            art.shape(.circle(11, 12.6, 4.4), .orange)
        },
        SubjectIcon("owl", .humanities, en: "owl", ru: "сова", tint: .brown,
                    keys: "philosophy философ wisdom мудрост logic логик knowledge знани night ночь") { art in
            let body = EmojiFigure.path("M8.6 8.4 L7.2 3.6 L12 6.6 C14.6 5.8 17.4 5.8 20 6.6 L24.8 3.6 L23.4 8.4 C26.4 12 27 18 25 22.6 C23.2 26.6 19.8 28.6 16 28.6 C12.2 28.6 8.8 26.6 7 22.6 C5 18 5.6 12 8.6 8.4 Z")
            art.fill(body, .brown)
            art.fill(.blob(11.4, 17.6, 16, 16, 20.6, 17.6, 21.4, 23.4, 16, 27, 10.6, 23.4), .tan)
            art.ink(body)
            for (x, y) in [(13.6, 20), (18.4, 20), (16, 22.8), (13.4, 24.4), (18.6, 24.4)] as [(CGFloat, CGFloat)] {
                art.fine(.line(x - 1, y - 0.4, x, y + 0.6, x + 1, y - 0.4), .brown)
            }
            art.shape(.circle(12, 12.8, 3.6), .paper, width: 1.2)
            art.shape(.circle(20, 12.8, 3.6), .paper, width: 1.2)
            art.dot(12.4, 13, 1.6)
            art.dot(19.6, 13, 1.6)
            art.shape(.poly(14.8, 15.6, 17.2, 15.6, 16, 18.6), .orange, width: 1)
        },
    ]

    // MARK: - The world

    private static let world: [SubjectIcon] = [
        SubjectIcon("globe", .humanities, en: "globe", ru: "глобус", tint: .sky,
                    keys: "geography географ world мир earth земл planet планет travel путешеств") { art in
            let sphere = EmojiFigure.circle(16, 16, 11.8)
            art.fill(sphere, .sky)
            art.clip(sphere) { inside in
                inside.fill(.blob(7, 8.2, 11.6, 6.4, 15.4, 8.8, 14, 12.4, 16.4, 15.6, 13.2, 19.8, 10.8, 18, 9.6, 14.6, 6.2, 13.4), .lime)
                inside.fill(.blob(19.6, 5.8, 25.4, 8.6, 27.8, 13.2, 24.2, 13.8, 21.8, 11.6, 18.4, 10.2), .lime)
                inside.fill(.blob(19.4, 17.4, 24.6, 16.8, 26.4, 20.8, 22.8, 26.2, 20, 24.4, 18.2, 20.6), .lime)
                inside.shade(.path("M20 2 A 13 13 0 0 1 20 30 L32 30 L32 2 Z"), opacity: 0.25)
            }
            art.fine(.oval(16, 16, 5.2, 11.6), .ink, opacity: 0.7)
            art.fine(.curve(4.6, 12.4, 10, 11.2, 16, 11, 22, 11.2, 27.4, 12.4), .ink, opacity: 0.55)
            art.fine(.curve(4.4, 19.4, 10, 20.8, 16, 21.1, 22, 20.8, 27.6, 19.4), .ink, opacity: 0.55)
            art.ink(sphere, width: 1.5)
        },
        SubjectIcon("map", .humanities, en: "map", ru: "карта", tint: .lime,
                    keys: "geography географ travel путешеств tourism туризм route маршрут cartography картограф") { art in
            let panels = [
                EmojiFigure.poly(3.4, 8.6, 11.4, 5.6, 11.4, 24.6, 3.4, 27.6),
                EmojiFigure.poly(11.4, 5.6, 20.6, 8.6, 20.6, 27.6, 11.4, 24.6),
                EmojiFigure.poly(20.6, 8.6, 28.6, 5.6, 28.6, 24.6, 20.6, 27.6),
            ]
            let whole = EmojiFigure.poly(3.4, 8.6, 11.4, 5.6, 20.6, 8.6, 28.6, 5.6, 28.6, 24.6, 20.6, 27.6, 11.4, 24.6, 3.4, 27.6)
            art.fill(whole, .sky)
            art.clip(whole) { inside in
                inside.fill(.blob(2, 14, 7, 11.4, 13, 13.6, 16.4, 19.6, 12, 26, 4, 24), .lime)
                inside.fill(.blob(19, 4, 26, 8, 30, 14.6, 24, 17, 19.6, 13), .lime)
                inside.shade(panels[1], opacity: 0.22)
            }
            for panel in panels {
                art.ink(panel, width: 1.3)
            }
            let route: [CGPoint] = EmojiCurves.catmullRom([
                CGPoint(x: 6, y: 21.6), CGPoint(x: 10, y: 17.4), CGPoint(x: 15, y: 19.6), CGPoint(x: 19.4, y: 15.4), CGPoint(x: 22.8, y: 16.6),
            ], closed: false)
            var dash: [CGPoint] = []
            for (index, point) in route.enumerated() {
                dash.append(point)
                if dash.count == 5 {
                    if (index / 5).isMultiple(of: 2) { art.ink(.polyline(dash), .red, width: 1.1) }
                    dash = [point]
                }
            }
            art.shape(.path("M23.4 17.6 C20.8 14.4 19.8 12.8 19.8 11 A3.6 3.6 0 0 1 27 11 C27 12.8 26 14.4 23.4 17.6 Z"), .red, width: 1.2)
            art.dot(23.4, 11, 1.1, .paper)
        },
        SubjectIcon("compass", .humanities, en: "compass", ru: "компас", tint: .red,
                    keys: "navigation навигац orienteering ориентирован direction направлен geography географ travel путешеств") { art in
            let face = EmojiFigure.circle(16, 16, 12)
            art.shape(face, .paper, width: 1.6)
            art.fine(.circle(16, 16, 9.4), .graphite, opacity: 0.6)
            for angle in stride(from: CGFloat(0), to: 360, by: 45) {
                let a = angle * .pi / 180
                let inner: CGFloat = angle.truncatingRemainder(dividingBy: 90) == 0 ? 7.8 : 8.6
                art.fine(.line(16 + cos(a) * inner, 16 + sin(a) * inner, 16 + cos(a) * 9.4, 16 + sin(a) * 9.4), .ink, opacity: 0.8)
            }
            art.shape(.poly(16, 6.4, 18.6, 16, 13.4, 16), .red, width: 1.1)
            art.shape(.poly(13.4, 16, 18.6, 16, 16, 25.6), .steel, width: 1.1)
            art.shape(.circle(16, 16, 1.3), .gold, width: 0.8)
        },
        SubjectIcon("column", .humanities, en: "column", ru: "колонна", tint: .steel,
                    keys: "history истор ancient античн greece древн architecture архитектур classics классическ museum музе") { art in
            art.shape(.box(6.6, 3.8, 18.8, 2.8, r: 0.6), .paper, width: 1.3)
            art.shape(.path("M9 6.6 L23 6.6 C23.4 8.2 22.6 9.4 21 9.4 L11 9.4 C9.4 9.4 8.6 8.2 9 6.6 Z"), .paper, width: 1.2)
            art.fine(.arc(9.6, 8.2, 1.3, from: 60, to: 400))
            art.fine(.arc(22.4, 8.2, 1.3, from: -220, to: 120))
            let shaft = EmojiFigure.path("M10.8 9.4 L21.2 9.4 L20.8 24.4 L11.2 24.4 Z")
            art.fill(shaft, .paper)
            art.clip(shaft) { inside in
                inside.shade(.box(18.4, 0, 10, 32), opacity: 0.25)
            }
            art.ink(shaft, width: 1.3)
            for x in [CGFloat(13.6), 16, 18.4] {
                art.fine(.line(x, 10.4, x, 23.4), .ink, opacity: 0.7)
            }
            art.shape(.box(8.8, 24.4, 14.4, 2.2, r: 0.6), .paper, width: 1.2)
            art.shape(.box(6.6, 26.6, 18.8, 2.4, r: 0.6), .paper, width: 1.3)
        },
        SubjectIcon("hourglass", .humanities, en: "hourglass", ru: "песочные часы", tint: .yellow,
                    keys: "history истор time время deadline дедлайн exam экзамен patience терпени") { art in
            let glass = EmojiFigure.path("M9.4 6.4 C9.4 11.6 14.2 13.4 14.6 16 C14.2 18.6 9.4 20.4 9.4 25.6 L22.6 25.6 C22.6 20.4 17.8 18.6 17.4 16 C17.8 13.4 22.6 11.6 22.6 6.4 Z")
            art.fill(glass, .paper)
            art.clip(glass) { inside in
                inside.fill(.path("M8 10.6 C11 11.4 21 11.4 24 10.6 L24 17 L8 17 Z"), .yellow)
                inside.fill(.path("M8 26 L10.6 22.6 C12.4 20.6 14.4 20.2 16 20 C17.6 20.2 19.6 20.6 21.4 22.6 L24 26 Z"), .yellow)
                inside.shade(.box(18, 0, 10, 32), opacity: 0.18)
            }
            art.ink(.line(16, 16, 16, 21), .gold, width: 0.8)
            art.ink(glass, width: 1.4)
            art.ink(.line(7.8, 6.6, 7.9, 25.4), .brown, width: 1.5)
            art.ink(.line(24.2, 6.6, 24.1, 25.4), .brown, width: 1.5)
            art.shape(.box(5.8, 3.6, 20.4, 3, r: 1), .brown, width: 1.3)
            art.shape(.box(5.8, 25.4, 20.4, 3, r: 1), .brown, width: 1.3)
        },
        SubjectIcon("crown", .humanities, en: "crown", ru: "корона", tint: .gold,
                    keys: "history истор monarchy монарх king корол empire импери power власт") { art in
            let crown = EmojiFigure.poly(5.4, 24.6, 4.4, 10.6, 10.6, 16.2, 16, 7, 21.4, 16.2, 27.6, 10.6, 26.6, 24.6)
            art.fill(crown, .yellow)
            art.clip(crown) { inside in
                inside.fill(.box(0, 20.4, 32, 6), .gold)
                inside.shade(.box(21, 0, 12, 32), opacity: 0.2)
            }
            art.ink(crown, width: 1.5)
            art.fine(.line(5.2, 20.4, 26.8, 20.4))
            art.shape(.circle(4.4, 10, 1.5), .yellow, width: 1)
            art.shape(.circle(16, 6.2, 1.6), .yellow, width: 1)
            art.shape(.circle(27.6, 10, 1.5), .yellow, width: 1)
            art.shape(.oval(16, 22.6, 1.6, 1.3), .red, width: 0.9)
            art.shape(.oval(10.2, 22.6, 1.2, 1), .blue, width: 0.8)
            art.shape(.oval(21.8, 22.6, 1.2, 1), .blue, width: 0.8)
        },
        SubjectIcon("speech", .humanities, en: "speech", ru: "речь", tint: .sky,
                    keys: "language язык communication общени rhetoric риторик debate дебат conversation разговор linguistics лингвист") { art in
            let back = EmojiFigure.path("M15.4 4.4 L25.6 4.4 Q29 4.4 29 7.8 L29 12.4 Q29 15.8 25.6 15.8 L25 15.8 L26.2 19.4 L21.4 15.8 L15.4 15.8 Q12 15.8 12 12.4 L12 7.8 Q12 4.4 15.4 4.4 Z")
            art.shape(back, .sky, width: 1.3)
            art.dot(16.6, 10.2, 0.9)
            art.dot(20.4, 10.2, 0.9)
            art.dot(24.2, 10.2, 0.9)
            let front = EmojiFigure.path("M6.8 11.8 L17.6 11.8 Q21.2 11.8 21.2 15.4 L21.2 20.6 Q21.2 24.2 17.6 24.2 L11.4 24.2 L6 28.2 L7.2 24.2 L6.8 24.2 Q3.2 24.2 3.2 20.6 L3.2 15.4 Q3.2 11.8 6.8 11.8 Z")
            art.shape(front, .paper, width: 1.4)
            art.text("Aa", 12.2, 18, size: 8.4, .red, weight: 0.8)
        },
    ]
}
