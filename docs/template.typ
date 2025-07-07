// adapted from https://github.com/Mc-Zen/tidy/blob/98612b847da41ffb0d1dc26fa250df5c17d50054/docs/template.typ
// licensed under the MIT license

#import "@preview/tidy:0.4.3"
#import "@preview/codly:1.3.0"
#import "@preview/t4t:0.4.2"

#import "man-style.typ"

#let _info = state("manual:info")

// The manual function defines how your document looks.
// It takes your content and some metadata and formats it.
// Go ahead and customize it to your liking!
#let manual(
  package-meta: none,

  title: auto,
  subtitle: auto,
  logo: none,
  authors: auto,
  abstract: none,
  url: auto,
  version: auto,
  date: none,

  scope: (:),
) = body => {
  import t4t.def: if-auto

  let title = if-auto(title, def: package-meta.name)
  let subtitle = if-auto(subtitle, def: package-meta.description)
  let authors = if-auto(authors, def: {
    package-meta.at("authors").map(a => a.split("<").first().trim())
  })
  let url = if-auto(url, def: {
    package-meta.at("homepage", default:
      package-meta.at("repository", default: none))
  })
  let version = if-auto(version, def: package-meta.version)

  _info.update((
    meta: package-meta,
    scope: scope,
  ))

  // Set the document's basic properties.
  set document(author: authors, title: title, date: date)
  set page(numbering: "1", number-align: center)
  set text(font: man-style.serif-font, lang: "en")

  set heading(numbering: "I.a")
  show heading.where(level: 1): set block(below: 1em)
  show heading.where(level: 1): smallcaps

  show list: pad.with(x: 5%)

  show: codly.codly-init
  show raw.where(block: true): set text(size: .9em)
  show raw.where(block: true): pad.with(x: 4%)
  codly.codly(fill: white)

  // show link: set text(fill: rgb("#1e8f6f"))
  // show link: underline

  // title page
  page(columns: 2, {
    place(top, float: true, scope: "parent", {
      show: block.with(height: 75%)

      set align(center)

      v(1fr)

      // title
      block(text(weight: 700, 1.75em, title))
      block(text(1.0em, subtitle))

      // logo
      if logo != none {
        v(4em, weak: true)
        logo
      }

      // version, date
      v(4em, weak: true)
      [v#version]
      if date != none [
        #h(1.2cm)
        #date.display("[month repr:long] [day], [year]")
      ]

      // url
      block(link(url))
      v(1.5em, weak: true)

      // authors
      block(above: 0.5cm, {
        pad(x: 2em, grid(
          columns: (1fr,) * calc.min(3, authors.len()),
          gutter: 1em,
          ..authors.map(author => align(center, strong(author))),
        ))
      })

      v(1fr)

      set align(left)
      set par(justify: true)
      pad(x: 8%, abstract)

      v(1fr)

    })

    outline(depth: 3)
  })

  // Main body.

  set par(justify: true)
  show raw.where(block: true): set par(justify: false)
  show: tidy.render-examples.with(scope: scope, layout: man-style.layout-example)

  body
}

// retrieve the package metadata (contextual)
#let package-meta() = _info.get().meta

// retrieve the evaluation scope (contextual)
#let eval-scope() = _info.get().scope

// retrieve the package import spec, i.e. `@preview/<name>:<version>` (contextual)
#let package-import-spec(namespace: "preview") = {
  let meta = package-meta()
  "@" + namespace + "/" + meta.name + ":" + meta.version
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

  context {
    let scope = eval-scope() + scope
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
}

#let ref-fn(name) = man-style.show-reference(label(name), name)

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
    radius: man-style.preview-radius * 1.25,
    in-raw: false,
    ..args,
    block(width: 90%, inset: 16pt, breakable: false, {
      set align(left)
      body
    })
  )
}
