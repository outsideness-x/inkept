import CoreGraphics

extension SubjectIcon {
    static let countries: [SubjectIcon] = flags + scripts

    private static func flag(
        _ code: String, en: String, ru: String, tint: InkPencil, keys: String,
        paint: @escaping @Sendable (inout EmojiFlag) -> Void
    ) -> SubjectIcon {
        SubjectIcon("flag-\(code)", .countries, en: en, ru: ru, tint: tint, keys: keys + " flag флаг") { art in
            art.flag(paint)
        }
    }

    // MARK: - Flags

    private static let flags: [SubjectIcon] = [
        flag("us", en: "United States", ru: "США", tint: .navy, keys: "english английск american американ usa сша америк") { flag in
            flag.stripes([.red, .white, .red, .white, .red, .white, .red])
            flag.rect(-0.05, -0.1, 0.43, 4 / 7, .navy)
            for row in 0..<3 {
                for column in 0..<4 {
                    let u = 0.07 + CGFloat(column) * 0.09 + (row == 1 ? 0.045 : 0)
                    guard u < 0.4 else { continue }
                    flag.disc(u, 0.1 + CGFloat(row) * 0.16, 0.035, .white)
                }
            }
        },
        flag("gb", en: "United Kingdom", ru: "Великобритания", tint: .navy, keys: "english английск british британ uk england англия london лондон") { flag in
            flag.unionJack()
        },
        flag("ca", en: "Canada", ru: "Канада", tint: .red, keys: "english английск french французск canadian канадск") { flag in
            flag.field(.white)
            flag.rect(-0.05, -0.1, 0.25, 1.1, .red)
            flag.rect(0.75, -0.1, 1.05, 1.1, .red)
            flag.emblem(0.5, 0.5, 0.34, .red,
                        0, -1, 0.22, -0.6, 0.48, -0.72, 0.4, -0.25, 0.85, -0.4, 0.72, -0.05, 0.95, 0.12, 0.5, 0.36,
                        0.56, 0.56, 0.08, 0.46, 0.08, 0.95, -0.08, 0.95, -0.08, 0.46, -0.56, 0.56, -0.5, 0.36,
                        -0.95, 0.12, -0.72, -0.05, -0.85, -0.4, -0.4, -0.25, -0.48, -0.72, -0.22, -0.6)
        },
        flag("au", en: "Australia", ru: "Австралия", tint: .navy, keys: "english английск australian австралийск") { flag in
            flag.field(.navy)
            flag.unionJack(in: (0, 0, 0.5, 0.5))
            flag.star(0.25, 0.76, 0.13, .white, points: 7)
            flag.star(0.76, 0.2, 0.07, .white, points: 7)
            flag.star(0.64, 0.46, 0.07, .white, points: 7)
            flag.star(0.87, 0.4, 0.07, .white, points: 7)
            flag.star(0.76, 0.82, 0.07, .white, points: 7)
            flag.star(0.81, 0.56, 0.04, .white)
        },
        flag("ie", en: "Ireland", ru: "Ирландия", tint: .green, keys: "irish ирландск english английск gaelic гэльск") { flag in
            flag.stripes([.green, .white, .orange], vertical: true)
        },
        flag("fr", en: "France", ru: "Франция", tint: .blue, keys: "french французск francais париж paris") { flag in
            flag.stripes([.blue, .white, .red], vertical: true)
        },
        flag("de", en: "Germany", ru: "Германия", tint: .yellow, keys: "german немецк deutsch дойч берлин berlin") { flag in
            flag.stripes([.black, .red, .yellow])
        },
        flag("at", en: "Austria", ru: "Австрия", tint: .red, keys: "german немецк austrian австрийск вена vienna") { flag in
            flag.stripes([.red, .white, .red])
        },
        flag("ch", en: "Switzerland", ru: "Швейцария", tint: .red, keys: "swiss швейцарск german немецк french французск") { flag in
            flag.field(.red)
            let arm: CGFloat = 0.3
            let width: CGFloat = 0.1
            flag.rect(0.5 - arm / flag.aspect, 0.5 - width, 0.5 + arm / flag.aspect, 0.5 + width, .white)
            flag.rect(0.5 - width / flag.aspect, 0.5 - arm, 0.5 + width / flag.aspect, 0.5 + arm, .white)
        },
        flag("nl", en: "Netherlands", ru: "Нидерланды", tint: .red, keys: "dutch нидерландск голландск holland голланд") { flag in
            flag.stripes([.red, .white, .blue])
        },
        flag("be", en: "Belgium", ru: "Бельгия", tint: .yellow, keys: "belgian бельгийск dutch нидерландск french французск flemish фламандск") { flag in
            flag.stripes([.black, .yellow, .red], vertical: true)
        },
        flag("es", en: "Spain", ru: "Испания", tint: .red, keys: "spanish испанск espanol español castellano кастильск") { flag in
            flag.field(.red)
            flag.rect(-0.05, 0.25, 1.05, 0.75, .yellow)
            flag.rect(0.24, 0.38, 0.34, 0.62, .red)
            flag.disc(0.29, 0.44, 0.04, .gold)
        },
        flag("mx", en: "Mexico", ru: "Мексика", tint: .green, keys: "spanish испанск mexican мексиканск") { flag in
            flag.stripes([.green, .white, .red], vertical: true)
            flag.emblem(0.5, 0.5, 0.15, .brown, -0.9, 0.2, -0.4, -0.7, 0.3, -0.9, 0.9, -0.2, 0.5, 0.5, -0.2, 0.6)
            flag.line(0.8, .green, 0.44, 0.66, 0.5, 0.7, 0.56, 0.66)
        },
        flag("ar", en: "Argentina", ru: "Аргентина", tint: .sky, keys: "spanish испанск argentine аргентинск") { flag in
            flag.stripes([.sky, .white, .sky])
            flag.star(0.5, 0.5, 0.14, .gold, points: 12)
            flag.disc(0.5, 0.5, 0.08, .yellow)
        },
        flag("it", en: "Italy", ru: "Италия", tint: .green, keys: "italian итальянск italiano рим rome") { flag in
            flag.stripes([.green, .white, .red], vertical: true)
        },
        flag("pt", en: "Portugal", ru: "Португалия", tint: .green, keys: "portuguese португальск lisbon лиссабон") { flag in
            flag.field(.red)
            flag.rect(-0.05, -0.1, 0.4, 1.1, .green)
            flag.disc(0.4, 0.5, 0.22, .yellow)
            flag.disc(0.4, 0.5, 0.15, .red)
            flag.rect(0.36, 0.42, 0.44, 0.58, .white)
        },
        flag("br", en: "Brazil", ru: "Бразилия", tint: .green, keys: "portuguese португальск brazilian бразильск") { flag in
            flag.field(.green)
            flag.poly(.yellow, 0.5, 0.1, 0.92, 0.5, 0.5, 0.9, 0.08, 0.5)
            flag.disc(0.5, 0.5, 0.25, .navy)
            flag.line(0.9, .white, 0.34, 0.5, 0.45, 0.44, 0.58, 0.44, 0.67, 0.5)
            flag.disc(0.45, 0.58, 0.025, .white)
            flag.disc(0.54, 0.62, 0.025, .white)
            flag.disc(0.58, 0.55, 0.025, .white)
        },
        flag("ru", en: "Russia", ru: "Россия", tint: .blue, keys: "russian русск россия rki рки") { flag in
            flag.stripes([.white, .blue, .red])
        },
        flag("ua", en: "Ukraine", ru: "Украина", tint: .yellow, keys: "ukrainian украинск") { flag in
            flag.stripes([.blue, .yellow])
        },
        flag("pl", en: "Poland", ru: "Польша", tint: .red, keys: "polish польск") { flag in
            flag.stripes([.white, .red])
        },
        flag("cz", en: "Czechia", ru: "Чехия", tint: .blue, keys: "czech чешск") { flag in
            flag.stripes([.white, .red])
            flag.poly(.blue, -0.05, -0.1, 0.5, 0.5, -0.05, 1.1)
        },
        flag("hu", en: "Hungary", ru: "Венгрия", tint: .green, keys: "hungarian венгерск magyar") { flag in
            flag.stripes([.red, .white, .green])
        },
        flag("ro", en: "Romania", ru: "Румыния", tint: .yellow, keys: "romanian румынск") { flag in
            flag.stripes([.blue, .yellow, .red], vertical: true)
        },
        flag("bg", en: "Bulgaria", ru: "Болгария", tint: .green, keys: "bulgarian болгарск") { flag in
            flag.stripes([.white, .green, .red])
        },
        flag("gr", en: "Greece", ru: "Греция", tint: .blue, keys: "greek греческ hellenic эллинск") { flag in
            flag.stripes([.blue, .white, .blue, .white, .blue, .white, .blue, .white, .blue])
            flag.rect(-0.05, -0.1, 0.37, 5 / 9, .blue)
            flag.rect(0.14, -0.1, 0.2, 5 / 9, .white)
            flag.rect(-0.05, 2 / 9, 0.37, 3 / 9, .white)
        },
        flag("tr", en: "Türkiye", ru: "Турция", tint: .red, keys: "turkish турецк turkey") { flag in
            flag.field(.red)
            flag.disc(0.37, 0.5, 0.25, .white)
            flag.disc(0.42, 0.5, 0.2, .red)
            flag.star(0.57, 0.5, 0.11, .white, rotation: 180)
        },
        flag("se", en: "Sweden", ru: "Швеция", tint: .blue, keys: "swedish шведск svenska") { flag in
            flag.field(.blue)
            flag.cross(0.375, 0.5, 0.2, .yellow)
        },
        flag("no", en: "Norway", ru: "Норвегия", tint: .red, keys: "norwegian норвежск norsk") { flag in
            flag.field(.red)
            flag.cross(0.36, 0.5, 0.28, .white)
            flag.cross(0.36, 0.5, 0.14, .navy)
        },
        flag("fi", en: "Finland", ru: "Финляндия", tint: .blue, keys: "finnish финск suomi") { flag in
            flag.field(.white)
            flag.cross(0.36, 0.5, 0.26, .blue)
        },
        flag("dk", en: "Denmark", ru: "Дания", tint: .red, keys: "danish датск dansk") { flag in
            flag.field(.red)
            flag.cross(0.36, 0.5, 0.2, .white)
        },
        flag("cn", en: "China", ru: "Китай", tint: .red, keys: "chinese китайск mandarin мандарин putonghua путунхуа hsk") { flag in
            flag.field(.red)
            flag.star(0.17, 0.27, 0.17, .yellow)
            flag.star(0.34, 0.1, 0.055, .yellow, rotation: -60)
            flag.star(0.41, 0.2, 0.055, .yellow, rotation: -80)
            flag.star(0.41, 0.34, 0.055, .yellow, rotation: -100)
            flag.star(0.34, 0.44, 0.055, .yellow, rotation: -120)
        },
        flag("jp", en: "Japan", ru: "Япония", tint: .red, keys: "japanese японск nihongo нихонго jlpt") { flag in
            flag.field(.white)
            flag.disc(0.5, 0.5, 0.3, .red)
        },
        flag("kr", en: "South Korea", ru: "Южная Корея", tint: .blue, keys: "korean корейск hangul хангыль корея topik") { flag in
            flag.field(.white)
            let radius: CGFloat = 0.25
            let tilt: CGFloat = 33.7 * .pi / 180
            let aspect = flag.aspect
            func place(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                // Around the centre in heights, turned with the flag's tilt.
                let rx = x * cos(tilt) - y * sin(tilt)
                let ry = x * sin(tilt) + y * cos(tilt)
                return CGPoint(x: 0.5 + rx / aspect, y: 0.5 + ry)
            }
            flag.disc(0.5, 0.5, radius, .blue)
            // Red over the top, back round the blue's bulge on the fly side and down into its own on the hoist side.
            var red: [CGPoint] = []
            for step in 0...24 {
                let angle = CGFloat.pi + CGFloat.pi * CGFloat(step) / 24
                red.append(place(cos(angle) * radius, sin(angle) * radius))
            }
            for step in 1...12 {
                let angle = -CGFloat.pi * CGFloat(step) / 12
                red.append(place(radius / 2 + cos(angle) * radius / 2, sin(angle) * radius / 2))
            }
            for step in 1...12 {
                let angle = CGFloat.pi * CGFloat(step) / 12
                red.append(place(-radius / 2 + cos(angle) * radius / 2, sin(angle) * radius / 2))
            }
            flag.paint(.fill(flag.figure(red), .red, opacity: 1, evenOdd: false))
            let trigrams: [(CGFloat, CGFloat, [Bool])] = [
                (-1, -1, [false, false, false]),
                (1, 1, [true, true, true]),
                (1, -1, [true, false, true]),
                (-1, 1, [false, true, false]),
            ]
            for (sx, sy, broken) in trigrams {
                let length = hypot(sx * aspect, sy)
                let direction = CGPoint(x: sx * aspect / length, y: sy / length)
                let across = CGPoint(x: -direction.y, y: direction.x)
                for (index, isBroken) in broken.enumerated() {
                    let distance = 0.396 + CGFloat(index) * 0.0625
                    func end(_ t: CGFloat) -> CGPoint {
                        CGPoint(
                            x: 0.5 + (direction.x * distance + across.x * t) / aspect,
                            y: 0.5 + direction.y * distance + across.y * t
                        )
                    }
                    let pieces: [(CGFloat, CGFloat)] = isBroken ? [(-0.12, -0.025), (0.025, 0.12)] : [(-0.12, 0.12)]
                    for (from, to) in pieces {
                        flag.paint(.ink(flag.figure([end(from), end(to)], closed: false), .black, width: 0.85, opacity: 1))
                    }
                }
            }
        },
        flag("vn", en: "Vietnam", ru: "Вьетнам", tint: .red, keys: "vietnamese вьетнамск") { flag in
            flag.field(.red)
            flag.star(0.5, 0.52, 0.3, .yellow)
        },
        flag("th", en: "Thailand", ru: "Таиланд", tint: .navy, keys: "thai тайск") { flag in
            flag.field(.red)
            flag.rect(-0.05, 1 / 6, 1.05, 5 / 6, .white)
            flag.rect(-0.05, 2 / 6, 1.05, 4 / 6, .navy)
        },
        flag("id", en: "Indonesia", ru: "Индонезия", tint: .red, keys: "indonesian индонезийск malay малайск") { flag in
            flag.stripes([.red, .white])
        },
        flag("in", en: "India", ru: "Индия", tint: .orange, keys: "hindi хинди indian индийск") { flag in
            flag.stripes([.orange, .white, .green])
            flag.paint(.ink(flag.circle(0.5, 0.5, 0.13), .navy, width: 0.8, opacity: 1))
            for spoke in 0..<8 {
                let angle = CGFloat(spoke) * .pi / 8
                let dx = cos(angle) * 0.12 / flag.aspect
                let dy = sin(angle) * 0.12
                flag.line(0.4, .navy, 0.5 - dx, 0.5 - dy, 0.5 + dx, 0.5 + dy)
            }
        },
        flag("il", en: "Israel", ru: "Израиль", tint: .blue, keys: "hebrew иврит israeli израильск") { flag in
            flag.field(.white)
            flag.rect(-0.05, 0.1, 1.05, 0.22, .blue)
            flag.rect(-0.05, 0.78, 1.05, 0.9, .blue)
            for rotation in [CGFloat(-90), 90] {
                let points = (0..<3).map { index -> CGPoint in
                    let angle = (rotation + CGFloat(index) * 120) * .pi / 180
                    return CGPoint(x: 0.5 + cos(angle) * 0.2 / flag.aspect, y: 0.5 + sin(angle) * 0.2)
                }
                flag.paint(.ink(flag.figure(points), .blue, width: 0.9, opacity: 1))
            }
        },
        flag("ae", en: "United Arab Emirates", ru: "ОАЭ", tint: .green, keys: "arabic арабск emirates эмират dubai дубай") { flag in
            flag.stripes([.green, .white, .black])
            flag.rect(-0.05, -0.1, 0.25, 1.1, .red)
        },
        flag("kz", en: "Kazakhstan", ru: "Казахстан", tint: .sky, keys: "kazakh казахск") { flag in
            flag.field(.sky)
            flag.star(0.5, 0.4, 0.2, .yellow, points: 16)
            flag.disc(0.5, 0.4, 0.12, .yellow)
            flag.emblem(0.5, 0.68, 0.2, .yellow, -1, 0, -0.3, -0.25, 0, 0.1, 0.3, -0.25, 1, 0, 0.3, 0.15, 0, 0.35, -0.3, 0.15)
            flag.rect(0.06, -0.1, 0.1, 1.1, .yellow)
        },
        flag("ge", en: "Georgia", ru: "Грузия", tint: .red, keys: "georgian грузинск kartuli") { flag in
            flag.field(.white)
            flag.cross(0.5, 0.5, 0.2, .red)
            for (u, v) in [(0.22, 0.24), (0.78, 0.24), (0.22, 0.76), (0.78, 0.76)] as [(CGFloat, CGFloat)] {
                flag.rect(u - 0.018, v - 0.13, u + 0.018, v + 0.13, .red)
                flag.rect(u - 0.085, v - 0.045, u + 0.085, v + 0.045, .red)
            }
        },
        flag("am", en: "Armenia", ru: "Армения", tint: .orange, keys: "armenian армянск") { flag in
            flag.stripes([.red, .blue, .orange])
        },
        flag("eu", en: "European Union", ru: "Евросоюз", tint: .blue, keys: "europe европ european европейск eu ес") { flag in
            flag.field(.blue)
            for index in 0..<12 {
                let angle = CGFloat(index) / 12 * 2 * .pi
                flag.star(0.5 + cos(angle) * 0.3 / flag.aspect, 0.5 + sin(angle) * 0.3, 0.06, .yellow)
            }
        },
        flag("eo", en: "Esperanto", ru: "эсперанто", tint: .green, keys: "esperanto эсперанто constructed искусствен") { flag in
            flag.field(.green)
            flag.rect(-0.05, -0.1, 0.5 / flag.aspect, 0.5, .white)
            flag.star(0.25 / flag.aspect, 0.25, 0.17, .green)
        },
    ]

