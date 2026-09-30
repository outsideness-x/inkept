import CoreGraphics

extension SubjectIcon {
    static let things: [SubjectIcon] = marks + study + life + nature + animals

    // MARK: - Marks

    private static let marks: [SubjectIcon] = [
        SubjectIcon("star", .things, en: "star", ru: "звезда", tint: .yellow,
                    keys: "favorite избранн important важн best лучш") { art in
            let star = EmojiFigure.star(16, 16.8, 12.6, inner: 5.6)
            art.fill(star, .yellow)
            art.clip(star) { inside in
                inside.shade(.path("M16 16.8 L30 12 L30 32 L16 32 Z"), opacity: 0.22)
            }
            art.ink(star)
        },
        SubjectIcon("heart", .things, en: "heart", ru: "сердце", tint: .red,
                    keys: "love любов favorite любим health здоров") { art in
            let heart = EmojiFigure.path("M16 27.4 C10.4 23 4.4 18.6 4.4 12.2 C4.4 8.4 7.2 5.6 10.6 5.6 C13 5.6 14.8 7 16 9.2 C17.2 7 19 5.6 21.4 5.6 C24.8 5.6 27.6 8.4 27.6 12.2 C27.6 18.6 21.6 23 16 27.4 Z")
            art.shape(heart, .red)
            art.ink(.curve(8, 10.6, 9.2, 8.6, 11.4, 8.4), .paper, width: 1.1)
        },
        SubjectIcon("fire", .things, en: "fire", ru: "огонь", tint: .orange,
                    keys: "streak серия motivation мотивац hot горяч energy энерги") { art in
            let flame = EmojiFigure.path("""
            M16 28.4 C10 28.4 6.4 24.2 6.8 19 C7.2 14.4 10.4 12.2 11.2 8.6 C13.2 10.6 13.8 12.6 13.6 14.6 \
            C15.4 12.2 16.4 7.8 15.4 3.4 C20.8 6.4 25.6 12.4 25.4 19.4 C25.2 24.6 21.8 28.4 16 28.4 Z
            """)
            art.fill(flame, .orange)
            art.fill(.path("M16 28.2 C12.8 28.2 11 25.8 11.4 22.8 C11.8 20.4 13.6 19 14.4 16.8 C15.6 18.2 16 19.6 15.8 20.8 C17 20 18 18.4 18 16.4 C20.4 18.4 21.6 21.4 21 24 C20.4 26.6 18.6 28.2 16 28.2 Z"), .yellow)
            art.ink(flame, width: 1.5)
        },
        SubjectIcon("flag-pride", .things, en: "pride flag", ru: "прайд-флаг", tint: .purple,
                    keys: "lgbt лгбт pride прайд rainbow радуг queer квир") { art in
            art.flag { flag in
                flag.stripes([.red, .orange, .yellow, .green, .blue, .purple])
            }
        },
        SubjectIcon("sparkles", .things, en: "sparkles", ru: "искры", tint: .yellow,
                    keys: "magic магия new нов shine блеск idea иде") { art in
            art.shape(.star(13, 17.4, 10, inner: 2.8, points: 4), .yellow, width: 1.4)
            art.shape(.star(24.2, 8, 5, inner: 1.5, points: 4), .yellow, width: 1.1)
            art.shape(.star(25, 23.4, 3.6, inner: 1.1, points: 4), .yellow, width: 1)
        },
        SubjectIcon("lightbulb", .things, en: "light bulb", ru: "лампочка", tint: .yellow,
                    keys: "idea иде creativity креатив philosophy философ invention изобретен insight озарени") { art in
            let bulb = EmojiFigure.path("""
            M16 3.6 C10.8 3.6 7.4 7.6 7.4 12 C7.4 15.4 9.4 17.2 10.8 19 C11.6 20 12 21 12 22.4 L20 22.4 \
            C20 21 20.4 20 21.2 19 C22.6 17.2 24.6 15.4 24.6 12 C24.6 7.6 21.2 3.6 16 3.6 Z
            """)
            art.fill(bulb, .yellow)
            art.clip(bulb) { inside in
                inside.shade(.box(19.4, 0, 10, 32), opacity: 0.2)
            }
            art.ink(bulb, width: 1.5)
            art.fine(.curve(13.4, 22.2, 13.2, 17.4, 14.6, 15.2, 16, 17, 17.4, 15.2, 18.8, 17.4, 18.6, 22.2), .brown)
            art.shape(.box(12, 22.4, 8, 4.4, r: 1), .steel, width: 1.2)
            art.fine(.line(12.2, 24, 19.8, 24))
            art.fine(.line(12.2, 25.4, 19.8, 25.4))
            art.shape(.path("M13.8 26.8 L18.2 26.8 C18 28.2 17.2 28.8 16 28.8 C14.8 28.8 14 28.2 13.8 26.8 Z"), .black, width: 0.9)
            art.ink(.arc(15.6, 11.6, 5, from: 195, to: 250), .paper, width: 1)
        },
        SubjectIcon("target", .things, en: "target", ru: "мишень", tint: .red,
                    keys: "goal цель focus фокус aim задач objective plan план") { art in
            art.shape(.circle(14.6, 17.4, 11.4), .red, width: 1.5)
            art.shape(.circle(14.6, 17.4, 8), .paper, width: 1.1)
            art.shape(.circle(14.6, 17.4, 4.8), .red, width: 1.1)
            art.fill(.circle(14.6, 17.4, 1.8), .paper)
            art.ink(.line(14.8, 17.2, 27.4, 4.6), width: 1.6)
            art.shape(.poly(27.4, 4.6, 24.4, 3.8, 23.6, 5.8, 26.2, 7.8, 28.2, 7), .yellow, width: 1)
        },
    ]

