#import "template.typ" as template: *
#import "/src/lib.typ" as alexandria

#let package-meta = toml("/typst.toml").package
#let date = none
// #let date = datetime(year: ..., month: ..., day: ...)

#show: manual(
  title: "Alexandria",
  // subtitle: "...",
  authors: package-meta.authors.map(a => a.split("<").at(0).trim()),
  abstract: [
    _Alexandria_ allows a single document to have multiple bibliographies.
  ],
  url: package-meta.repository,
  version: package-meta.version,
  date: date,
)

// the scope for evaluating expressions and documentation
#let scope = (alexandria: alexandria)

= Introduction

_Alexandria_ allows adding multiple bibliographies to the same document. Its two main functions are #ref-fn("alexandria()") and #ref-fn("bibliographyx()"). Typical usage would look something like this:

#crudo.join(
  main: -1,
  crudo.map(
    ```typ
    #import "@preview/NAME:VERSION": *
    ```,
    line => line.replace("NAME", package-meta.name).replace("VERSION", package-meta.version),
  ),
  ```typ
  #show: alexandria(prefix: "x-", read: path => read(path))

  ...

  #bibliographyx(
    "bibliography.bib",
    // title: auto is not yet supported so it needs to be specified
    title: "Bibliography",
  )
  ```
)

With this setup, you can use regular Typst citations (to keys starting with the configured prefix) to cite entries in an Alexandria bibliography.

Some known limitations:

- Alexandria citations are converted to links and are thus affected by `link` rules.
- Native bibliographies have `numbering: none` applied to its title, while Alexandrias' haven't. `show bibliography: set heading(...)` also won't work on them.
- Adjacent citations aren't collapsed.
- Citations that are shown as footnotes are not supported yet.

The example on the next page demonstrates some of these. If you find additional limitations or other issues, please report them at https://github.com/SillyFreak/typst-alexandria/issues.

#pagebreak(weak: true)

= Example -- native Typst version (APA)

#[
  For further information on pirate and quark organizations, see @arrgh @quark.
  #cite(<distress>, form: "author") discusses bibliographical distress.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<netwok>, form: "prose", style: "apa") zu lesen.
  ]

  #set heading(offset: 1)
  #bibliography(
    "bibliography.bib",
    // title: "Bibliography",
    full: true,
    style: "apa",
  )
]

= Example -- Alexandria version (APA)

#[
  #import alexandria: *
  #show: alexandria(prefix: "x-", read: path => read(path))

  For further information on pirate and quark organizations, see @x-arrgh @x-quark.
  #cite(<x-distress>, form: "author") discusses bibliographical distress.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<x-netwok>, form: "prose", style: "ieee") zu lesen.
  ]

  #set heading(offset: 1)
  #bibliographyx(
    "bibliography.bib",
    prefix: "x-",
    title: "Bibliography",
    full: true,
    style: "apa",
  )
]

= Example -- Alexandria version (IEEE)

#[
  #import alexandria: *
  #show: alexandria(prefix: "y-", read: path => read(path))

  For further information on pirate and quark organizations, see @y-arrgh @y-quark.
  #cite(<y-distress>, form: "author") discusses bibliographical distress.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<y-netwok>, form: "prose", style: "apa") zu lesen.
  ]

  #set heading(offset: 1)
  #bibliographyx(
    "bibliography.bib",
    prefix: "y-",
    title: "Bibliography",
    full: true,
    style: "ieee",
  )
]

#pagebreak(weak: true)

= Module reference

#module(
  read("/src/lib.typ"),
  name: "alexandria",
  label-prefix: none,
  scope: scope,
)
