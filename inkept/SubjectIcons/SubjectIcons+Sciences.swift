import CoreGraphics

extension SubjectIcon {
    static let sciences: [SubjectIcon] = mathematics + physics + chemistry + life + earth

    // MARK: - Mathematics

    private static let mathematics: [SubjectIcon] = [
        SubjectIcon("math", .sciences, en: "maths", ru: "математика", tint: .red,
                    keys: "math mathematics arithmetic математ арифметик счет") { art in
            art.shape(.box(4.5, 4.5, 23, 23, r: 4), .paper)
            art.fine(.line(16, 5.5, 16.2, 26.5), .graphite, opacity: 0.55)
            art.fine(.line(5.5, 16.1, 26.5, 15.9), .graphite, opacity: 0.55)
            art.bold(.line(7.4, 10.3, 13.6, 10.1), .red)
            art.bold(.line(10.5, 7.2, 10.4, 13.4), .red)
            art.bold(.line(18.6, 10.4, 24.4, 10.2))
            art.bold(.line(8.1, 18.6, 12.9, 23.6))
            art.bold(.line(13, 18.7, 8, 23.5))
            art.bold(.line(18.5, 21.1, 24.5, 21))
            art.dot(21.5, 18.3, 1.05)
            art.dot(21.4, 23.9, 1.05)
        },
        SubjectIcon("pi", .sciences, en: "pi", ru: "пи", tint: .red,
                    keys: "math математ number числ constant констант circle окружн trigonometry тригонометр") { art in
            art.hatch(.circle(17, 17, 10.5), .red, angle: -40, gap: 1.9, opacity: 0.6)
            art.ink(.curve(5.6, 11.4, 8, 9.4, 13, 9.3, 20, 9.2, 25.6, 8.6, 27, 7.4), width: 2.5)
            art.ink(.curve(12.6, 9.6, 12.4, 15, 11.6, 21, 10.2, 24.4, 8.6, 25.6), width: 2.5)
            art.ink(.curve(20.2, 9.5, 20, 15, 20.2, 21.4, 21.4, 24.6, 23.6, 25.2, 25.4, 23.8), width: 2.5)
        },
        SubjectIcon("plot", .sciences, en: "graph of a function", ru: "график функции", tint: .red,
                    keys: "calculus матанализ матан analysis анализ математ function функци integral интеграл derivative производн limit предел") { art in
            art.hatch(.poly(11.6, 25.2, 11.6, 13.2, 13.8, 10.4, 17.2, 9.4, 20.4, 12.4, 22.6, 16, 22.6, 25.2), .red, angle: -45, gap: 1.6, opacity: 0.75)
            art.ink(.line(7, 28, 7.2, 4.4), width: 1.4)
            art.ink(.line(4.6, 7.2, 7.2, 4.4, 9.6, 7.4), width: 1.3)
            art.ink(.line(4, 25.4, 28.4, 25.2), width: 1.4)
            art.ink(.line(25.6, 22.8, 28.4, 25.2, 25.6, 27.8), width: 1.3)
            art.ink(.curve(7.6, 22.8, 10.4, 15.6, 13.8, 10.4, 17.2, 9.4, 20.4, 12.4, 23.4, 17.4, 27, 19.6), .red, width: 2)
            art.fine(.line(11.6, 25.4, 11.6, 13.4), .red)
            art.fine(.line(22.6, 25.4, 22.6, 16), .red)
        },
        SubjectIcon("geometry", .sciences, en: "geometry", ru: "геометрия", tint: .yellow,
                    keys: "geometry геометр drawing черчени triangle треугольн compass циркул stereometry стереометр") { art in
            let square = EmojiFigure.group([.poly(3.4, 27.2, 3.4, 10.4, 19.6, 27.2), .poly(6.8, 23.8, 6.8, 18.4, 12, 23.8)])
            art.fill(square, .yellow, opacity: 0.92, evenOdd: true)
            art.ink(.poly(3.4, 27.2, 3.4, 10.4, 19.6, 27.2), width: 1.4)
            art.fine(.poly(6.8, 23.8, 6.8, 18.4, 12, 23.8))
            for index in 0..<5 {
                let y = 13 + CGFloat(index) * 2.8
                art.fine(.line(3.5, y, index.isMultiple(of: 2) ? 5.4 : 4.7, y), .ink, opacity: 0.8)
            }
            art.ink(.line(23, 6.4, 19.4, 26.8), width: 1.7)
            art.ink(.line(23, 6.4, 28.4, 25.8), width: 1.7)
            art.fill(.poly(27.2, 22.4, 29, 21.9, 28.8, 26.6), .red)
            art.ink(.line(23, 6.6, 23.1, 2.6), width: 1.6)
            art.shape(.circle(23, 6.6, 1.9), .steel, width: 1.1)
        },
        SubjectIcon("chart", .sciences, en: "chart", ru: "диаграмма", tint: .blue,
                    keys: "statistics статистик data данн analytics аналитик probability вероятност econometrics эконометрик") { art in
            let bars: [(CGFloat, CGFloat, InkPencil)] = [(5, 18.4, .sky), (11, 13.8, .yellow), (17, 16, .lime), (23, 8.8, .red)]
            for (x, top, pencil) in bars {
                art.shape(.box(x, top, 4.6, 26.2 - top, r: 0.6), pencil, width: 1.2)
            }
            art.ink(.line(3.4, 26.4, 29, 26.2), width: 1.5)
            art.fine(.line(7.2, 13.6, 13.2, 9.4, 19.2, 11.2, 25.4, 4.4))
            art.fine(.line(22.8, 4.6, 25.4, 4.4, 25.4, 7))
        },
        SubjectIcon("dice", .sciences, en: "dice", ru: "кости", tint: .red,
                    keys: "probability вероятност chance случа game игр random случайн combinatorics комбинатор") { art in
            art.shape(EmojiFigure.box(15.4, 4.2, 12, 12, r: 2.4).rotated(16, around: 21.4, 10.2), .red, width: 1.3)
            for (x, y) in [(18.6, 7.6), (24.2, 12.8)] as [(CGFloat, CGFloat)] {
                let pip = EmojiFigure.turn(x, y, 16, around: 21.4, 10.2)
                art.dot(pip.x, pip.y, 1.15, .paper)
            }
            art.shape(EmojiFigure.box(4.4, 12.6, 13.6, 13.6, r: 2.6).rotated(-9, around: 11.2, 19.4), .paper, width: 1.4)
            for (x, y) in [(7.9, 16.1), (14.5, 16.1), (11.2, 19.4), (7.9, 22.7), (14.5, 22.7)] as [(CGFloat, CGFloat)] {
                let pip = EmojiFigure.turn(x, y, -9, around: 11.2, 19.4)
                art.dot(pip.x, pip.y, 1.2, .ink)
            }
        },
        SubjectIcon("matrix", .sciences, en: "matrix", ru: "матрица", tint: .red,
                    keys: "linear algebra линейн алгебр линал vector вектор determinant определител") { art in
            art.ink(.line(9.6, 5.4, 6, 5.4, 6, 26.6, 9.6, 26.6), width: 2)
            art.ink(.line(22.4, 5.4, 26, 5.4, 26, 26.6, 22.4, 26.6), width: 2)
            art.text("1", 11.8, 11.6, size: 10, .red, weight: 1)
            art.text("0", 20.2, 11.6, size: 10, .graphite)
            art.text("0", 11.8, 21.2, size: 10, .graphite)
            art.text("1", 20.2, 21.2, size: 10, .red, weight: 1)
        },
        SubjectIcon("infinity", .sciences, en: "infinity", ru: "бесконечность", tint: .purple,
                    keys: "analysis анализ limit предел series ряд set множеств logic логик") { art in
            let points = (0...72).map { step -> CGPoint in
                let t = CGFloat(step) / 72 * 2 * .pi
                let denominator = 1 + sin(t) * sin(t)
                return CGPoint(x: 16 + 12.6 * cos(t) / denominator, y: 16 + 14.5 * sin(t) * cos(t) / denominator)
            }
            art.hatch(.polygon(points), .purple, angle: -50, gap: 1.6, opacity: 0.8)
            art.ink(.polygon(points), width: 2.4)
        },
        SubjectIcon("calculator", .sciences, en: "calculator", ru: "калькулятор", tint: .navy,
                    keys: "arithmetic арифметик accounting бухгалтер calculation вычислен счет") { art in
            art.shape(.box(7, 3.4, 18, 25.4, r: 3), .navy, width: 1.4)
            art.shape(.box(9.6, 6, 12.8, 5.6, r: 1), .paper, width: 1.1)
            art.text("3,14", 16, 8.7, size: 6.4, .ink)
            for row in 0..<3 {
                for column in 0..<3 {
                    let isEquals = row == 2 && column == 2
                    art.shape(
                        .box(9.4 + CGFloat(column) * 4.6, 14 + CGFloat(row) * 4.4, 3.6, 3.2, r: 0.9),
                        isEquals ? .red : .paper,
                        width: 0.8
                    )
                }
            }
        },
    ]