    // MARK: - Studying

    private static let study: [SubjectIcon] = [
        SubjectIcon("grad-cap", .things, en: "graduation cap", ru: "шапочка выпускника", tint: .black,
                    keys: "university университет education образован exam экзамен graduation выпуск school школ college колледж") { art in
            art.shape(.path("M8.6 14.2 L8.6 20.4 C8.6 22.8 12 24.6 16 24.6 C20 24.6 23.4 22.8 23.4 20.4 L23.4 14.2 L16 17.4 Z"), .black, width: 1.4)
            art.shape(.poly(16, 5.4, 29.6, 11.4, 16, 17.4, 2.4, 11.4), .black, width: 1.5)
            art.ink(.line(16, 11.4, 24.6, 13.8, 24.6, 20.4), .yellow, width: 1.2)
            art.shape(.path("M23.4 20.4 L25.8 20.4 L26.6 25 L22.6 25 Z"), .yellow, width: 0.9)
            art.dot(16, 11.4, 1.1, .yellow)
        },
        SubjectIcon("books", .things, en: "books", ru: "книги", tint: .blue,
                    keys: "reading чтени library библиотек study учёб revision повторени textbook учебник homework домашн") { art in
            let books: [(CGRect, CGFloat, InkPencil)] = [
                (CGRect(x: 4, y: 21.4, width: 24, height: 5.8), 0, .blue),
                (CGRect(x: 5.6, y: 15.6, width: 21.6, height: 5.8), -3, .red),
                (CGRect(x: 4.8, y: 9.4, width: 20.4, height: 5.8), 4, .green),
            ]
            for (rect, tilt, pencil) in books {
                let center = CGPoint(x: rect.midX, y: rect.midY)
                let cover = EmojiFigure.box(rect.minX, rect.minY, rect.width, rect.height, r: 1).rotated(tilt, around: center.x, center.y)
                art.fill(cover, pencil)
                art.fill(EmojiFigure.box(rect.maxX - 3.4, rect.minY + 1, 2.6, rect.height - 2).rotated(tilt, around: center.x, center.y), .paper)
                art.ink(cover, width: 1.3)
                art.fine(EmojiFigure.line(rect.minX + 3.2, rect.minY + 0.6, rect.minX + 3.2, rect.maxY - 0.6).rotated(tilt, around: center.x, center.y), .paper)
                art.fine(EmojiFigure.line(rect.maxX - 3.4, rect.minY + 1, rect.maxX - 3.4, rect.maxY - 1).rotated(tilt, around: center.x, center.y))
            }
        },
        SubjectIcon("notebook", .things, en: "notebook", ru: "тетрадь", tint: .red,
                    keys: "notes конспект заметк writing письм journal дневник lecture лекци school школ") { art in
            let cover = EmojiFigure.box(7.4, 4, 18.6, 24.4, r: 2.2)
            art.fill(cover, .red)
            art.clip(cover) { inside in
                inside.shade(.box(21, 0, 10, 32), opacity: 0.2)
            }
            art.ink(cover, width: 1.5)
            art.shape(.box(12.4, 9, 10.2, 6.4, r: 0.8), .paper, width: 1)
            art.fine(.line(14, 11.4, 21, 11.4), .graphite)
            art.fine(.line(14, 13.2, 19.4, 13.2), .graphite)
            for index in 0..<5 {
                let y = 7 + CGFloat(index) * 4.6
                art.ink(.oval(7.4, y, 2.2, 1.1), width: 1)
            }
        },
        SubjectIcon("pencil", .things, en: "pencil", ru: "карандаш", tint: .yellow,
                    keys: "drawing рисован writing письм homework домашн sketch эскиз design дизайн") { art in
            let tilt: CGFloat = -42
            func turned(_ figure: EmojiFigure) -> EmojiFigure { figure.rotated(tilt) }
            art.shape(turned(.poly(9.4, 13.4, 9.4, 18.6, 3.6, 16)), .tan, width: 1.2)
            art.fill(turned(.poly(5, 15.2, 5, 16.8, 3.2, 16)), .ink)
            art.shape(turned(.box(9.4, 13.4, 13.6, 5.2)), .yellow, width: 1.3)
            art.fine(turned(.line(9.6, 16, 22.8, 16)), .gold)
            art.shape(turned(.box(23, 13.4, 2.8, 5.2)), .steel, width: 1.1)
            art.shape(turned(.box(25.8, 13.4, 3.4, 5.2, r: 1.4)), .rose, width: 1.2)
        },
        SubjectIcon("backpack", .things, en: "backpack", ru: "рюкзак", tint: .red,
                    keys: "school школ student студент travel путешеств lessons уроки") { art in
            art.ink(.path("M13 5.6 C13 3.4 19 3.4 19 5.6"), width: 1.5)
            let bag = EmojiFigure.path("M8 11 C8 7.4 11 5.2 16 5.2 C21 5.2 24 7.4 24 11 L24 26 C24 27.4 23 28.4 21.6 28.4 L10.4 28.4 C9 28.4 8 27.4 8 26 Z")
            art.fill(bag, .red)
            art.clip(bag) { inside in
                inside.shade(.box(20.4, 0, 10, 32), opacity: 0.2)
            }
            art.ink(bag, width: 1.5)
            art.fine(.curve(8.2, 13.4, 12, 14.8, 20, 14.8, 23.8, 13.4))
            art.shape(.box(10.6, 18.4, 10.8, 7.6, r: 2), .red, width: 1.2)
            art.fine(.line(11.6, 20.6, 20.4, 20.6))
            art.shape(.box(19, 19.8, 1.6, 2.4, r: 0.4), .gold, width: 0.7)
        },
        SubjectIcon("calendar", .things, en: "calendar", ru: "календарь", tint: .red,
                    keys: "schedule расписан planning планирован exams экзамен dates даты deadline дедлайн") { art in
            let page = EmojiFigure.box(5, 6.4, 22, 21.8, r: 2.6)
            art.fill(page, .paper)
            art.clip(page) { inside in
                inside.fill(.box(0, 0, 32, 11.6), .red)
            }
            art.ink(page, width: 1.5)
            art.fine(.line(5.2, 11.6, 26.8, 11.6))
            art.ink(.line(11, 3.8, 11, 8.6), width: 1.8)
            art.ink(.line(21, 3.8, 21, 8.6), width: 1.8)
            art.text("17", 16, 20.2, size: 11, .ink, weight: 0.8)
        },
        SubjectIcon("alarm-clock", .things, en: "alarm clock", ru: "будильник", tint: .red,
                    keys: "time время deadline дедлайн routine режим productivity продуктивност morning утро") { art in
            art.shape(.path("M4.2 10.6 C3.6 6.8 6.8 4 10.2 5.2 Z"), .red, width: 1.2)
            art.shape(.path("M27.8 10.6 C28.4 6.8 25.2 4 21.8 5.2 Z"), .red, width: 1.2)
            art.ink(.line(9.6, 26.2, 7.6, 28.8), width: 1.6)
            art.ink(.line(22.4, 26.2, 24.4, 28.8), width: 1.6)
            art.shape(.circle(16, 17.2, 10.4), .red, width: 1.5)
            art.shape(.circle(16, 17.2, 7.6), .paper, width: 1.1)
            art.ink(.line(16, 17.2, 16, 12), width: 1.4)
            art.ink(.line(16, 17.2, 19.8, 19.2), width: 1.4)
            art.dot(16, 17.2, 0.9)
        },
        SubjectIcon("pin", .things, en: "pushpin", ru: "булавка", tint: .red,
                    keys: "important важн pinned закреп reminder напоминани note заметк") { art in
            art.ink(.line(15.4, 16.6, 6.2, 26.6), .steel, width: 1.6)
            art.shape(.path("M14.2 12.6 L19.4 17.8 L16.8 19.8 L12.2 15.2 Z"), .red, width: 1.2)
            art.shape(.circle(19.6, 11, 6.4), .red, width: 1.5)
            art.ink(.arc(18.4, 9.8, 3.2, from: 190, to: 260), .paper, width: 1)
        },
        SubjectIcon("magnifier", .things, en: "magnifier", ru: "лупа", tint: .sky,
                    keys: "research исследован search поиск investigation расследован science наук") { art in
            art.shape(EmojiFigure.box(17.6, 21.2, 12, 4.4, r: 2).rotated(45, around: 23.6, 23.4), .brown, width: 1.4)
            let lens = EmojiFigure.circle(13.2, 13.2, 8.6)
            art.fill(lens, .sky, opacity: 0.55)
            art.clip(lens) { inside in
                inside.hatch(.box(0, 0, 32, 32), .sky, angle: -50, gap: 1.8)
            }
            art.ink(lens, .steel, width: 2.8)
            art.ink(lens, width: 1)
            art.ink(.arc(12.4, 12.4, 5, from: 195, to: 255), .paper, width: 1.1)
        },
        SubjectIcon("puzzle", .things, en: "puzzle", ru: "пазл", tint: .lime,
                    keys: "logic логик problem задач solving решени olympiad олимпиад brain teaser головоломк") { art in
            let piece = EmojiFigure.path("""
            M7 9.6 L12.4 9.6 C11.6 8.4 11.4 7.8 11.4 7 C11.4 5.2 12.8 3.8 14.8 3.8 C16.8 3.8 18.2 5.2 18.2 7 \
            C18.2 7.8 18 8.4 17.2 9.6 L22.6 9.6 L22.6 15 C23.8 14.2 24.4 14 25.2 14 C27 14 28.4 15.4 28.4 17.4 \
            C28.4 19.4 27 20.8 25.2 20.8 C24.4 20.8 23.8 20.6 22.6 19.8 L22.6 25.6 L7 25.6 L7 19.8 \
            C8.2 20.6 8.8 20.8 9.6 20.8 C11.4 20.8 12.8 19.4 12.8 17.4 C12.8 15.4 11.4 14 9.6 14 \
            C8.8 14 8.2 14.2 7 15 Z
            """)
            art.fill(piece, .lime)
            art.clip(piece) { inside in
                inside.shade(.box(0, 21, 32, 10), opacity: 0.2)
            }
            art.ink(piece, width: 1.5)
        },
        SubjectIcon("chess", .things, en: "chess", ru: "шахматы", tint: .black,
                    keys: "chess шахмат strategy стратеги logic логик game игр theory теори") { art in
            let knight = EmojiFigure.path("""
            M10.4 25.2 C10.2 23.8 10.4 22.6 11 21.6 C12.6 19.6 14.6 17.4 14.8 14.8 C14 15.6 12.8 16.2 11.6 16.4 \
            C10.8 17.2 9.8 18 8.6 17.8 C7.2 17.6 6.6 16.2 7.2 15 L9.2 11.2 C10.2 8.8 12 6.8 14.2 5.9 \
            L15.2 3.4 L16.4 5.4 C18.4 4.8 20.8 5.2 22.6 6.6 C24.8 8.4 25.2 11.4 24 13.8 C22.6 16.6 21.6 19.6 21.8 23.6 \
            L22.4 25.2 Z
            """)
            art.shape(knight, .black)
            art.dot(13.6, 9.8, 0.9, .white)
            art.fine(.curve(18, 6.6, 20.6, 8.2, 21.8, 11), .white)
            art.shape(.box(7.4, 25, 17.2, 3.4, r: 1), .black, width: 1.4)
        },
    ]