    // MARK: - Scripts

    private static func script(_ id: String, _ letters: String, en: String, ru: String, keys: String) -> SubjectIcon {
        SubjectIcon("script-\(id)", .countries, en: en, ru: ru, tint: .red, keys: keys) { art in
            art.tile(.paper, corner: 4.5, inset: 4.2)
            art.ink(.line(5.2, 10, 26.8, 9.8), .red, width: 0.8, opacity: 0.8)
            art.text(letters, 16, 18.4, size: 13, .ink, weight: 0.6)
        }
    }

    private static let scripts: [SubjectIcon] = [
        script("latin", "Aa", en: "Latin alphabet", ru: "латиница", keys: "alphabet алфавит latin латынь латинск letters буквы"),
        script("cyrillic", "Жж", en: "Cyrillic", ru: "кириллица", keys: "russian русск alphabet алфавит cyrillic кириллиц"),
        script("greek", "αβ", en: "Greek alphabet", ru: "греческий алфавит", keys: "greek греческ alphabet алфавит ancient древн"),
        script("han", "文", en: "Chinese characters", ru: "иероглифы", keys: "chinese китайск hanzi ханьцзы kanji кандзи characters иероглиф"),
        script("kana", "あ", en: "kana", ru: "кана", keys: "japanese японск hiragana хирагана katakana катакана"),
        script("hangul", "한", en: "Hangul", ru: "хангыль", keys: "korean корейск hangul хангыл"),
        script("arabic", "ع", en: "Arabic script", ru: "арабское письмо", keys: "arabic арабск persian персидск farsi фарси urdu урду"),
        script("hebrew", "א", en: "Hebrew", ru: "иврит", keys: "hebrew иврит yiddish идиш"),
        script("devanagari", "अ", en: "Devanagari", ru: "деванагари", keys: "hindi хинди sanskrit санскрит devanagari деванагари"),
    ]
}