    // MARK: - Physics and astronomy

    private static let physics: [SubjectIcon] = [
        SubjectIcon("atom", .sciences, en: "atom", ru: "атом", tint: .blue,
                    keys: "physics физик quantum квант nuclear ядер particle частиц") { art in
            for (index, tilt) in [CGFloat(0), 60, 120].enumerated() {
                art.ink(.oval(16, 16, 12.6, 4.7, rotation: tilt), width: 1.25)
                let angle: CGFloat = [0.35, 3.6, 2.2][index]
                let electron = EmojiCurves.ellipsePoint(CGPoint(x: 16, y: 16), 12.6, 4.7, tilt, angle)
                art.shape(.circle(electron.x, electron.y, 1.55), .sky, width: 1)
            }
            art.shape(.circle(16, 16, 3.3), .red, width: 1.3)
            art.fine(.arc(15.2, 15.2, 1.4, from: 190, to: 260), .paper)
        },
        SubjectIcon("magnet", .sciences, en: "magnet", ru: "магнит", tint: .red,
                    keys: "physics физик magnetism магнетизм electromagnetism электромагнет field пол") { art in
            let magnet = EmojiFigure.path("M4.6 14 A11.4 11.4 0 0 1 27.4 14 L27.4 25.4 L21.2 25.4 L21.2 14 A5.2 5.2 0 0 0 10.8 14 L10.8 25.4 L4.6 25.4 Z")
            art.fill(magnet, .red)
            art.clip(magnet) { inside in
                inside.fill(.box(0, 21, 32, 8), .steel)
                inside.shade(.box(22, 0, 10, 32), opacity: 0.2)
            }
            art.ink(magnet, width: 1.5)
            art.fine(.line(4.8, 21.1, 10.7, 21))
            art.fine(.line(21.3, 21.1, 27.2, 21))
            art.fine(.curve(6.4, 27.8, 7.8, 29.6, 9.6, 30.2), .graphite)
            art.fine(.curve(22.8, 27.8, 24.2, 29.6, 26, 30.2), .graphite)
            art.fine(.arc(9.2, 12.6, 2.2, from: 200, to: 260), .paper)
        },
        SubjectIcon("lightning", .sciences, en: "lightning", ru: "молния", tint: .yellow,
                    keys: "electricity электричеств electronics электроник energy энерги power ток current") { art in
            let bolt = EmojiFigure.poly(18.8, 2.8, 6.8, 18.2, 14.6, 18, 11.8, 29.2, 25.4, 12.6, 17.4, 12.8, 21.8, 2.8)
            art.fill(bolt, .yellow)
            art.clip(bolt) { inside in
                inside.shade(.poly(17.4, 12.8, 25.4, 12.6, 11.8, 29.2, 16, 18), opacity: 0.25)
            }
            art.ink(bolt, width: 1.5)
        },
        SubjectIcon("prism", .sciences, en: "prism", ru: "призма", tint: .sky,
                    keys: "optics оптик light свет spectrum спектр rainbow радуг waves волн") { art in
            art.ink(.line(1, 20.4, 11.4, 16.4), .graphite, width: 1.3)
            let colours: [InkPencil] = [.red, .orange, .yellow, .lime, .sky, .purple]
            for (index, pencil) in colours.enumerated() {
                let spread = CGFloat(index) * 1.9
                art.ink(.line(20, 15.4 + CGFloat(index) * 0.35, 31, 12.6 + spread), pencil, width: 1.35)
            }
            let prism = EmojiFigure.poly(16, 5, 26.6, 25, 5.4, 25)
            art.fill(prism, .sky, opacity: 0.45)
            art.clip(prism) { inside in
                inside.hatch(.box(0, 0, 32, 32), .sky, angle: -60, gap: 1.8, opacity: 0.9)
            }
            art.ink(prism, width: 1.5)
            art.ink(.line(12.6, 11.8, 10.8, 16.4), .paper, width: 0.9)
        },
        SubjectIcon("gears", .sciences, en: "gears", ru: "шестерёнки", tint: .gold,
                    keys: "engineering инженер mechanics механик machine машин technology технолог robotics робототехник") { art in
            art.shape(.gear(12.2, 19, outer: 9.6, inner: 7.4, teeth: 9, rotation: 8), .gold)
            art.shape(.circle(12.2, 19, 3), .paper, width: 1.2)
            art.shape(.gear(23.4, 9.2, outer: 6.8, inner: 5, teeth: 7, rotation: 20), .steel)
            art.shape(.circle(23.4, 9.2, 2), .paper, width: 1.1)
        },
        SubjectIcon("rocket", .sciences, en: "rocket", ru: "ракета", tint: .red,
                    keys: "space космос astronautics космонавтик aerospace аэрокосмич launch запуск startup стартап") { art in
            let tilt: CGFloat = 42
            let body = EmojiFigure.path("M16 3 C20.6 7 21.6 13.2 21 20.4 L11 20.4 C10.4 13.2 11.4 7 16 3 Z").rotated(tilt)
            art.fill(EmojiFigure.blob(13.4, 20.6, 16, 29.4, 18.6, 20.6).rotated(tilt), .orange)
            art.fill(EmojiFigure.blob(14.6, 20.6, 16, 25.6, 17.4, 20.6).rotated(tilt), .yellow)
            art.shape(EmojiFigure.poly(11.2, 14.6, 6.8, 20.8, 7, 23.8, 11.2, 20.8).rotated(tilt), .red, width: 1.3)
            art.shape(EmojiFigure.poly(20.8, 14.6, 25.2, 20.8, 25, 23.8, 20.8, 20.8).rotated(tilt), .red, width: 1.3)
            art.fill(body, .paper)
            art.clip(body) { inside in
                inside.fill(EmojiFigure.box(0, 0, 32, 7.8).rotated(tilt), .red)
                inside.shade(EmojiFigure.box(18.6, 0, 8, 32).rotated(tilt), opacity: 0.2)
            }
            art.ink(body, width: 1.5)
            let window = EmojiFigure.turn(16, 11.6, tilt)
            art.shape(.circle(window.x, window.y, 2.4), .sky, width: 1.2)
            art.ink(EmojiFigure.line(13.8, 20.4, 18.2, 20.4).rotated(tilt), width: 1.2)
        },
        SubjectIcon("planet", .sciences, en: "planet", ru: "планета", tint: .tan,
                    keys: "astronomy астроном space космос saturn сатурн universe вселенн") { art in
            let tilt: CGFloat = -18
            let ring = EmojiFigure.group([.oval(16, 16.4, 14.6, 4.3, rotation: tilt), .oval(16, 16.4, 10.8, 2.7, rotation: tilt)])
            art.fill(ring, .gold, evenOdd: true)
            art.ink(.oval(16, 16.4, 14.6, 4.3, rotation: tilt), width: 1.2)
            art.fine(.oval(16, 16.4, 10.8, 2.7, rotation: tilt))
            let sphere = EmojiFigure.circle(16, 16, 8.4)
            art.fill(sphere, .tan)
            art.clip(sphere) { inside in
                inside.fill(EmojiFigure.box(0, 12.6, 32, 2.2).rotated(tilt), .orange, opacity: 0.8)
                inside.fill(EmojiFigure.box(0, 18.2, 32, 1.6).rotated(tilt), .orange, opacity: 0.7)
                inside.shade(.path("M19 4 A 9 9 0 0 1 19 28 L32 28 L32 4 Z"), opacity: 0.24)
            }
            art.ink(sphere, width: 1.4)
            // The ring's near side passes in front of the planet.
            art.clip(EmojiFigure.box(-4, 16.4, 40, 14).rotated(tilt, around: 16, 16.4)) { front in
                front.fill(ring, .gold, evenOdd: true)
            }
            art.ink(.arc(center: CGPoint(x: 16, y: 16.4), rx: 14.6, ry: 4.3, from: 0, to: 180, rotation: tilt), width: 1.2)
            art.fine(.arc(center: CGPoint(x: 16, y: 16.4), rx: 10.8, ry: 2.7, from: 0, to: 180, rotation: tilt))
        },
        SubjectIcon("telescope", .sciences, en: "telescope", ru: "телескоп", tint: .navy,
                    keys: "astronomy астроном stars звезд observatory обсерватор space космос") { art in
            art.ink(.line(15.6, 17.6, 9.6, 28.6), width: 1.5)
            art.ink(.line(15.8, 17.6, 21.6, 28.6), width: 1.5)
            art.ink(.line(15.7, 17.6, 15.8, 28.8), width: 1.3)
            let tube = EmojiFigure.box(5.6, 10.6, 19.6, 5.6, r: 1.2).rotated(-27, around: 15.4, 13.4)
            art.shape(tube, .navy)
            art.shape(EmojiFigure.box(24, 9.8, 2.8, 7.2, r: 0.8).rotated(-27, around: 15.4, 13.4), .gold, width: 1.2)
            art.shape(EmojiFigure.box(3, 11.9, 3, 3, r: 0.5).rotated(-27, around: 15.4, 13.4), .steel, width: 1.1)
            art.shape(.circle(15.6, 16.6, 1.5), .steel, width: 1)
            art.shape(.star(26.4, 23.2, 3.2, inner: 1.3, points: 4, rotation: -90), .yellow, width: 0.9)
            art.shape(.star(28.4, 4.6, 2, inner: 0.8, points: 4, rotation: -90), .yellow, width: 0.8)
        },
        SubjectIcon("thermometer", .sciences, en: "thermometer", ru: "термометр", tint: .red,
                    keys: "thermodynamics термодинамик temperature температур heat тепл weather погод climate климат") { art in
            let glass = EmojiFigure.path("M13 21.2 L13 6.4 A3 3 0 0 1 19 6.4 L19 21.2 A5 5 0 1 1 13 21.2 Z")
            art.fill(glass, .paper)
            art.fill(.box(14.7, 11, 2.6, 12), .red)
            art.fill(.circle(16, 25.2, 3.2), .red)
            art.ink(glass, width: 1.5)
            for index in 0..<5 {
                let y = 7.6 + CGFloat(index) * 2.8
                art.fine(.line(19.2, y, index.isMultiple(of: 2) ? 22.4 : 21.2, y))
            }
            art.fine(.arc(14.4, 24.4, 1.2, from: 180, to: 250), .paper)
        },
    ]