    // MARK: - Everyday life

    private static let life: [SubjectIcon] = [
        SubjectIcon("coffee", .things, en: "coffee", ru: "кофе", tint: .brown,
                    keys: "cup чашк break перерыв cafe кафе tea чай morning утро") { art in
            art.shape(.oval(15, 26.2, 11, 2.4), .paper, width: 1.2)
            let cup = EmojiFigure.path("M6.2 13 L7.6 22.4 C8 24.6 9.8 25.8 12 25.8 L18 25.8 C20.2 25.8 22 24.6 22.4 22.4 L23.8 13 Z")
            art.shape(.path("M23.4 15 C27.6 14.4 28.8 17.2 27.6 19.4 C26.6 21.2 24.4 21.6 22.4 21.2"), .paper, width: 1.4)
            art.fill(cup, .paper)
            art.clip(cup) { inside in
                inside.fill(.box(0, 18.6, 32, 14), .red)
                inside.shade(.box(17.5, 12, 8, 16), opacity: 0.22)
            }
            art.ink(cup)
            art.shape(.oval(15, 13, 8.8, 1.9), .brown, width: 1.2)
            art.fine(.curve(11.4, 10.2, 10.2, 8.2, 11.8, 6.4, 10.8, 4.2), .graphite)
            art.fine(.curve(15.4, 10.4, 14.2, 8.2, 15.8, 6.2, 14.8, 3.6), .graphite)
            art.fine(.curve(19.4, 10.2, 18.2, 8.2, 19.8, 6.4, 18.8, 4.4), .graphite)
        },
        SubjectIcon("cooking", .things, en: "cooking", ru: "кулинария", tint: .yellow,
                    keys: "cooking готовк kitchen кухн food еда recipes рецепт chef повар") { art in
            art.shape(.box(21.6, 14.6, 9.4, 3, r: 1.3), .brown, width: 1.3)
            art.shape(.circle(13, 16.2, 10.4), .black, width: 1.5)
            art.fine(.circle(13, 16.2, 8.4), .steel)
            art.shape(.blob(8.2, 13.4, 11.4, 9.8, 15.6, 10.6, 18.4, 13.6, 17.8, 18.8, 14, 21.8, 9.4, 20.6, 7.4, 17.4), .white, width: 1.1)
            art.shape(.circle(13, 15.8, 3), .yellow, width: 1.1)
            art.ink(.arc(12.4, 15.2, 1.4, from: 190, to: 260), .paper, width: 0.8)
        },
        SubjectIcon("headphones", .things, en: "headphones", ru: "наушники", tint: .red,
                    keys: "listening аудировани music музык podcast подкаст audio аудио") { art in
            art.ink(.path("M6.2 19.6 C6.2 10.6 10.4 5.4 16 5.4 C21.6 5.4 25.8 10.6 25.8 19.6"), width: 2.4)
            art.shape(.box(3.4, 16.6, 6.6, 10.6, r: 2.8), .red)
            art.shape(.box(22, 16.6, 6.6, 10.6, r: 2.8), .red)
            art.fine(.line(8.4, 18.4, 8.4, 25.4), .paper)
            art.fine(.line(23.6, 18.4, 23.6, 25.4), .paper)
        },
        SubjectIcon("ball", .things, en: "ball", ru: "мяч", tint: .black,
                    keys: "sport спорт football футбол soccer physical физкультур pe fitness игр") { art in
            let ball = EmojiFigure.circle(16, 16, 11.6)
            art.fill(ball, .white)
            art.clip(ball) { inside in
                inside.fill(.ngon(16, 16, 4.4, sides: 5), .black)
                for index in 0..<5 {
                    let angle = (-90 + 36 + CGFloat(index) * 72) * .pi / 180
                    inside.fill(.ngon(16 + cos(angle) * 11.8, 16 + sin(angle) * 11.8, 4.4, sides: 5, rotation: -90 + 36 + CGFloat(index) * 72 + 180), .black)
                    let from = CGPoint(x: 16 + cos(angle) * 3.6, y: 16 + sin(angle) * 3.6)
                    let to = CGPoint(x: 16 + cos(angle) * 8.4, y: 16 + sin(angle) * 8.4)
                    inside.fine(.line(from.x, from.y, to.x, to.y))
                }
                inside.shade(.path("M20 3 A 13 13 0 0 1 20 29 L32 29 L32 3 Z"), opacity: 0.2)
            }
            art.ink(ball, width: 1.5)
        },
        SubjectIcon("dumbbell", .things, en: "dumbbell", ru: "гантель", tint: .steel,
                    keys: "fitness фитнес gym спортзал sport спорт training тренировк health здоров") { art in
            let tilt: CGFloat = -20
            art.shape(EmojiFigure.box(8, 14.6, 16, 2.8, r: 0.8).rotated(tilt), .steel, width: 1.3)
            for x in [CGFloat(4.4), 23.6] {
                art.shape(EmojiFigure.box(x, 8.6, 4, 14.8, r: 1.2).rotated(tilt), .black, width: 1.4)
            }
            for x in [CGFloat(2), 27.6] {
                art.shape(EmojiFigure.box(x, 11, 2.4, 10, r: 1).rotated(tilt), .black, width: 1.2)
            }
        },
        SubjectIcon("car", .things, en: "car", ru: "машина", tint: .red,
                    keys: "driving вождени пдд traffic rules правила дорожн license права автошкол") { art in
            let body = EmojiFigure.path("""
            M3.6 22.4 L3.6 18.4 C3.6 16.8 4.8 15.8 6.4 15.6 L9.4 15.2 L12.4 10.6 C13 9.8 13.8 9.4 14.8 9.4 \
            L21.4 9.4 C22.4 9.4 23.2 9.8 23.8 10.6 L26.6 15 C28 15.4 28.6 16.4 28.6 17.8 L28.6 22.4 Z
            """)
            art.fill(body, .red)
            art.clip(body) { inside in
                inside.shade(.box(0, 19.4, 32, 6), opacity: 0.22)
            }
            art.ink(body, width: 1.5)
            art.shape(.poly(12.6, 15, 14.6, 11.4, 17.6, 11.4, 17.6, 15), .sky, width: 1.1)
            art.shape(.poly(19.6, 15, 19.6, 11.4, 21.6, 11.4, 23.8, 15), .sky, width: 1.1)
            art.shape(.box(26.4, 17.2, 2.2, 1.8, r: 0.6), .yellow, width: 0.8)
            for x in [CGFloat(9.4), 22.6] {
                art.shape(.circle(x, 22.6, 3.4), .black, width: 1.3)
                art.dot(x, 22.6, 1.2, .steel)
            }
        },
        SubjectIcon("plane", .things, en: "plane", ru: "самолёт", tint: .sky,
                    keys: "travel путешеств aviation авиаци flight полёт pilot пилот trip поездк") { art in
            let tilt: CGFloat = 45
            art.shape(EmojiFigure.poly(13.8, 11.8, 2.8, 18, 2.8, 20.4, 13.8, 17.2).rotated(tilt), .sky, width: 1.3)
            art.shape(EmojiFigure.poly(18.2, 11.8, 29.2, 18, 29.2, 20.4, 18.2, 17.2).rotated(tilt), .sky, width: 1.3)
            art.shape(EmojiFigure.poly(14.2, 23.2, 9.6, 26.2, 9.6, 27.8, 14.4, 26.4).rotated(tilt), .sky, width: 1.1)
            art.shape(EmojiFigure.poly(17.8, 23.2, 22.4, 26.2, 22.4, 27.8, 17.6, 26.4).rotated(tilt), .sky, width: 1.1)
            art.shape(EmojiFigure.path("M16 2.8 C17.6 2.8 18.4 4.6 18.4 6.8 L18.4 24.4 L16 28.4 L13.6 24.4 L13.6 6.8 C13.6 4.6 14.4 2.8 16 2.8 Z").rotated(tilt), .white, width: 1.4)
            art.fill(EmojiFigure.path("M14.6 6.6 C14.6 5.2 15.2 4.4 16 4.4 C16.8 4.4 17.4 5.2 17.4 6.6 Z").rotated(tilt), .navy)
        },
    ]

