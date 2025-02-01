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

This is a template for typst packages. It provides the #ref-fn("id()") function:

#file-code("lib.typ", {
  let lib = raw(block: true, lang: "typ", read("/src/lib.typ").trim(at: end))
  lib = crudo.lines(lib, "10-")
  lib
})

Here is the function in action:
#man-style.show-example(mode: "markup", dir: ttb, scope: scope, ```typ
one equals #alexandria.id[one], 1 = #alexandria.id(1)
```)

= Module reference

#module(
  read("/src/lib.typ"),
  name: "alexandria",
  label-prefix: none,
  scope: scope,
)
