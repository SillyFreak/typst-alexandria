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
    // full: false is not yet supported so it needs to be specified
    full: true,
    // currently, only ieee style is supported
    style: "ieee",
  )
  ```
)

= Module reference

#module(
  read("/src/lib.typ"),
  name: "alexandria",
  label-prefix: none,
  scope: scope,
)