    // MARK: - Nature

    private static let nature: [SubjectIcon] = [
        SubjectIcon("plant", .things, en: "plant", ru: "растение", tint: .green,
                    keys: "plants растени gardening садоводств botany ботаник calm спокойстви growth рост") { art in
            let leaves: [(EmojiFigure, InkPencil)] = [
                (.path("M16 17.6 C13.6 13.6 13.8 8.4 16.4 4.6 C19 8.4 18.8 13.6 16 17.6 Z"), .green),
                (.path("M15.6 17.4 C11 17.4 7 14.8 5.6 10.6 C10.4 10.4 13.8 13 15.6 17.4 Z"), .lime),
                (.path("M16.4 17.4 C20.4 16.2 24.4 12.6 25 8.2 C20.6 9.2 17.4 12.4 16.4 17.4 Z"), .lime),
            ]
            for (leaf, pencil) in leaves {
                art.shape(leaf, pencil, width: 1.3)
            }
            art.fine(.curve(16, 17, 16.2, 11, 16.4, 6.4))
            art.fine(.curve(15.4, 17, 11, 14, 7.6, 11.4))
            art.fine(.curve(16.6, 17, 20.4, 13, 23.6, 9.4))
            let pot = EmojiFigure.path("M9.8 19.6 L22.2 19.6 L20.8 27.4 C20.6 28.2 20 28.6 19.2 28.6 L12.8 28.6 C12 28.6 11.4 28.2 11.2 27.4 Z")
            art.fill(pot, .terracotta)
            art.clip(pot) { inside in
                inside.shade(.box(18.4, 0, 10, 32), opacity: 0.22)
            }
            art.ink(pot, width: 1.4)
            art.shape(.box(8.6, 17.4, 14.8, 3, r: 1), .terracotta, width: 1.3)
        },
        SubjectIcon("flower", .things, en: "tulip", ru: "тюльпан", tint: .red,
                    keys: "flower цвет spring весн garden сад botany ботаник gift подар") { art in
            art.ink(.curve(16.4, 28.8, 16, 23, 16.2, 16.4), .green, width: 1.8)
            art.shape(.path("M16.2 27.4 C12.4 26.8 9 23.4 8.6 18.8 C12.6 19.8 15.4 23 16.2 27.4 Z"), .green, width: 1.2)
            art.shape(.path("M16.4 25.6 C19.8 24.2 22.8 21 23 17.2 C19.4 18.4 17 21.4 16.4 25.6 Z"), .lime, width: 1.2)
            let bloom = EmojiFigure.path("M10.4 6.6 L13.2 9.2 L16 4 L18.8 9.2 L21.6 6.6 C22.4 12.6 20.2 16.6 16 16.6 C11.8 16.6 9.6 12.6 10.4 6.6 Z")
            art.fill(bloom, .red)
            art.clip(bloom) { inside in
                inside.shade(.box(17.6, 0, 10, 32), opacity: 0.22)
            }
            art.ink(bloom, width: 1.4)
            art.fine(.curve(16, 5.2, 15.8, 10, 16, 15.6), .ink, opacity: 0.7)
        },
        SubjectIcon("sun", .things, en: "sun", ru: "солнце", tint: .yellow,
                    keys: "summer лето weather погод day день energy энерги morning утро") { art in
            for index in 0..<10 {
                let angle = (CGFloat(index) * 36 - 90) * .pi / 180
                art.ink(.line(16 + cos(angle) * 9.8, 16 + sin(angle) * 9.8, 16 + cos(angle) * 13.4, 16 + sin(angle) * 13.4), .orange, width: 1.7)
            }
            let disc = EmojiFigure.circle(16, 16, 7.4)
            art.fill(disc, .yellow)
            art.clip(disc) { inside in
                inside.shade(.path("M18 7 A 9 9 0 0 1 18 25 L28 25 L28 7 Z"), opacity: 0.18)
            }
            art.ink(disc, width: 1.5)
        },
        SubjectIcon("moon", .things, en: "moon", ru: "луна", tint: .yellow,
                    keys: "night ночь sleep сон evening вечер astronomy астроном dream мечт") { art in
            let moon = EmojiFigure.path("M17.4 3.8 A12 12 0 1 0 28.4 19.4 A9.4 9.4 0 1 1 17.4 3.8 Z")
            art.fill(moon, .yellow)
            art.clip(moon) { inside in
                inside.shade(.box(0, 19, 32, 14), opacity: 0.2)
            }
            art.ink(moon, width: 1.5)
            art.shape(.star(24.8, 7.4, 3, inner: 1, points: 4), .yellow, width: 0.9)
            art.shape(.star(28.4, 13, 1.8, inner: 0.7, points: 4), .yellow, width: 0.8)
        },
        SubjectIcon("cloud", .things, en: "cloud", ru: "облако", tint: .sky,
                    keys: "weather погод meteorology метеоролог sky небо cloud computing облачн") { art in
            let cloud = EmojiFigure.path("""
            M8.6 24 C5.4 24 3.4 21.8 3.6 19.2 C3.8 16.6 5.8 15 8.2 15 C8.6 11 11.8 8.2 15.8 8.2 \
            C19.2 8.2 22 10.2 23 13.4 C26.4 13.4 28.8 16 28.6 19 C28.4 21.8 26.2 24 23.2 24 Z
            """)
            art.fill(cloud, .white)
            art.clip(cloud) { inside in
                inside.hatch(.box(0, 19.2, 32, 8), .sky, angle: -45, gap: 1.6)
            }
            art.ink(cloud, width: 1.5)
        },
        SubjectIcon("mountain", .things, en: "mountains", ru: "горы", tint: .blue,
                    keys: "geography географ hiking поход travel путешеств nature природ geology геолог") { art in
            let back = EmojiFigure.poly(12.4, 27.4, 21.8, 7.8, 30.4, 27.4)
            art.fill(back, .sky)
            art.clip(back) { inside in
                inside.fill(.poly(21.8, 7.8, 25, 14.6, 22.8, 13.2, 20.8, 15, 18.8, 14), .white)
            }
            art.ink(back, width: 1.4)
            let front = EmojiFigure.poly(1.6, 27.4, 11.4, 10.4, 22, 27.4)
            art.fill(front, .blue)
            art.clip(front) { inside in
                inside.fill(.poly(11.4, 10.4, 14.6, 16, 12.6, 14.8, 10.8, 16.6, 8.4, 15.4), .white)
                inside.shade(.poly(11.4, 10.4, 22, 27.4, 13, 27.4), opacity: 0.25)
            }
            art.ink(front, width: 1.5)
        },
        SubjectIcon("wave", .things, en: "wave", ru: "волна", tint: .blue,
                    keys: "ocean океан sea море oceanography океанолог surfing сёрфинг water вода") { art in
            let wave = EmojiFigure.path("""
            M3 26.8 C3.4 16.6 9.6 8.4 18.4 6.8 C24.2 5.8 28.8 8.8 29 13.4 C29.2 17 26.4 19.2 23.4 18.4 \
            C21.2 17.8 20.4 15.4 21.8 13.6 C19 13.8 16.6 16.2 16.4 19.6 C16.2 23 18.4 25.6 21.4 26.8 Z
            """)
            art.fill(wave, .blue)
            art.clip(wave) { inside in
                inside.hatch(.box(0, 0, 32, 32), .sky, angle: 30, gap: 1.7, opacity: 0.9)
            }
            art.ink(wave, width: 1.5)
            art.ink(.curve(9.2, 13.6, 12.8, 9.6, 18.6, 8, 24, 8.8), .paper, width: 1.1)
            art.ink(.line(2.2, 27.2, 29.8, 27), width: 1.4)
        },
    ]