    // MARK: - Chemistry

    private static let chemistry: [SubjectIcon] = [
        SubjectIcon("flask", .sciences, en: "flask", ru: "колба", tint: .teal,
                    keys: "chemistry хими lab лаборатор reaction реакц experiment опыт") { art in
            let flask = EmojiFigure.path("M13.2 4.6 L13.2 12.4 L6.6 24.2 Q5.4 27.2 8.8 27.2 L23.2 27.2 Q26.6 27.2 25.4 24.2 L18.8 12.4 L18.8 4.6 Z")
            art.fill(flask, .paper)
            art.clip(flask) { inside in
                inside.fill(.path("M0 19.4 C 6 18.4 10 20.2 16 19.2 S 26 18.4 32 19.6 L32 32 L0 32 Z"), .teal)
                inside.shade(.box(19, 12, 10, 16), opacity: 0.22)
            }
            art.fine(.curve(9.4, 19.3, 13, 18.8, 16.4, 19.5, 20, 18.8, 22.8, 19.3))
            art.ink(flask)
            art.ink(.line(11.8, 4.6, 20.2, 4.5), width: 1.9)
            art.shape(.circle(14.2, 23.4, 1.3), .paper, width: 0.9)
            art.shape(.circle(18.6, 22, 0.9), .paper, width: 0.8)
            art.fine(.circle(16.4, 15.8, 0.8))
            art.fine(.circle(15, 11.6, 0.55))
        },
        SubjectIcon("test-tubes", .sciences, en: "test tubes", ru: "пробирки", tint: .purple,
                    keys: "chemistry хими lab лаборатор biochemistry биохими") { art in
            let tubes: [(CGFloat, CGFloat, InkPencil)] = [(6.4, 14.4, .red), (13.8, 10.8, .yellow), (21.2, 16.6, .purple)]
            for (x, level, pencil) in tubes {
                let tube = EmojiFigure.path("M\(x) 4.6 L\(x) 23.6 A2.2 2.2 0 0 0 \(x + 4.4) 23.6 L\(x + 4.4) 4.6 Z")
                art.fill(tube, .paper)
                art.clip(tube) { inside in
                    inside.fill(.box(0, level, 32, 20), pencil)
                }
                art.fine(.line(x + 0.2, level + 0.1, x + 4.2, level - 0.1))
                art.ink(tube, width: 1.3)
                art.ink(.line(x - 0.9, 4.6, x + 5.3, 4.5), width: 1.4)
            }
            art.shape(.box(3.2, 18.6, 25.6, 3.4, r: 0.8), .tan, width: 1.3)
            art.ink(.line(4.6, 22, 4.2, 28.4), width: 1.5)
            art.ink(.line(27.4, 22, 27.8, 28.4), width: 1.5)
        },
        SubjectIcon("molecule", .sciences, en: "molecule", ru: "молекула", tint: .red,
                    keys: "chemistry хими organic органическ bond связ compound соединен biochemistry биохими") { art in
            let center = CGPoint(x: 15.2, y: 16.6)
            let atoms: [(CGFloat, CGFloat, CGFloat, InkPencil)] = [
                (6.4, 9.6, 3, .sky), (25.4, 8.4, 3.3, .yellow), (23.6, 25, 2.9, .paper), (6.8, 25.2, 2.5, .lime),
            ]
            for (x, y, _, _) in atoms {
                art.ink(.line(center.x, center.y, x, y), width: 1.6)
            }
            for (x, y, r, pencil) in atoms {
                art.shape(.circle(x, y, r), pencil, width: 1.2)
                art.fine(.arc(x - r * 0.25, y - r * 0.25, r * 0.45, from: 190, to: 260), .paper)
            }
            art.shape(.circle(center.x, center.y, 4.4), .red, width: 1.4)
            art.fine(.arc(center.x - 1.2, center.y - 1.2, 1.9, from: 190, to: 260), .paper)
        },
        SubjectIcon("benzene", .sciences, en: "benzene ring", ru: "бензольное кольцо", tint: .teal,
                    keys: "organic органическ chemistry хими hydrocarbon углеводород aromatic ароматич") { art in
            let ring = EmojiFigure.ngon(16, 16, 11, sides: 6, rotation: -90)
            art.hatch(ring, .teal, angle: -40, gap: 1.8, opacity: 0.8)
            art.ink(ring, width: 1.9)
            art.ink(.circle(16, 16, 6), .teal, width: 1.4)
        },
    ]

