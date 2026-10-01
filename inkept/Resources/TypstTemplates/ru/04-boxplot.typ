#import "@preview/cetz:0.5.2": canvas
#import "@preview/cetz-plot:0.1.4": chart

#align(center, canvas({
  chart.boxwhisker(
    size: (7, 4),
    label-key: "label",
    y-min: 0, y-max: 12, y-tick-step: 2,
    y-label: [Результат],
    (
      (label: "1", min: 1, q1: 2.5, q2: 3.5, q3: 5, max: 9),
      (label: "2", min: 3, q1: 5.5, q2: 6.5, q3: 7.5, max: 9),
      (label: "3", min: 3, q1: 6, q2: 8, q3: 9.5, max: 11.5),
    ),
  )
}))
