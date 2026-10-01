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