    // MARK: - Life

    private static let life: [SubjectIcon] = [
        SubjectIcon("dna", .sciences, en: "DNA", ru: "ДНК", tint: .green,
                    keys: "biology биолог genetics генет gene ген heredity наследствен") { art in
            let turns: CGFloat = 1.3
            func strand(_ phase: CGFloat) -> [CGPoint] {
                stride(from: CGFloat(3.4), through: 28.6, by: 0.5).map { y in
                    CGPoint(x: 16 + 6.4 * sin((y - 3.4) / 25.2 * 2 * .pi * turns + phase), y: y)
                }
            }
            let rungs: [InkPencil] = [.red, .yellow, .sky, .green]
            for (index, y) in stride(from: CGFloat(5.6), through: 27, by: 3).enumerated() {
                let offset = 6.4 * sin((y - 3.4) / 25.2 * 2 * .pi * turns)
                guard abs(offset) > 1.4 else { continue }
                let inset: CGFloat = offset > 0 ? 0.8 : -0.8
                art.ink(.line(16 - offset + inset, y, 16 + offset - inset, y), rungs[index % rungs.count], width: 1.7)
            }
            art.ink(.smooth(strand(0), closed: false), width: 1.7)
            art.ink(.smooth(strand(.pi), closed: false), width: 1.7)
        },
        SubjectIcon("microscope", .sciences, en: "microscope", ru: "микроскоп", tint: .navy,
                    keys: "biology биолог microbiology микробиолог lab лаборатор cells клетк research исследован") { art in
            art.shape(.path("M17.6 25.4 C22.6 22.4 23.4 16.6 20.6 12.2 L23 10.8 C26.8 16.2 26 22.8 21.4 25.4 Z"), .navy, width: 1.3)
            art.shape(.box(5.6, 25, 20.8, 3.8, r: 1.6), .navy, width: 1.4)
            art.shape(.box(8, 18.6, 12.4, 2.2, r: 0.6), .steel, width: 1.2)
            art.fill(.box(10.6, 18.1, 5.4, 0.9), .sky)
            let tilt: CGFloat = 24
            art.shape(EmojiFigure.box(11.4, 4.4, 5.2, 11.6, r: 0.8).rotated(tilt, around: 14, 10.2), .paper)
            art.shape(EmojiFigure.box(11.2, 2, 5.6, 3, r: 0.8).rotated(tilt, around: 14, 10.2), .navy, width: 1.2)
            art.shape(EmojiFigure.box(12.6, 15.8, 2.8, 2.4, r: 0.4).rotated(tilt, around: 14, 10.2), .steel, width: 1.1)
            art.shape(.circle(20.8, 11.4, 1.7), .steel, width: 1)
            art.shape(.oval(13.6, 23.2, 2.4, 0.9), .yellow, width: 0.9)
        },
        SubjectIcon("leaf", .sciences, en: "leaf", ru: "лист", tint: .green,
                    keys: "botany ботаник biology биолог ecology эколог plants растени nature природ environment окружающ") { art in
            let leaf = EmojiFigure.path("M5.6 26.6 C5 14.6 13 5.4 27.6 4.6 C28 18.4 19.6 26.8 5.6 26.6 Z")
            art.fill(leaf, .green)
            art.clip(leaf) { inside in
                inside.hatch(.path("M5 27 L28 4 L32 32 Z"), .ink, angle: -30, gap: 1.6, opacity: 0.2)
            }
            art.ink(leaf, width: 1.5)
            art.ink(.curve(3.2, 29, 7.4, 24.4, 13.4, 18, 20.6, 11.2, 26.2, 6.2), width: 1.2)
            for (x, y, dx, dy) in [(10.4, 21.2, -0.6, -6), (14.6, 16.8, -0.4, -6), (19, 12.6, 0, -4.8), (11.6, 20, 5.8, 0.8), (16, 15.4, 6.2, 0.6), (20.4, 11, 4.8, 0.2)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
                art.fine(.curve(x, y, x + dx * 0.55 + (dx == 0 ? 0.6 : 0), y + dy * 0.6, x + dx, y + dy), .ink, opacity: 0.75)
            }
        },
        SubjectIcon("cell", .sciences, en: "cell", ru: "клетка", tint: .rose,
                    keys: "biology биолог cytology цитолог organism организм microbiology микробиолог") { art in
            let membrane = EmojiFigure.blob(6.4, 9.6, 13.6, 5, 22.8, 5.8, 28, 12.4, 27.2, 21.6, 20.8, 27.4, 11.4, 27.2, 4.8, 21.4, 4, 14.4)
            art.fill(membrane, .rose)
            art.ink(membrane, width: 1.5)
            art.fine(.blob(8.4, 10.6, 14.2, 7.2, 22, 8, 25.8, 13, 25, 20.6, 19.8, 25.2, 12.2, 25, 7, 20.6, 6.4, 14.6), .ink, opacity: 0.35)
            art.shape(.circle(13.6, 15, 5), .purple, width: 1.3)
            art.dot(12.6, 14.2, 1.5, .navy)
            art.shape(.oval(21.8, 19.8, 3.2, 1.8, rotation: -30), .orange, width: 1)
            art.fine(.curve(19.6, 20.6, 20.6, 19.4, 21.8, 20.4, 23, 19))
            art.shape(.oval(20.2, 10.8, 2.4, 1.4, rotation: 20), .orange, width: 0.9)
            for (x, y) in [(10.4, 22.6), (13.4, 23.4), (24.6, 13.6), (17.2, 23.6)] as [(CGFloat, CGFloat)] {
                art.dot(x, y, 0.6, .ink)
            }
        },
        SubjectIcon("brain", .sciences, en: "brain", ru: "мозг", tint: .rose,
                    keys: "psychology психолог neuroscience нейро cognitive когнитив mind разум memory памят thinking мышлен") { art in
            let brain = EmojiFigure.path("""
            M9.2 22.4 C5.6 22.2 3.6 19 4.4 15.8 C3.8 11.6 7 8.2 10.8 7.8 C12.6 5.2 16.8 4.4 19.6 6 \
            C23 5.4 26.6 7.8 27.2 11.6 C29 13.6 28.8 17.4 26.6 19.2 C25.8 22.2 22.8 23.8 19.8 22.8 \
            C17.2 24.2 12.2 24.4 9.2 22.4 Z
            """)
            art.shape(.path("M16.4 23 C16.8 25 16.6 27 15.8 28.8 L19.4 28.8 C18.8 27 18.8 25 19.2 23.2 Z"), .rose, width: 1.3)
            art.fill(brain, .rose)
            art.clip(brain) { inside in
                inside.shade(.path("M4 17 C10 20 20 21 29 16 L29 26 L4 26 Z"), opacity: 0.18)
            }
            art.ink(brain, width: 1.5)
            art.fine(.curve(8, 13.6, 10.4, 11.8, 12.6, 13.4, 14.6, 10.4))
            art.fine(.curve(16.8, 7.6, 16.2, 10, 18.4, 12.2, 21.6, 11))
            art.fine(.curve(22.8, 8.8, 24, 11.2, 23.4, 13.6))
            art.fine(.curve(7.4, 18.8, 10, 17.4, 12.4, 19, 15.6, 16.4, 18.6, 17.8))
            art.fine(.curve(20.6, 15.2, 22.8, 16.4, 25.4, 15))
            art.fine(.curve(11.4, 15.2, 13.8, 15.2, 15.4, 13.6))
        },
        SubjectIcon("stethoscope", .sciences, en: "stethoscope", ru: "стетоскоп", tint: .navy,
                    keys: "medicine медицин doctor врач health здоров anatomy анатом physiology физиолог clinic клиник") { art in
            art.ink(.curve(8.6, 4.4, 7.6, 10.6, 9.2, 16.2, 13.2, 18.6, 17.2, 16.2, 18.8, 10.6, 17.8, 4.4), .navy, width: 2.1)
            art.ink(.curve(13.2, 18.8, 13.4, 23.6, 16.6, 27.2, 21, 26.6, 23.4, 23.6, 23.8, 20.6), .navy, width: 2.1)
            art.shape(.circle(8.6, 4, 1.3), .steel, width: 0.9)
            art.shape(.circle(17.8, 4, 1.3), .steel, width: 0.9)
            art.shape(.circle(23.8, 17.2, 4.2), .steel, width: 1.4)
            art.shape(.circle(23.8, 17.2, 2.2), .paper, width: 1)
        },
        SubjectIcon("pill", .sciences, en: "pills", ru: "таблетки", tint: .red,
                    keys: "medicine медицин pharmacology фармаколог pharmacy аптек drugs лекарств health здоров") { art in
            let tilt: CGFloat = -38
            let capsule = EmojiFigure.box(5, 11.4, 20, 8.4, r: 4.2).rotated(tilt, around: 15, 15.6)
            art.fill(capsule, .paper)
            art.clip(capsule) { inside in
                inside.fill(EmojiFigure.box(-10, -10, 25, 50).rotated(tilt, around: 15, 15.6), .red)
                inside.shade(EmojiFigure.box(-10, 16.4, 50, 10).rotated(tilt, around: 15, 15.6), opacity: 0.2)
            }
            art.ink(capsule, width: 1.5)
            art.ink(EmojiFigure.line(15, 11.6, 15, 19.6).rotated(tilt, around: 15, 15.6), width: 1.2)
            art.ink(EmojiFigure.curve(8.4, 13.4, 11.2, 12.6).rotated(tilt, around: 15, 15.6), .paper, width: 0.9)
            art.shape(.oval(23.6, 24.4, 5.2, 4.4), .paper, width: 1.3)
            art.fine(.line(21, 22.4, 26.2, 26.4))
        },
    ]

