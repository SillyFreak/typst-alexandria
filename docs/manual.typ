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

This package allows adding multiple bibliographies to the same document.

= Module reference

#module(
  read("/src/lib.typ"),
  name: "alexandria",
  label-prefix: none,
  scope: scope,
)
