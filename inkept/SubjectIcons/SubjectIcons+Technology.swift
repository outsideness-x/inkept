import CoreGraphics

extension SubjectIcon {
    static let technology: [SubjectIcon] = computing + platforms + programmingLanguages + tools

    // MARK: - Computing

    private static let computing: [SubjectIcon] = [
        SubjectIcon("code", .technology, en: "code", ru: "код", tint: .blue,
                    keys: "programming программ coding developer разработ computer компьют informatics информат") { art in
            art.shape(.box(3.5, 5.5, 25, 21, r: 3.5), .paper)
            art.fill(.box(3.5, 5.5, 25, 4.6, r: 2), .navy)
            art.ink(.box(3.5, 5.5, 25, 21, r: 3.5))
            art.fine(.line(3.8, 10.1, 28.2, 10))
            art.dot(6.6, 7.8, 0.75, .red)
            art.dot(9.2, 7.8, 0.75, .yellow)
            art.dot(11.8, 7.8, 0.75, .lime)
            art.bold(.line(12.4, 14.2, 8.4, 18.2, 12.4, 22.2))
            art.bold(.line(19.6, 14.2, 23.6, 18.2, 19.6, 22.2))
            art.ink(.line(17.6, 13.2, 14.6, 23.4), .red, width: 1.9)
        },
        SubjectIcon("terminal", .technology, en: "terminal", ru: "терминал", tint: .black,
                    keys: "command командн shell bash linux console консол devops unix") { art in
            art.shape(.box(3.4, 5.6, 25.2, 21, r: 3.4), .black)
            art.fine(.line(3.8, 10, 28.2, 9.9), .white, opacity: 0.6)
            art.dot(6.6, 7.8, 0.75, .red)
            art.dot(9.2, 7.8, 0.75, .yellow)
            art.dot(11.8, 7.8, 0.75, .lime)
            art.ink(.line(8, 13.8, 12.6, 17.4, 8, 21), .lime, width: 2)
            art.ink(.line(14.8, 21.4, 22, 21.3), .lime, width: 2)
        },
        SubjectIcon("database", .technology, en: "database", ru: "база данных", tint: .blue,
                    keys: "data данн sql storage хранени backend бэкенд server сервер") { art in
            let body = EmojiFigure.path("M5.4 7.6 L5.4 24.4 A10.6 3.6 0 0 0 26.6 24.4 L26.6 7.6 Z")
            art.fill(body, .blue)
            art.clip(body) { inside in
                inside.shade(.box(20.4, 0, 12, 32), opacity: 0.22)
            }
            art.ink(body, width: 1.5)
            art.ink(.arc(center: CGPoint(x: 16, y: 13.2), rx: 10.6, ry: 3.6, from: 0, to: 180, rotation: 0), width: 1.2)
            art.ink(.arc(center: CGPoint(x: 16, y: 18.8), rx: 10.6, ry: 3.6, from: 0, to: 180, rotation: 0), width: 1.2)
            art.shape(.oval(16, 7.6, 10.6, 3.6), .sky, width: 1.4)
            art.dot(22.4, 16.4, 0.8, .yellow)
            art.dot(22.4, 22, 0.8, .yellow)
        },
        SubjectIcon("chip", .technology, en: "chip", ru: "микросхема", tint: .gold,
                    keys: "hardware железо electronics электроник computer компьют architecture архитектур processor процессор embedded встраиваем") { art in
            for index in 0..<4 {
                let offset = 10.6 + CGFloat(index) * 3.6
                art.ink(.line(offset, 4, offset, 8), .steel, width: 1.4)
                art.ink(.line(offset, 24, offset, 28), .steel, width: 1.4)
                art.ink(.line(4, offset, 8, offset), .steel, width: 1.4)
                art.ink(.line(24, offset, 28, offset), .steel, width: 1.4)
            }
            art.shape(.box(7.6, 7.6, 16.8, 16.8, r: 2), .black, width: 1.5)
            art.shape(.box(11.4, 11.4, 9.2, 9.2, r: 1), .gold, width: 1.1)
            art.dot(10.2, 10.2, 0.7, .white)
        },
        SubjectIcon("robot", .technology, en: "robot", ru: "робот", tint: .steel,
                    keys: "ai ии artificial искусствен intelligence интеллект machine learning машинн обучени robotics робототехник neural нейро") { art in
            art.ink(.line(16, 8.8, 16, 4.6), width: 1.4)
            art.shape(.circle(16, 3.8, 1.6), .red, width: 1)
            art.shape(.box(3.8, 14.2, 3, 6, r: 1), .steel, width: 1.1)
            art.shape(.box(25.2, 14.2, 3, 6, r: 1), .steel, width: 1.1)
            let head = EmojiFigure.box(6.6, 8.6, 18.8, 16.6, r: 4)
            art.fill(head, .steel)
            art.clip(head) { inside in
                inside.shade(.box(20.6, 0, 10, 32), opacity: 0.22)
            }
            art.ink(head, width: 1.5)
            art.shape(.circle(11.8, 14.6, 2.6), .sky, width: 1.1)
            art.shape(.circle(20.2, 14.6, 2.6), .sky, width: 1.1)
            art.dot(12.2, 14.4, 0.8)
            art.dot(20.6, 14.4, 0.8)
            art.shape(.box(11, 19.6, 10, 3, r: 1), .paper, width: 1)
            for x in [CGFloat(13.6), 16, 18.4] {
                art.fine(.line(x, 19.8, x, 22.4))
            }
        },
        SubjectIcon("network", .technology, en: "network", ru: "сеть", tint: .red,
                    keys: "networks сети graph граф algorithms алгоритм internet интернет discrete дискретн") { art in
            let nodes: [CGPoint] = [
                CGPoint(x: 16, y: 15.4), CGPoint(x: 6.4, y: 7.8), CGPoint(x: 25.6, y: 6.8),
                CGPoint(x: 26.2, y: 23.4), CGPoint(x: 7.2, y: 24.6), CGPoint(x: 16.4, y: 4.4),
            ]
            for (a, b) in [(0, 1), (0, 2), (0, 3), (0, 4), (1, 5), (5, 2), (3, 4)] {
                art.ink(.line(nodes[a].x, nodes[a].y, nodes[b].x, nodes[b].y), width: 1.3)
            }
            let colours: [InkPencil] = [.red, .sky, .yellow, .lime, .paper, .paper]
            for (index, node) in nodes.enumerated() {
                art.shape(.circle(node.x, node.y, index == 0 ? 3.6 : 2.5), colours[index], width: 1.2)
            }
        },
        SubjectIcon("laptop", .technology, en: "laptop", ru: "ноутбук", tint: .navy,
                    keys: "computer компьют informatics информат it web веб remote удалённ") { art in
            art.shape(.box(6, 5.8, 20, 14.6, r: 1.8), .navy)
            art.fill(.box(8, 7.8, 16, 10.6, r: 0.8), .paper)
            art.fine(.line(9.8, 10.2, 16.4, 10.2), .red)
            art.fine(.line(11.6, 12.6, 20.6, 12.6), .blue)
            art.fine(.line(11.6, 15, 18, 15), .green)
            art.shape(.path("M3 21.6 L29 21.6 L27.4 25.2 Q27 26 26 26 L6 26 Q5 26 4.6 25.2 Z"), .steel, width: 1.4)
            art.fine(.line(13.4, 23.4, 18.6, 23.4))
        },
        SubjectIcon("lock", .technology, en: "lock", ru: "замок", tint: .gold,
                    keys: "security безопасност cryptography криптограф privacy приватн encryption шифровани password парол") { art in
            art.ink(.path("M10.2 14.6 L10.2 10.4 A5.8 5.8 0 0 1 21.8 10.4 L21.8 14.6"), .steel, width: 2.6)
            art.ink(.path("M10.2 14.6 L10.2 10.4 A5.8 5.8 0 0 1 21.8 10.4 L21.8 14.6"), width: 0.8)
            let body = EmojiFigure.box(6.8, 14, 18.4, 14.2, r: 2.6)
            art.fill(body, .gold)
            art.clip(body) { inside in
                inside.shade(.box(20.4, 0, 10, 32), opacity: 0.22)
            }
            art.ink(body, width: 1.5)
            art.fill(.path("M16 18 A1.9 1.9 0 0 1 17.3 21.3 L18 24.6 L14 24.6 L14.7 21.3 A1.9 1.9 0 0 1 16 18 Z"), .black)
        },
        SubjectIcon("gamepad", .technology, en: "gamepad", ru: "геймпад", tint: .purple,
                    keys: "games игр gamedev геймдев video game видеоигр esports киберспорт play") { art in
            let pad = EmojiFigure.path("""
            M9.6 9.6 L22.4 9.6 C26.4 9.6 28.8 13.2 29.4 18.6 C29.8 22.4 28.6 25.2 26.2 25.2 C24.2 25.2 23 22.8 21.4 21.2 \
            L10.6 21.2 C9 22.8 7.8 25.2 5.8 25.2 C3.4 25.2 2.2 22.4 2.6 18.6 C3.2 13.2 5.6 9.6 9.6 9.6 Z
            """)
            art.fill(pad, .purple)
            art.clip(pad) { inside in
                inside.shade(.box(0, 19, 32, 12), opacity: 0.2)
            }
            art.ink(pad, width: 1.5)
            art.fill(.path("M8.2 12.8 L10.2 12.8 L10.2 15 L12.4 15 L12.4 17 L10.2 17 L10.2 19.2 L8.2 19.2 L8.2 17 L6 17 L6 15 L8.2 15 Z"), .black)
            art.shape(.circle(22.2, 13.4, 1.4), .yellow, width: 0.8)
            art.shape(.circle(25.2, 16, 1.4), .red, width: 0.8)
            art.shape(.circle(19.4, 16, 1.4), .sky, width: 0.8)
            art.shape(.circle(22.2, 18.6, 1.4), .lime, width: 0.8)
        },
        SubjectIcon("smartphone", .technology, en: "smartphone", ru: "смартфон", tint: .black,
                    keys: "mobile мобильн phone телефон app приложени ios android") { art in
            art.shape(.box(8.6, 3.2, 14.8, 25.6, r: 3.4), .black)
            art.fill(.box(10.4, 6.6, 11.2, 18, r: 1.2), .sky)
            let apps: [InkPencil] = [.red, .yellow, .mint, .purple, .orange, .paper]
            for (index, pencil) in apps.enumerated() {
                let x = 11.9 + CGFloat(index % 2) * 4.6
                let y = 8.4 + CGFloat(index / 2) * 4.8
                art.shape(.box(x, y, 3.4, 3.4, r: 0.9), pencil, width: 0.8)
            }
            art.ink(.line(14.2, 4.9, 17.8, 4.9), .white, width: 0.9)
            art.ink(.line(13.8, 26.6, 18.2, 26.6), .white, width: 1.2)
        },
        SubjectIcon("server", .technology, en: "server", ru: "сервер", tint: .steel,
                    keys: "backend бэкенд hosting хостинг datacenter devops sysadmin администрировани") { art in
            for (index, y) in [CGFloat(4.4), 12.4, 20.4].enumerated() {
                art.shape(.box(4.6, y, 22.8, 7.2, r: 1.8), .steel, width: 1.4)
                art.dot(8.6, y + 3.6, 1.2, index == 1 ? .yellow : .lime)
                art.fine(.line(13.4, y + 2.5, 23.6, y + 2.4))
                art.fine(.line(13.4, y + 4.8, 23.6, y + 4.7))
            }
        },
        SubjectIcon("cloud-computing", .technology, en: "cloud computing", ru: "облачные вычисления", tint: .sky,
                    keys: "cloud облак aws azure devops deploy деплой hosting хостинг") { art in
            let cloud = EmojiFigure.path("""
            M8.6 25 C5.4 25 3.4 22.8 3.6 20.2 C3.8 17.6 5.8 16 8.2 16 C8.6 12 11.8 9.2 15.8 9.2 \
            C19.2 9.2 22 11.2 23 14.4 C26.4 14.4 28.8 17 28.6 20 C28.4 22.8 26.2 25 23.2 25 Z
            """)
            art.fill(cloud, .sky)
            art.clip(cloud) { inside in
                inside.shade(.box(0, 21.4, 32, 8), opacity: 0.22)
            }
            art.ink(cloud, width: 1.5)
            art.ink(.line(16, 23, 16, 14.6), .white, width: 2.2)
            art.ink(.line(12.4, 17.8, 16, 14.2, 19.6, 17.8), .white, width: 2.2)
        },
        SubjectIcon("bug", .technology, en: "bug", ru: "баг", tint: .green,
                    keys: "debug отладк testing тестировани qa bug ошибк") { art in
            for (y, reach) in [(CGFloat(14.6), CGFloat(-2.6)), (19, 0), (23.4, 2.6)] {
                art.ink(.line(10, y, 5, y + reach), width: 1.3)
                art.ink(.line(22, y, 27, y + reach), width: 1.3)
            }
            art.ink(.curve(14.4, 8.4, 13.2, 5.4, 10.4, 4.2), width: 1.2)
            art.ink(.curve(17.6, 8.4, 18.8, 5.4, 21.6, 4.2), width: 1.2)
            art.shape(.oval(16, 10, 4.6, 3.6), .black, width: 1.3)
            let body = EmojiFigure.oval(16, 19.4, 7.4, 9)
            art.fill(body, .lime)
            art.clip(body) { inside in
                inside.shade(.box(17.4, 0, 12, 32), opacity: 0.22)
            }
            art.ink(body)
            art.fine(.line(16, 11, 16, 28.2))
            art.dot(12.6, 16.6, 1.1)
            art.dot(19.4, 16.6, 1.1)
            art.dot(12.8, 22.4, 1.1)
            art.dot(19.2, 22.4, 1.1)
        },
        SubjectIcon("keyboard", .technology, en: "keyboard", ru: "клавиатура", tint: .steel,
                    keys: "typing печат touch typing слепая blind keys клавиш") { art in
            art.shape(.box(2.6, 8.8, 26.8, 15.4, r: 2.4), .steel)
            for row in 0..<3 {
                let keys = row == 1 ? 6 : 7
                let start: CGFloat = row == 1 ? 6.1 : 4.4
                for key in 0..<keys {
                    art.shape(.box(start + CGFloat(key) * 3.36, 11 + CGFloat(row) * 3.1, 2.6, 2.3, r: 0.5), .paper, width: 0.7)
                }
            }
            art.shape(.box(9.8, 20.3, 12.4, 2.3, r: 0.6), .paper, width: 0.7)
        },
        SubjectIcon("wifi", .technology, en: "Wi-Fi", ru: "вайфай", tint: .blue,
                    keys: "wifi internet интернет wireless беспроводн network сет") { art in
            for radius in [CGFloat(5), 10, 15] {
                art.ink(.arc(16, 24.2, radius, from: 222, to: 318), .blue, width: 2.8)
            }
            art.fill(.circle(16, 24.2, 2.2), .blue)
        },
        SubjectIcon("binary", .technology, en: "binary", ru: "двоичный код", tint: .lime,
                    keys: "bits бит bytes байт двоичн computer science информатик") { art in
            art.tile(.black)
            art.text("010", 16, 11.8, size: 9, .lime, font: .mono)
            art.text("110", 16, 20.2, size: 9, .lime, font: .mono)
        },
        SubjectIcon("vr-headset", .technology, en: "VR headset", ru: "VR-шлем", tint: .purple,
                    keys: "virtual виртуальн reality реальност ar metaverse 3d") { art in
            art.ink(.curve(7, 12, 9.6, 6, 22.4, 6, 25, 12), .graphite, width: 2.4)
            let visor = EmojiFigure.path("""
            M6 11 L26 11 C28 11 29.2 12.4 29.2 14.4 L29.2 19.6 C29.2 21.6 28 23 26 23 L20.4 23 \
            C19 23 18.4 22 17.8 21 C17.2 20 16.6 19.6 16 19.6 C15.4 19.6 14.8 20 14.2 21 \
            C13.6 22 13 23 11.6 23 L6 23 C4 23 2.8 21.6 2.8 19.6 L2.8 14.4 C2.8 12.4 4 11 6 11 Z
            """)
            art.fill(visor, .purple)
            art.clip(visor) { inside in
                inside.shade(.box(0, 19.4, 32, 8), opacity: 0.25)
            }
            art.ink(visor)
            art.ink(.curve(6.4, 14.2, 10, 13.4, 14, 13.4, 16.6, 13.8), .paper, width: 1)
            art.dot(25, 14.6, 0.9, .lime)
        },
        SubjectIcon("bitcoin", .technology, en: "Bitcoin", ru: "биткоин", tint: .orange,
                    keys: "crypto крипт blockchain блокчейн ethereum эфир") { art in
            let coin = EmojiFigure.circle(16, 16, 12.6)
            art.fill(coin, .orange)
            art.clip(coin) { inside in
                inside.shade(.path("M16 30 L30 16 L32 32 Z"), opacity: 0.22)
            }
            art.ink(coin)
            art.ink(.circle(16, 16, 10), .gold, width: 0.9)
            art.text("₿", 16.2, 16.4, size: 16, .white, font: .rounded, rotation: 12)
        },
        SubjectIcon("api", .technology, en: "API", ru: "API", tint: .purple,
                    keys: "json braces скобк rest http endpoint backend бэкенд") { art in
            let brace = EmojiFigure.path("M11.6 5.4 C8.6 5.4 8.8 8 8.8 11 C8.8 13.8 8.4 15.4 5.6 16 C8.4 16.6 8.8 18.2 8.8 21 C8.8 24 8.6 26.6 11.6 26.6")
            art.ink(brace, .purple, width: 2.6)
            art.ink(brace.mirrored(), .purple, width: 2.6)
            art.dot(12.4, 16, 1.4, .red)
            art.dot(16, 16, 1.4, .yellow)
            art.dot(19.6, 16, 1.4, .mint)
        },
    ]

