#import "@preview/mannot:0.4.0": *

#block(inset: (y: 1.6em), width: 100%)[$ mark(a x + b, tag: #<first>, color: #red) mark((c x + d), tag: #<second>, color: #blue)
  = a c x^2 + (a d + b c) x + b d
  #annot(<first>, pos: bottom)[первый]
  #annot(<second>, pos: top)[второй] $]
