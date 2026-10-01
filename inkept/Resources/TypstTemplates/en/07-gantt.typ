#import "@preview/timeliney:0.4.0"

#timeliney.timeline(show-grid: true, {
  import timeliney: *
  headerline(group(([*2026*], 4)))
  headerline(group(..range(4).map(n => strong("Q" + str(n + 1)))))
  taskgroup(title: [*Study*], {
    task("Read the book", (0, 1.5), style: (stroke: 2pt + gray))
    task("Solve problems", (1, 3), style: (stroke: 2pt + gray))
  })
  taskgroup(title: [*Exam*], {
    task("Revise", (2.5, 3.8), style: (stroke: 2pt + gray))
  })
  milestone(at: 3.8, style: (stroke: (dash: "dashed")), align(center, [*Exam day*]))
})