    // MARK: - Platforms

    private static let platforms: [SubjectIcon] = [
        SubjectIcon("apple", .technology, en: "Apple", ru: "Apple", tint: .graphite,
                    keys: "ios macos iphone ipad mac swiftui xcode эпл") { art in
            let body = EmojiFigure.path("""
            M16 10.4 C14.3 9.3 12.3 8.9 10.5 9.3 C7.1 10.1 5.2 13.4 5.6 17.7 C6 22.5 9 27.5 12.2 27.6 \
            C13.6 27.7 14.6 26.9 16 26.9 C17.4 26.9 18.4 27.7 19.8 27.6 C22.4 27.4 24.9 24.2 26.1 20.8 \
            C23.8 19.8 22.5 17.8 22.5 15.6 C22.5 13.5 23.6 11.9 25.2 11.1 C23.8 9.3 21.6 8.8 20 9 \
            C18.4 9.2 17.2 9.9 16 10.4 Z
            """)
            let leaf = EmojiFigure.path("M16.3 8.3 C16.2 5.8 18.1 3.8 20.8 3.6 C20.9 6.1 18.9 8.2 16.3 8.3 Z")
            art.fill(body, .ink, opacity: 0.86)
            art.fill(leaf, .ink, opacity: 0.86)
            art.ink(body, width: 1.3)
            art.ink(leaf, width: 1.1)
            art.ink(.curve(9.4, 13.2, 8.4, 15.6, 8.5, 18.6), .paper, width: 1)
        },
        SubjectIcon("android", .technology, en: "Android", ru: "Android", tint: .mint,
                    keys: "андроид google kotlin mobile мобильн") { art in
            let head = EmojiFigure.path("M5.4 23 C5.4 16.6 10.2 11.8 16 11.8 C21.8 11.8 26.6 16.6 26.6 23 Z")
            art.ink(.line(10.6, 14.4, 7.8, 9.4), width: 1.5)
            art.ink(.line(21.4, 14.4, 24.2, 9.4), width: 1.5)
            art.shape(head, .mint)
            art.dot(11.4, 18.4, 1.25, .paper)
            art.dot(20.6, 18.4, 1.25, .paper)
        },
        SubjectIcon("windows", .technology, en: "Windows", ru: "Windows", tint: .sky,
                    keys: "microsoft майкрософт виндоус pc компьют") { art in
            let panes = [
                EmojiFigure.poly(4.4, 7.4, 14.6, 5.8, 14.6, 15.2, 4.4, 15.6),
                EmojiFigure.poly(16.6, 5.4, 27.6, 3.8, 27.6, 15, 16.6, 15.2),
                EmojiFigure.poly(4.4, 17.6, 14.6, 17.4, 14.6, 26.8, 4.4, 25.2),
                EmojiFigure.poly(16.6, 17.4, 27.6, 17.2, 27.6, 28.6, 16.6, 27.2),
            ]
            for pane in panes {
                art.shape(pane, .sky, width: 1.3)
            }
        },
        SubjectIcon("linux", .technology, en: "Linux", ru: "Linux", tint: .black,
                    keys: "линукс tux unix ubuntu debian open source опенсорс") { art in
            let body = EmojiFigure.path("""
            M16 3.6 C20.4 3.6 21.8 7.4 21.6 10.8 C21.4 13 22.8 14.6 24.2 16.8 C26.2 20 26.4 23.8 23.8 26 \
            L8.2 26 C5.6 23.8 5.8 20 7.8 16.8 C9.2 14.6 10.6 13 10.4 10.8 C10.2 7.4 11.6 3.6 16 3.6 Z
            """)
            art.shape(body, .black)
            art.shape(.blob(16, 12.6, 20.6, 16.4, 21.4, 21.4, 18.8, 25.6, 13.2, 25.6, 10.6, 21.4, 11.4, 16.4), .white, width: 1)
            art.shape(.oval(13.8, 8.4, 1.6, 2), .white, width: 0.8)
            art.shape(.oval(18.2, 8.4, 1.6, 2), .white, width: 0.8)
            art.dot(14.1, 8.8, 0.7)
            art.dot(17.9, 8.8, 0.7)
            art.shape(.path("M13.4 11.2 C14.8 10.2 17.2 10.2 18.6 11.2 C17.8 12.8 14.2 12.8 13.4 11.2 Z"), .yellow, width: 0.9)
            art.shape(.oval(10.6, 26.4, 3.8, 1.8, rotation: -8), .yellow, width: 1.1)
            art.shape(.oval(21.4, 26.4, 3.8, 1.8, rotation: 8), .yellow, width: 1.1)
        },
        SubjectIcon("claude", .technology, en: "Claude", ru: "Claude", tint: .terracotta,
                    keys: "anthropic ai ии нейросет llm assistant ассистент клод") { art in
            let lengths: [CGFloat] = [12.4, 10.2, 11.8, 10.6, 12.8, 9.8, 12.2, 10.8, 12.6, 10.1, 11.9, 10.7]
            let wobble: [CGFloat] = [0, 4, -3, 2, -2, 5, -4, 1, 3, -5, 2, -1]
            for index in 0..<12 {
                let angle = (CGFloat(index) * 30 - 90 + wobble[index]) * .pi / 180
                let inner: CGFloat = 1.8
                let outer = lengths[index]
                art.ink(
                    .line(16 + cos(angle) * inner, 16 + sin(angle) * inner, 16 + cos(angle) * outer, 16 + sin(angle) * outer),
                    .terracotta,
                    width: 2.9
                )
            }
            art.fill(.circle(16, 16, 2.6), .terracotta)
        },
    ]

