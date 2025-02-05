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

Note that Alexandria is currently limited to non-Englishfull bibliographies, but more general support is planned soon.

#pagebreak(weak: true)

= Example

// #set text(lang: "de")

Below is an example text using equivalent content, showing the current problems:

- Alexandria citations are converted to links and are thus affected by `link` rules.
- The native bibliography has `numbering: none` applied to its title, while Alexandria's hasn't. `show bibliography: set heading(...)` also won't work on it.
- Adjacent citations aren't collapsed yet, thus the Alexandria version misses a comma.
- Non-full bibliographies are not supported yet, thus there's an extra entry in the native version that Alexandria can't produce yet.
- Per-citation customization of style and language are not supported yet, thus there is an English "and" in place of a German #text(lang: "de")["und"] in the second paragraph.

== Alexandria version

#[
  #import alexandria: *
  #show: alexandria(prefix: "x-", read: path => read(path))

  For further information on pirate and quark organizations, see @x-arrgh @x-quark.
  #cite(<x-distress>, form: "author") discusses bibliographical distress.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<x-netwok>, form: "prose") zu lesen.
  ]

  #set heading(offset: 2)
  #bibliographyx(
    "bibliography.bib",
    title: "Bibliography",
    full: true,
    // style: "apa",
  )
]

== Native Typst version

#[
  For further information on pirate and quark organizations, see @arrgh @quark.
  #cite(<distress>, form: "author") discusses bibliographical distress.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<netwok>, form: "prose") zu lesen.
  ]

  #set heading(offset: 2)
  #bibliography(
    "bibliography.bib",
    // title: "Bibliography",
    full: true,
    // style: "apa",
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
