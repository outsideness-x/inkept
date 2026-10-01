#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#align(center, diagram(
  spacing: (8mm, 7mm),
  node-stroke: 1pt,
  node-corner-radius: 4pt,
  node-inset: 7pt,
  node((0, 3), [Вход], fill: red.lighten(75%)),
  edge("-|>"),
  node((0, 2), [Внимание], fill: orange.lighten(65%)),
  edge("-|>"),
  node((0, 1), [Сумма и норма], fill: yellow.lighten(55%)),
  edge("-|>"),
  node((0, 0), [Выход], fill: green.lighten(60%)),
  edge((0, 2), (1, 2), (1, 1), (0, 1), "--|>", [обход], label-side: left),
))