    // MARK: - Programming languages

    private static let programmingLanguages: [SubjectIcon] = [
        SubjectIcon("python", .technology, en: "Python", ru: "Python", tint: .blue,
                    keys: "питон пайтон programming программ data данн") { art in
            let snake = EmojiFigure.path("""
            M16.2 4.2 C11.4 4.2 10.2 6.2 10.2 8.6 L10.2 11.2 L16.4 11.2 L16.4 12.4 L7.8 12.4 \
            C5.2 12.4 4.2 14.6 4.2 17.2 C4.2 20 5.3 22 7.8 22 L10 22 L10 18.9 C10 16.9 11.7 15.6 13.6 15.6 \
            L18.6 15.6 C20.4 15.6 21.8 14.3 21.8 12.5 L21.8 8.6 C21.8 6.2 20.2 4.2 16.2 4.2 Z
            """)
            art.shape(snake, .blue, width: 1.3)
            art.shape(snake.rotated(180), .yellow, width: 1.3)
            art.dot(13.2, 7.6, 1, .paper)
            art.dot(18.8, 24.4, 1, .ink)
        },
        SubjectIcon("javascript", .technology, en: "JavaScript", ru: "JavaScript", tint: .yellow,
                    keys: "js джаваскрипт web веб frontend фронтенд node") { art in
            art.tile(.yellow)
            art.text("JS", 19.6, 21, size: 12.5, .black, weight: 1)
        },
        SubjectIcon("typescript", .technology, en: "TypeScript", ru: "TypeScript", tint: .blue,
                    keys: "ts тайпскрипт web веб frontend фронтенд") { art in
            art.tile(.blue)
            art.text("TS", 19.6, 21, size: 12.5, .white, weight: 1)
        },
        SubjectIcon("nodejs", .technology, en: "Node", ru: "Node", tint: .green,
                    keys: "nodejs нод backend бэкенд javascript server сервер") { art in
            art.shape(.ngon(16, 16, 13, sides: 6, rotation: -90), .green)
            art.fill(.poly(16, 16, 27.3, 22.5, 16, 29, 4.7, 22.5), .black, opacity: 0.25)
            art.text("node", 16, 15.6, size: 7.4, .white, font: .rounded)
        },
        SubjectIcon("swift", .technology, en: "Swift", ru: "Swift", tint: .orange,
                    keys: "свифт ios apple xcode swiftui") { art in
            art.tile(.orange, corner: 6)
            art.fill(.path("""
            M7.6 20.6 C11.2 23.6 16.8 24.6 20.6 22.4 C22.4 23.6 24 24 25.2 23.8 C24.4 22.4 24.4 21 24.8 19.8 \
            C26.2 15.2 23.8 10.6 19.4 7.4 C21.6 11 22 14.6 20.6 17.6 C16.8 15.4 12.8 12.2 9.4 8.6 \
            C11.6 11.6 13.8 14.2 16.2 16.4 C13.2 15 10.2 12.8 7.6 10.6 C10.2 14.6 13.4 17.8 17.2 19.8 \
            C14 21 10.6 21.2 7.6 20.6 Z
            """), .white)
        },
        SubjectIcon("rust", .technology, en: "Rust", ru: "Rust", tint: .orange,
                    keys: "раст systems системн memory памят") { art in
            let gear = EmojiFigure.group([.gear(16, 16, outer: 13, inner: 11, teeth: 18), .circle(16, 16, 8.4)])
            art.fill(gear, .orange, evenOdd: true)
            art.ink(.gear(16, 16, outer: 13, inner: 11, teeth: 18), width: 1.2)
            art.ink(.circle(16, 16, 8.4), width: 1.2)
            art.text("R", 16.2, 16.4, size: 13, .ink, font: .serif)
        },
        SubjectIcon("c", .technology, en: "C", ru: "C", tint: .blue,
                    keys: "си systems системн embedded встраиваем low-level unix") { art in
            art.shape(.ngon(16, 16, 13, sides: 6, rotation: -90), .sky)
            art.fill(.poly(16, 16, 27.3, 22.5, 16, 29, 4.7, 22.5), .blue, opacity: 0.55)
            art.text("C", 16, 15.6, size: 14, .white, weight: 1)
        },
        SubjectIcon("cpp", .technology, en: "C++", ru: "C++", tint: .blue,
                    keys: "cpp си плюс plus olympiad олимпиад competitive спортивн") { art in
            art.shape(.ngon(16, 16, 13, sides: 6, rotation: -90), .blue)
            art.fill(.poly(16, 16, 27.3, 22.5, 16, 29, 4.7, 22.5), .navy, opacity: 0.55)
            art.text("C++", 16, 15.6, size: 9.6, .white, weight: 1)
        },
        SubjectIcon("csharp", .technology, en: "C#", ru: "C#", tint: .purple,
                    keys: "csharp шарп dotnet net unity юнити microsoft") { art in
            art.shape(.ngon(16, 16, 13, sides: 6, rotation: -90), .purple)
            art.fill(.poly(16, 16, 27.3, 22.5, 16, 29, 4.7, 22.5), .navy, opacity: 0.45)
            art.text("C#", 16, 15.6, size: 11, .white, weight: 1)
        },
        SubjectIcon("java", .technology, en: "Java", ru: "Java", tint: .red,
                    keys: "джава jvm spring android enterprise") { art in
            art.ink(.oval(15, 26.4, 10.4, 2.2), .blue, width: 1.4)
            art.ink(.path("M7 14.8 L8.2 22.2 C8.6 24 10 24.8 11.8 24.8 L18.2 24.8 C20 24.8 21.4 24 21.8 22.2 L23 14.8 Z"), .blue, width: 1.8)
            art.ink(.path("M22.8 16.4 C26.6 15.8 27.6 18.6 26.4 20.4 C25.6 21.6 24 22 22.4 21.6"), .blue, width: 1.6)
            art.ink(.curve(13.6, 12.4, 11.4, 9.6, 14.6, 7.4, 12.6, 3.6), .red, width: 1.6)
            art.ink(.curve(17.8, 12.6, 16.2, 10.4, 18.8, 8.2, 17.4, 5.4), .red, width: 1.6)
        },
        SubjectIcon("go", .technology, en: "Go", ru: "Go", tint: .teal,
                    keys: "golang го backend бэкенд google") { art in
            art.ink(.line(2.4, 13.2, 7.4, 13.2), .teal, width: 1.5)
            art.ink(.line(1.4, 16.4, 6.4, 16.4), .teal, width: 1.5)
            art.ink(.line(3, 19.6, 7, 19.6), .teal, width: 1.5)
            art.text("GO", 18.4, 16.4, size: 14.4, .teal, font: .rounded, rotation: -4)
        },
        SubjectIcon("kotlin", .technology, en: "Kotlin", ru: "Kotlin", tint: .purple,
                    keys: "котлин android андроид jvm") { art in
            let mark = EmojiFigure.poly(5, 5, 27, 5, 16, 16, 27, 27, 5, 27)
            art.fill(mark, .purple)
            art.clip(mark) { inside in
                inside.fill(.poly(5, 5, 20, 5, 5, 20), .orange)
                inside.hatch(.poly(5, 18, 20, 5, 26, 5, 5, 26), .rose, angle: -45, gap: 1.5, opacity: 0.9)
            }
            art.ink(mark, width: 1.4)
        },
        SubjectIcon("flutter", .technology, en: "Flutter", ru: "Flutter", tint: .sky,
                    keys: "флаттер dart дарт mobile мобильн google cross-platform кроссплатформ") { art in
            art.shape(.poly(18.2, 4.2, 25.4, 4.2, 11, 19.6, 7.4, 16), .sky, width: 1.3)
            art.shape(.poly(18, 15.2, 25.2, 15.2, 15.3, 25.1, 11.7, 21.5), .sky, width: 1.3)
            art.shape(.poly(15.3, 25.1, 18.9, 21.5, 25.2, 27.8, 18, 27.8), .navy, width: 1.3)
        },
        SubjectIcon("php", .technology, en: "PHP", ru: "PHP", tint: .purple,
                    keys: "пхп web веб backend бэкенд laravel wordpress site сайт") { art in
            let badge = EmojiFigure.oval(16, 16, 13.6, 8.6)
            art.fill(badge, .purple, opacity: 0.8)
            art.clip(badge) { inside in
                inside.shade(.box(0, 19.4, 32, 8), opacity: 0.22)
            }
            art.ink(badge)
            art.text("php", 16, 15.4, size: 11.4, .white, weight: 1)
        },
        SubjectIcon("ruby", .technology, en: "Ruby", ru: "Ruby", tint: .red,
                    keys: "руби rails рельс web веб backend бэкенд") { art in
            let gem = EmojiFigure.poly(8.4, 6.4, 23.6, 6.4, 28.6, 12.6, 16, 27.6, 3.4, 12.6)
            art.fill(gem, .red)
            art.clip(gem) { inside in
                inside.fill(.poly(3.4, 12.6, 11.4, 12.6, 16, 27.6), .rose, opacity: 0.55)
                inside.shade(.poly(20.6, 12.6, 28.6, 12.6, 16, 27.6), opacity: 0.25)
            }
            art.fine(.line(3.6, 12.6, 28.4, 12.6))
            art.fine(.line(8.4, 6.6, 11.4, 12.6, 16, 27.2, 20.6, 12.6, 23.6, 6.6))
            art.fine(.line(11.4, 12.6, 16, 6.6, 20.6, 12.6))
            art.ink(gem)
        },
        SubjectIcon("lua", .technology, en: "Lua", ru: "Lua", tint: .navy,
                    keys: "луа roblox роблокс scripting скрипт gamedev геймдев") { art in
            art.ink(.arc(15, 17, 14, from: 200, to: 250), .steel, width: 0.9)
            art.ink(.arc(15, 17, 14, from: 290, to: 360), .steel, width: 0.9)
            art.shape(.circle(15, 17, 10.6), .navy)
            art.shape(.circle(18.6, 13.2, 3.2), .paper, width: 1.1)
            art.shape(.circle(26.4, 5.8, 3), .navy, width: 1.2)
            art.text("Lua", 14.2, 20.2, size: 7.4, .white, font: .rounded)
        },
        SubjectIcon("haskell", .technology, en: "Haskell", ru: "Haskell", tint: .purple,
                    keys: "хаскель functional функциональн lambda лямбда") { art in
            art.shape(.poly(3, 25.2, 9.1, 16, 3, 6.8, 7.6, 6.8, 13.7, 16, 7.6, 25.2), .navy, width: 1.1)
            art.shape(.poly(9.1, 25.2, 15.2, 16, 9.1, 6.8, 13.7, 6.8, 26, 25.2, 21.4, 25.2, 17.5, 19.5, 13.7, 25.2), .purple, width: 1.1)
            art.shape(.poly(20.9, 15.2, 18.8, 12.2, 29, 12.2, 29, 15.2), .rose, width: 1)
            art.shape(.poly(23.9, 19.8, 21.9, 16.7, 29, 16.7, 29, 19.8), .rose, width: 1)
        },
        SubjectIcon("scala", .technology, en: "Scala", ru: "Scala", tint: .red,
                    keys: "скала jvm functional функциональн spark big data") { art in
            for y in [CGFloat(3.8), 11.2, 18.6] {
                art.shape(.path("M9 \(y + 3) C13 \(y + 2.2) 19 \(y + 1.2) 23 \(y) L23 \(y + 4.6) C19 \(y + 5.8) 13 \(y + 6.8) 9 \(y + 7.6) Z"), .red, width: 1.2)
            }
        },
        SubjectIcon("elixir", .technology, en: "Elixir", ru: "Elixir", tint: .purple,
                    keys: "эликсир erlang эрланг phoenix functional функциональн") { art in
            let drop = EmojiFigure.path("M16 3.4 C20 8.6 25 14.2 25 19.8 C25 25 21 28.6 16 28.6 C11 28.6 7 25 7 19.8 C7 13.4 12.6 9 16 3.4 Z")
            art.fill(drop, .purple)
            art.clip(drop) { inside in
                inside.shade(.box(17.6, 0, 12, 32), opacity: 0.22)
            }
            art.ink(drop)
            art.ink(.curve(11.2, 15, 10, 18, 10.2, 21, 11.8, 23.8), .paper, width: 1.1)
        },
        SubjectIcon("julia", .technology, en: "Julia", ru: "Julia", tint: .purple,
                    keys: "джулия scientific научн numerical численн computing вычислени") { art in
            art.shape(.circle(16, 9.4, 5.6), .green, width: 1.3)
            art.shape(.circle(9.4, 21.4, 5.6), .red, width: 1.3)
            art.shape(.circle(22.6, 21.4, 5.6), .purple, width: 1.3)
        },
        SubjectIcon("rlang", .technology, en: "R", ru: "R", tint: .blue,
                    keys: "statistics статистик rstudio data science") { art in
            let ring = EmojiFigure.group([.oval(15, 13.6, 13, 8.6), .oval(16.8, 13.2, 8.4, 5.2)])
            art.fill(ring, .steel, evenOdd: true)
            art.ink(.oval(15, 13.6, 13, 8.6), width: 1.3)
            art.ink(.oval(16.8, 13.2, 8.4, 5.2), width: 1.1)
            art.text("R", 18.6, 19.4, size: 18, .blue, font: .rounded)
        },
        SubjectIcon("react", .technology, en: "React", ru: "React", tint: .sky,
                    keys: "реакт frontend фронтенд web веб javascript") { art in
            for tilt in [CGFloat(0), 60, 120] {
                art.ink(.oval(16, 16, 13, 5, rotation: tilt), .sky, width: 1.6)
            }
            art.fill(.circle(16, 16, 2.6), .sky)
        },
        SubjectIcon("vue", .technology, en: "Vue", ru: "Vue", tint: .mint,
                    keys: "вью frontend фронтенд web веб javascript") { art in
            art.shape(.poly(2.4, 5.6, 8.2, 5.6, 16, 19.2, 23.8, 5.6, 29.6, 5.6, 16, 28.4), .mint, width: 1.3)
            art.shape(.poly(8.2, 5.6, 12.8, 5.6, 16, 11.2, 19.2, 5.6, 23.8, 5.6, 16, 19.2), .navy, width: 1.2)
        },
        SubjectIcon("html", .technology, en: "HTML", ru: "HTML", tint: .orange,
                    keys: "web веб css html5 frontend фронтенд site сайт вёрстк") { art in
            let shield = EmojiFigure.poly(5, 3.6, 27, 3.6, 25, 25.4, 16, 28.4, 7, 25.4)
            art.fill(shield, .orange)
            art.clip(shield) { inside in
                inside.fill(.box(16, 0, 16, 32), .red, opacity: 0.35)
            }
            art.ink(shield, width: 1.5)
            art.text("5", 16, 16, size: 16, .white, font: .rounded)
        },
        SubjectIcon("css", .technology, en: "CSS", ru: "CSS", tint: .blue,
                    keys: "стили styles web веб frontend фронтенд tailwind layout") { art in
            let shield = EmojiFigure.poly(5, 3.6, 27, 3.6, 25, 25.4, 16, 28.4, 7, 25.4)
            art.fill(shield, .blue)
            art.clip(shield) { inside in
                inside.fill(.box(16, 0, 16, 32), .navy, opacity: 0.35)
            }
            art.ink(shield, width: 1.5)
            art.text("3", 16, 16, size: 16, .white, font: .rounded)
        },
    ]