    // MARK: - Animals

    private static let animals: [SubjectIcon] = [
        SubjectIcon("cat", .things, en: "cat", ru: "кот", tint: .orange,
                    keys: "pet питом animal животн kitten котен кошк") { art in
            let head = EmojiFigure.path("""
            M6.6 12.6 L5.4 4.8 L12 9 C14.6 8.2 17.4 8.2 20 9 L26.6 4.8 L25.4 12.6 \
            C27.4 15.2 27.8 18.4 26.6 21.4 C24.8 25.6 20.8 27.6 16 27.6 C11.2 27.6 7.2 25.6 5.4 21.4 \
            C4.2 18.4 4.6 15.2 6.6 12.6 Z
            """)
            art.shape(head, .orange)
            art.hatch(.poly(8, 9, 12.4, 8.8, 13, 15, 9, 14.6), .brown, angle: 90, gap: 1.8, opacity: 0.55)
            art.fill(.poly(7, 6.8, 10.6, 9.2, 7.6, 10.8), .rose)
            art.fill(.poly(25, 6.8, 21.4, 9.2, 24.4, 10.8), .rose)
            art.ink(.curve(10.2, 16.8, 11.6, 15.6, 13, 16.8), width: 1.5)
            art.ink(.curve(19, 16.8, 20.4, 15.6, 21.8, 16.8), width: 1.5)
            art.shape(.poly(14.6, 19.4, 17.4, 19.4, 16, 21), .rose, width: 1)
            art.fine(.curve(16, 21, 15.8, 22.6, 14.2, 23.2))
            art.fine(.curve(16, 21, 16.2, 22.6, 17.8, 23.2))
            art.fine(.line(3.2, 19.4, 10.4, 20.2))
            art.fine(.line(3.6, 22.6, 10.4, 21.6))
            art.fine(.line(28.8, 19.4, 21.6, 20.2))
            art.fine(.line(28.4, 22.6, 21.6, 21.6))
        },
        SubjectIcon("dog", .things, en: "dog", ru: "собака", tint: .tan,
                    keys: "pet питом animal животн puppy щен") { art in
            art.shape(.path("M9.6 8 C6.2 7.2 3.6 10.4 4 15.4 C4.2 18.2 6.4 19.6 8.4 18 C9.6 16.8 10 12 9.6 8 Z"), .brown, width: 1.3)
            art.shape(.path("M22.4 8 C25.8 7.2 28.4 10.4 28 15.4 C27.8 18.2 25.6 19.6 23.6 18 C22.4 16.8 22 12 22.4 8 Z"), .brown, width: 1.3)
            let head = EmojiFigure.path("M9 11.4 C9 7.2 12 4.8 16 4.8 C20 4.8 23 7.2 23 11.4 L23.4 18 C23.6 23.6 20.4 27.6 16 27.6 C11.6 27.6 8.4 23.6 8.6 18 Z")
            art.shape(head, .tan)
            art.fill(.blob(18.4, 9.6, 21.8, 9.2, 22.6, 13, 20.2, 14.6, 18, 13), .brown, opacity: 0.8)
            art.dot(12.8, 13.4, 1.2)
            art.dot(19.4, 13.4, 1.2)
            art.shape(.oval(16, 21, 4.8, 3.6), .paper, width: 1.1)
            art.shape(.oval(16, 19, 2, 1.4), .black, width: 0.9)
            art.fine(.curve(16, 20.4, 16, 22.2, 14.4, 23))
            art.fine(.curve(16, 20.4, 16, 22.2, 17.6, 23))
            art.shape(.path("M15 23.2 L17 23.2 C17.2 25 16.8 25.8 16 25.8 C15.2 25.8 14.8 25 15 23.2 Z"), .rose, width: 0.8)
        },
        SubjectIcon("ladybug", .things, en: "ladybug", ru: "божья коровка", tint: .red,
                    keys: "bug баг debugging отладк insect насеком nature природ luck удач testing тестирован") { art in
            for (from, to) in [((8.4, 14), (4.4, 12.4)), ((7.6, 19.4), (3.6, 20)), ((9.2, 24.4), (5.6, 27)), ((23.6, 14), (27.6, 12.4)), ((24.4, 19.4), (28.4, 20)), ((22.8, 24.4), (26.4, 27))] as [((CGFloat, CGFloat), (CGFloat, CGFloat))] {
                art.ink(.line(from.0, from.1, to.0, to.1), width: 1.2)
            }
            art.ink(.curve(13.8, 6.8, 12.4, 4.4, 10.2, 3.6), width: 1.1)
            art.ink(.curve(18.2, 6.8, 19.6, 4.4, 21.8, 3.6), width: 1.1)
            art.shape(.path("M11.2 10.6 C11.4 7.4 13.4 5.6 16 5.6 C18.6 5.6 20.6 7.4 20.8 10.6 Z"), .black, width: 1.3)
            let shell = EmojiFigure.circle(16, 18.4, 9.8)
            art.fill(shell, .red)
            art.clip(shell) { inside in
                for (x, y, r) in [(11.6, 14.2, 1.8), (20.4, 14.2, 1.8), (10.6, 20.6, 1.6), (21.4, 20.6, 1.6), (13.6, 25.2, 1.4), (18.4, 25.2, 1.4)] as [(CGFloat, CGFloat, CGFloat)] {
                    inside.fill(.circle(x, y, r), .black)
                }
                inside.shade(.box(18, 0, 14, 32), opacity: 0.18)
            }
            art.ink(shell, width: 1.5)
            art.ink(.line(16, 9, 16, 28), width: 1.2)
            art.dot(14, 8.2, 0.6, .white)
            art.dot(18, 8.2, 0.6, .white)
        },
    ]
}
