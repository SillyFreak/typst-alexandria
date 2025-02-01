// adapted from https://github.com/Mc-Zen/tidy/blob/98612b847da41ffb0d1dc26fa250df5c17d50054/docs/template.typ
// licensed under the MIT license

#import "@preview/tidy:0.3.0"
#import "@preview/codly:1.0.0"
#import "@preview/crudo:0.1.1"

#import "man-style.typ"

// The manual function defines how your document looks.
// It takes your content and some metadata and formats it.
// Go ahead and customize it to your liking!
#let manual(
  title: "",
  subtitle: "",
  authors: (),
  abstract: [],
  url: none,
  version: none,
  date: none,
) = body => {
  // Set the document's basic properties.
  set document(author: authors, title: title, date: date)
  set page(numbering: "1", number-align: center)
  set text(font: "Libertinus Serif", lang: "en")

  show heading.where(level: 1): it => block(smallcaps(it), below: 1em)
  // set heading(numbering: (..args) => if args.pos().len() == 1 { numbering("I", ..args) })
  set heading(numbering: "I.a")
  show list: pad.with(x: 5%)

  // show link: set text(fill: purple.darken(30%))
  show link: set text(fill: rgb("#1e8f6f"))
  show link: underline

  v(4em)

  // Title row.
  align(center, {
    block(text(weight: 700, 1.75em, title))
    block(text(1.0em, subtitle))
    v(4em, weak: true)
    if date == none [
      v#version
    ] else [
      v#version
      #h(1.2cm)
      #date.display("[month repr:long] [day], [year]")
    ]
    block(link(url))
    v(1.5em, weak: true)
  })

  // Author information.
  pad(
    top: 0.5em,
    x: 2em,
    grid(
      columns: (1fr,) * calc.min(3, authors.len()),
      gutter: 1em,
      ..authors.map(author => align(center, strong(author))),
    ),
  )

  v(3cm, weak: true)

  // Abstract.
  pad(
    x: 3.8em,
    top: 1em,
    bottom: 1.1em,
    align(center)[
      #heading(
        outlined: false,
        numbering: none,
        text(0.85em, smallcaps[Abstract]),
      )
      #abstract
    ],
  )

  set par(justify: true)
  show raw.where(block: true): set par(justify: false)
  v(10em)

  // Outline.
  pad(x: 10%, outline(depth: 1))
  pagebreak()


  // Main body.
  show: codly.codly-init
  show raw.where(block: true): set text(size: .9em)
  show raw.where(block: true): pad.with(x: 4%)

  body
}

#let module(
  code,
  name: none,
  label-prefix: auto,
  scope: (:),
  preamble: "",
  ..args,
) = {
  let (name, label-prefix) = (name, label-prefix)
  if label-prefix == auto and name != none {
    label-prefix = name + "."
  } else if type(label-prefix) == str {
    label-prefix += "."
  } else {
    assert(label-prefix == none or name == none)
    label-prefix = ""
  }
  if name != none {
    name = raw(name)
  }

  let module = tidy.parse-module(
    code,
    name: name,
    label-prefix: label-prefix,
    scope: scope,
    preamble: preamble,
  )
  tidy.show-module(
    module,
    show-module-name: name != none,
    sort-functions: none,
    style: man-style,
    ..args,
  )
}

#let ref-fn(name) = link(label(name), man-style.mono(name))

#let file-code(filename, code) = pad(x: 4%, block(
  width: 100%,
  fill: rgb("#239DAE").lighten(80%),
  inset: 1pt,
  stroke: rgb("#239DAE") + 1pt,
  radius: 3pt,
  {
    block(align(right, text(raw(filename))), width: 100%, inset: 5pt)
    v(1pt, weak: true)
    move(dx: -1pt, line(length: 100% + 2pt, stroke: 1pt + rgb("#239DAE")))
        v(1pt, weak: true)
    pad(x: -4.3%, code)
  }
))

#let preview-block(body, ..args) = {
  show: figure
  man-style.preview-block(
    radius: man-style.preview-radius * 3,
    ..args,
    {
      set heading(numbering: none, outlined: false)
      set text(size: .8em)
      show: box.with(
        width: 80%,
        inset: 20pt,
      )
      show: align.with(left)
    block(breakable: false, body)
    }
  )
}