    // MARK: - Earth

    private static let earth: [SubjectIcon] = [
        SubjectIcon("crystal", .sciences, en: "crystal", ru: "кристалл", tint: .purple,
                    keys: "geology геолог mineralogy минералог mineral минерал gem камен crystallography кристаллограф") { art in
            let gem = EmojiFigure.poly(8.6, 6, 23.4, 6, 28.6, 12.6, 16, 27.6, 3.4, 12.6)
            art.fill(gem, .purple)
            art.clip(gem) { inside in
                inside.fill(.poly(12, 12.6, 20, 12.6, 16, 27.6), .purple, opacity: 0.6)
                inside.shade(.poly(20, 12.6, 28.6, 12.6, 16, 27.6), opacity: 0.3)
                inside.fill(.poly(8.6, 6, 12, 12.6, 3.4, 12.6), .paper, opacity: 0.35)
            }
            art.ink(gem, width: 1.5)
            art.fine(.line(3.6, 12.6, 28.4, 12.6))
            art.fine(.line(8.6, 6.2, 12, 12.6, 16, 6.2, 20, 12.6, 23.4, 6.2))
            art.fine(.line(12, 12.6, 16, 27.2, 20, 12.6))
        },
        SubjectIcon("volcano", .sciences, en: "volcano", ru: "вулкан", tint: .orange,
                    keys: "geology геолог geography географ earth земл nature природ") { art in
            art.fill(.blob(10.6, 6.2, 13.4, 3.6, 17, 4.8, 20.4, 3.2, 23, 5.6, 21.4, 8.4, 16.2, 9, 12, 8.6), .steel, opacity: 0.8)
            art.fine(.blob(10.6, 6.2, 13.4, 3.6, 17, 4.8, 20.4, 3.2, 23, 5.6, 21.4, 8.4, 16.2, 9, 12, 8.6), .graphite)
            let mountain = EmojiFigure.poly(2.8, 27.6, 12.4, 11.6, 19.6, 11.6, 29.2, 27.6)
            art.fill(mountain, .brown)
            art.clip(mountain) { inside in
                inside.fill(.path("M12.4 11.6 L19.6 11.6 L18.8 15.2 L20.6 19.8 L17.8 17.8 L16.4 22.4 L14.8 17.4 L12 19.6 L13.4 14.6 Z"), .orange)
                inside.shade(.poly(19.6, 11.6, 29.2, 27.6, 20, 27.6), opacity: 0.3)
            }
            art.ink(mountain, width: 1.5)
            art.fill(.poly(13, 10.8, 19, 10.8, 18, 12.2, 14, 12.2), .red)
        },
    ]
}
