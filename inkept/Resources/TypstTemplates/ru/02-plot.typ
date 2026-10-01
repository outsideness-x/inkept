#import "@preview/cetz:0.5.2": canvas, draw
#import "@preview/cetz-plot:0.1.4": plot

#align(center, canvas({
  plot.plot(
    size: (8, 4),
    x-tick-step: 1, y-tick-step: 1,
    x-label: $x$, y-label: $y$,
    legend: "inner-north-east",
    {
      plot.add(domain: (0, 6.28), samples: 120, x => calc.sin(x), label: $sin x$, style: (stroke: 1.4pt + red))
      plot.add(domain: (0, 6.28), samples: 120, x => calc.cos(x), label: $cos x$, style: (stroke: 1.4pt + blue))
    },
  )
}))