    // MARK: - Tools

    private static let tools: [SubjectIcon] = [
        SubjectIcon("git", .technology, en: "Git", ru: "Git", tint: .orange,
                    keys: "гит version control контроль версий github gitlab branch ветк") { art in
            art.shape(EmojiFigure.box(6.2, 6.2, 19.6, 19.6, r: 3.6).rotated(45), .orange)
            art.ink(.line(11.8, 10.4, 16.8, 15.4, 16.8, 22.4), .white, width: 1.6)
            art.ink(.line(16.8, 15.4, 21.4, 15.2), .white, width: 1.6)
            art.dot(16.8, 15.4, 1.7, .white)
            art.dot(16.8, 22.4, 1.7, .white)
            art.dot(21.8, 15.2, 1.7, .white)
        },
        SubjectIcon("github", .technology, en: "GitHub", ru: "GitHub", tint: .black,
                    keys: "гитхаб git open source опенсорс repository репозитор") { art in
            let badge = EmojiFigure.circle(16, 16, 12.8)
            art.fill(badge, .black)
            art.clip(badge) { inside in
                inside.fill(.path("""
                M12.2 28.8 L12.2 24.6 C9.6 25.2 8.4 23.8 7.8 22.6 C7.4 21.8 6.8 21.2 6.2 21 \
                C7.4 20.6 8.4 21.6 8.8 22.2 C9.6 23.4 10.8 23.4 12.2 23 C12.4 22.2 12.8 21.6 13.2 21.2 \
                C9.8 20.8 7.4 19 7.4 14.8 C7.4 13.4 7.8 12.2 8.6 11.2 C8.4 10.2 8.4 8.8 9 7.6 \
                C10.4 7.6 11.8 8.4 12.8 9.2 C14.8 8.6 17.2 8.6 19.2 9.2 C20.2 8.4 21.6 7.6 23 7.6 \
                C23.6 8.8 23.6 10.2 23.4 11.2 C24.2 12.2 24.6 13.4 24.6 14.8 C24.6 19 22.2 20.8 18.8 21.2 \
                C19.4 21.8 19.8 22.8 19.8 24 L19.8 28.8 Z
                """), .white)
            }
            art.ink(badge, width: 1.4)
        },
        SubjectIcon("docker", .technology, en: "Docker", ru: "Docker", tint: .blue,
                    keys: "докер containers контейнер devops kubernetes деплой deploy") { art in
            for (x, y) in [(8.6, 12.6), (12.8, 12.6), (17, 12.6), (12.8, 8.4), (17, 8.4), (17, 4.2), (21.2, 12.6)] as [(CGFloat, CGFloat)] {
                art.shape(.box(x, y, 3.8, 3.8, r: 0.4), .sky, width: 0.9)
            }
            let whale = EmojiFigure.path("""
            M3.4 16.8 L25.4 16.8 C26 15 27.6 14 29.4 14.6 C29.2 16 28.4 17 27.2 17.4 \
            C26 23.6 20.6 27.6 13.4 27.6 C7.4 27.6 3.8 23.2 3.4 16.8 Z
            """)
            art.fill(whale, .blue)
            art.clip(whale) { inside in
                inside.shade(.box(0, 22.6, 32, 10), opacity: 0.2)
            }
            art.ink(whale, width: 1.5)
            art.dot(9, 20.2, 0.9, .white)
        },
        SubjectIcon("figma", .technology, en: "Figma", ru: "Figma", tint: .purple,
                    keys: "фигма design дизайн ui ux interface интерфейс prototype прототип") { art in
            art.shape(.path("M16 4.6 L11.6 4.6 A4.4 4.4 0 0 0 11.6 13.4 L16 13.4 Z"), .red, width: 1.2)
            art.shape(.path("M16 4.6 L20.4 4.6 A4.4 4.4 0 0 1 20.4 13.4 L16 13.4 Z"), .rose, width: 1.2)
            art.shape(.path("M16 13.4 L11.6 13.4 A4.4 4.4 0 0 0 11.6 22.2 L16 22.2 Z"), .purple, width: 1.2)
            art.shape(.circle(20.4, 17.8, 4.4), .sky, width: 1.2)
            art.shape(.path("M16 22.2 L11.6 22.2 A4.4 4.4 0 1 0 16 26.6 Z"), .mint, width: 1.2)
        },
        SubjectIcon("vscode", .technology, en: "VS Code", ru: "VS Code", tint: .blue,
                    keys: "вскод editor редактор ide visual studio microsoft") { art in
            let outline = EmojiFigure.poly(21.6, 3.6, 28.2, 6.8, 28.2, 25.2, 21.6, 28.4, 9.4, 18, 5.2, 21.2, 3.6, 20, 3.6, 12, 5.2, 10.8, 9.4, 14)
            let arrow = EmojiFigure.poly(21.6, 10.6, 15.4, 16, 21.6, 21.4)
            let notch = EmojiFigure.poly(6, 13.6, 8.2, 16, 6, 18.4)
            let ribbon = EmojiFigure.group([outline, arrow, notch])
            art.fill(ribbon, .blue, evenOdd: true)
            art.clip(ribbon) { inside in
                inside.fill(.box(21.6, 0, 12, 32), .navy, opacity: 0.4)
            }
            art.ink(outline, width: 1.4)
            art.ink(arrow, width: 1.1)
            art.ink(notch, width: 1)
        },
        SubjectIcon("vim", .technology, en: "Vim", ru: "Vim", tint: .green,
                    keys: "вим neovim editor редактор terminal терминал") { art in
            let diamond = EmojiFigure.poly(16, 2.6, 29.4, 16, 16, 29.4, 2.6, 16)
            art.fill(diamond, .green)
            art.clip(diamond) { inside in
                inside.shade(.poly(16, 16, 32, 16, 16, 32), opacity: 0.22)
            }
            art.ink(diamond)
            art.text("V", 16, 15.6, size: 15, .white, font: .serif)
        },
        SubjectIcon("jupyter", .technology, en: "Jupyter", ru: "Jupyter", tint: .orange,
                    keys: "юпитер notebook ipynb python data science") { art in
            art.shape(.path("M4.6 12.4 C7 4.4 25 4.4 27.4 12.4 C22.8 9 9.2 9 4.6 12.4 Z"), .orange, width: 1.1)
            art.shape(.path("M4.6 19.6 C7 27.6 25 27.6 27.4 19.6 C22.8 23 9.2 23 4.6 19.6 Z"), .orange, width: 1.1)
            art.shape(.circle(26, 4.8, 1.9), .steel, width: 0.9)
            art.shape(.circle(6.2, 26.6, 2.3), .steel, width: 0.9)
            art.dot(7, 5.2, 1.1, .graphite)
        },
        SubjectIcon("kubernetes", .technology, en: "Kubernetes", ru: "Kubernetes", tint: .blue,
                    keys: "кубернетес k8s containers контейнер devops orchestration оркестрац") { art in
            art.shape(.ngon(16, 16.4, 13.4, sides: 7), .blue)
            for index in 0..<7 {
                let angle = (CGFloat(index) * 360 / 7 - 90) * .pi / 180
                art.ink(.line(16 + cos(angle) * 2.4, 16.4 + sin(angle) * 2.4, 16 + cos(angle) * 9.4, 16.4 + sin(angle) * 9.4), .white, width: 1.5)
            }
            art.ink(.circle(16, 16.4, 5.6), .white, width: 1.6)
            art.fill(.circle(16, 16.4, 2), .white)
        },
        SubjectIcon("npm", .technology, en: "npm", ru: "npm", tint: .red,
                    keys: "packages пакет node javascript registry") { art in
            art.tile(.red, corner: 2.4)
            art.text("npm", 16, 15.6, size: 9.2, .white, font: .rounded)
        },
        SubjectIcon("markdown", .technology, en: "Markdown", ru: "Markdown", tint: .graphite,
                    keys: "md маркдаун notes заметк markup разметк obsidian") { art in
            art.shape(.box(2.8, 8, 26.4, 16, r: 2.8), .paper, width: 1.6)
            art.text("M", 11.4, 16, size: 12, .ink, font: .rounded)
            art.ink(.line(22.2, 11.2, 22.2, 18.4), width: 2)
            art.fill(.poly(18.6, 16.6, 25.8, 16.6, 22.2, 21.2), .ink)
        },
        SubjectIcon("latex", .technology, en: "LaTeX", ru: "LaTeX", tint: .graphite,
                    keys: "латех tex formulas формул typesetting верстк papers статьи") { art in
            art.tile(.paper, corner: 4.5, inset: 3)
            art.text("T", 9.8, 13.8, size: 14, .ink, font: .serif)
            art.text("E", 16.2, 18, size: 14, .ink, font: .serif)
            art.text("X", 22.8, 13.8, size: 14, .ink, font: .serif)
        },
        SubjectIcon("typst", .technology, en: "Typst", ru: "Typst", tint: .teal,
                    keys: "тайпст formulas формул typesetting верстк") { art in
            art.tile(.teal, corner: 6)
            art.text("typst", 16, 15.4, size: 7.8, .white, font: .rounded)
        },
        SubjectIcon("arduino", .technology, en: "Arduino", ru: "Arduino", tint: .teal,
                    keys: "ардуино electronics электроник microcontroller микроконтроллер iot embedded встраиваем") { art in
            art.ink(.oval(10.2, 16, 6.8, 5.6), .teal, width: 3.2)
            art.ink(.oval(21.8, 16, 6.8, 5.6), .teal, width: 3.2)
            art.ink(.line(7.6, 16, 12.8, 16), .teal, width: 1.8)
            art.ink(.line(19.2, 16, 24.4, 16), .teal, width: 1.8)
            art.ink(.line(21.8, 13.4, 21.8, 18.6), .teal, width: 1.8)
        },
    ]
}
