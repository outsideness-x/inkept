#import "@preview/cetz:0.5.2": canvas
#import "@preview/cetz-plot:0.1.4": chart

#align(center, canvas({
  chart.piechart(
    (([Volume], 30), ([Velocity], 25), ([Variety], 20), ([Veracity], 15), ([Value], 10)),
    value-key: 1,
    label-key: 0,
    radius: 2.6,
    slice-style: (red.lighten(45%), orange.lighten(50%), yellow.lighten(40%), green.lighten(55%), blue.lighten(55%)),
    outer-label: (content: "LABEL", radius: 125%),
    inner-label: (content: "%", radius: 1.7),
    legend: (label: none),
  )
}))
