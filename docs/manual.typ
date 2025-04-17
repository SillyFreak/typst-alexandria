#import "template.typ" as template: *
#import "/src/lib.typ" as alexandria

#import "@preview/crudo:0.1.1"

#let package-meta = toml("/typst.toml").package
#let date = datetime(year: 2025, month: 3, day: 13)

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
- Citations that are shown as footnotes are not supported yet -- see #link("https://github.com/SillyFreak/typst-alexandria/issues/11")[issue \#11].

The example on the next page demonstrates some of these. If you find additional limitations or other issues, please report them at https://github.com/SillyFreak/typst-alexandria/issues.

#pagebreak(weak: true)

= Example -- native Typst version (APA) <ex-native>

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

= Example -- Alexandria version (APA) <ex-apa>

#[
  #import alexandria: *
  #show: alexandria(prefix: "x-", read: path => read(path))

  For further information on pirate and quark organizations, see #citegroup(prefix: "x-")[@x-arrgh @x-quark].
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

= Example -- Alexandria version (IEEE) <ex-ieee>

#[
  #import alexandria: *
  #show: alexandria(prefix: "y-", read: path => read(path))

  For further information on pirate and quark organizations, see #citegroup(prefix: "y-")[@y-arrgh @y-quark].
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

= Splitting bibliographies

The previous three examples showed using Alexandria to render three separate bibliographies for different parts of a document: @ex-native[Example] used the native bibliography, @ex-apa[Example] used Alexandria to show APA style references, and @ex-ieee[Example] showed IEEE style. Particularly, with IEEE, all references are numbered and multiple separate Alexandria bibliographies would reuse the same 1-based numbering.

This approach is thus not suitable for multiple bibliographies that serve the same regions of a document. For this purpose, Alexandria also supports splitting the _loading_ and _rendering_ of a bibliography, giving you the opportunity to preprocess the bibliography entries. Instead of calling #ref-fn("bibliographyx()") directly, you'd use #ref-fn("load-bibliography()") followed by #ref-fn("get-bibliography()") and #ref-fn("render-bibliography()").

An example could look like this:

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

  // load the bibliography so that the data is available to citations and rendering
  #load-bibliography("bibliography.bib")

  #context {
    // get the bibliography items
    let (references, ..rest) =  get-bibliography("x-")

    // render the bibliography
    render-bibliography(
      title: [Bibliography],
      (
        // instead of giving it all references, only consider non-book references
        references: references.filter(x => x.details.type != "book"),
        // `render-bibliography()` also needs the non-reference information
        // that was returned by `get-bibliography()`
        ..rest,
      ),
    )

    // render the rest of the bibliography
    // (this could also be somewhere else in the document)
    render-bibliography(
      title: [Books],
      (
        references: references.filter(x => x.details.type == "book"),
        ..rest,
      ),
    )
  }
  ```
)

= Example -- Splitting a bibliography <ex-split>

Here is a rendered example of using this approach. You can see how the single call to #ref-fn("load-bibliography()") results in the entries using distinct numbers.

Note how all references are rendered once, although in a different presentation from usual. This is generally a requirement for citations being able to refer to their corresponding reference's label. In this particular case, this is not a concern since there are no citations and references were rendered due to the `full` option, but in general this is a concern.

#[
  #import alexandria: *
  #show: alexandria(prefix: "z-", read: path => read(path))

  #load-bibliography(
    "bibliography.bib",
    prefix: "z-",
    full: true,
  )

  #set heading(offset: 1)
  #context {
    let (references, ..rest) =  get-bibliography("z-")

    render-bibliography(
      title: [Bibliography],
      (
        references: references.filter(x => x.details.type != "book"),
        ..rest,
      ),
    )

    render-bibliography(
      title: [Books],
      (
        references: references.filter(x => x.details.type == "book"),
        ..rest,
      ),
    )
  }
]

#pagebreak(weak: true)

= Module reference

#module(
  read("/src/lib.typ"),
  name: "alexandria",
  label-prefix: none,
  scope: scope,
)
