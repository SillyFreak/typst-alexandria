#import "template.typ" as template: *
#import "/src/lib.typ" as my-package

#let package-meta = toml("/typst.toml").package
#let date = none
// #let date = datetime(year: ..., month: ..., day: ...)

#show: manual(
  title: "Template",
  // subtitle: "...",
  authors: package-meta.authors.map(a => a.split("<").at(0).trim()),
  abstract: [
    A template for typst packages
  ],
  url: package-meta.repository,
  version: package-meta.version,
  date: date,
)

// the scope for evaluating expressions and documentation
#let scope = (my-package: my-package)

= Introduction

This is a template for typst packages. It provides the #ref-fn("id()") function:

#file-code("lib.typ", {
  let lib = raw(block: true, lang: "typ", read("/src/lib.typ").trim(at: end))
  lib = crudo.lines(lib, "10-")
  lib
})

Here is the function in action:
#man-style.show-example(mode: "markup", dir: ttb, scope: scope, ```typ
one equals #my-package.id[one], 1 = #my-package.id(1)
```)

= Module reference

#module(
  read("/src/lib.typ"),
  name: "my-package",
  label-prefix: none,
  scope: scope,
)
