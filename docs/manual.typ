#import "template.typ" as template: *
#import "/src/lib.typ" as alexandria

#import "@preview/crudo:0.1.1"

#show: manual(
  package-meta: toml("/typst.toml").package,
  title: "Alexandria",
  subtitle: [
    _Alexandria_ allows a single document to have multiple bibliographies.
  ],
  date: datetime(year: 2025, month: 4, day: 23),

  // logo: rect(width: 5cm, height: 5cm),
  // abstract: [
  //   A PACKAGE for something
  // ],

  scope: (alexandria: alexandria),
)

= Introduction

_Alexandria_ enables multiple bibliographies within the same Typst document.

With _Alexandria_, each citation citation is associated with a _prefix_.
To specify the prefix, one can explicitly prepend it to the bibliograhic key (e.g. `@x-quark` or `#cite(<y-arggh>)`)
or set the default prefix with this #ref-fn("alexandria-prefix()") function.
#ref-fn("bibliographyx()") allows generating a bibliography limited to the citations with a specific prefix.

Typical usage would look something like this:

#context crudo.join(
  main: -1,
  crudo.map(
    ```typ
    #import "PACKAGE": *
    ```,
    line => line.replace("PACKAGE", package-import-spec()),
  ),
  ```typ
  #show: alexandria("bibliography.bib", reader: path => read(path))

  ...
  My text that references @x-quark and @x-netwok.
  ...

  #bibliographyx(
    prefix: "x",
    title: "X Bibliography",
  )

  ...

  Lets use `y-` prefix by default for the rest of the document.

  #alexandria-prefix("y")

  ...
  Here we are referencing @arggh and @y-distress.
  ...

  #bibliographyx(
    prefix: "y",
    title: "Y Bibliography",
  )
  ```
)

With this setup, you can use regular Typst citations (to keys starting with the configured prefix) to cite entries in an Alexandria bibliography.

Some known limitations:

- Alexandria citations are converted to links and are thus affected by `link` rules.
- Native bibliographies have `numbering: none` applied to its title, while Alexandrias' haven't. ```typc show bibliography: set heading(...)``` also won't work on them.
- Citations that are shown as footnotes are not supported yet -- see #link("https://github.com/SillyFreak/typst-alexandria/issues/11")[issue \#11].

If you find additional limitations or other issues, please report them at https://github.com/SillyFreak/typst-alexandria/issues.

#pagebreak(weak: true)

= Example: Separate bibliographies for document sections

Below we demonstrate how to create separate bibliographies with independent numbering for different sections of a document:
- @ex-native[Example] uses the native Typst bibliography
- @ex-apa[Example] uses explicit prefix specification (`x`) for Alexandria bibliography with APA-style references
- @ex-ieee[Example] shows how #ref-fn("alexandria-prefix()") could be used to specify the default prefix (`y`) and generate the IEEE-style bibliography.

== Native Typst (APA) <ex-native>

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

#[

== Alexandria (APA) <ex-apa>

  #import alexandria: *
  #show: alexandria("bibliography.bib", reader: path => read(path))

  For further information on pirate and quark organizations, see #citegroup[@x-arrgh @x-quark].
  #cite(<x-distress>, form: "author") discusses bibliographical distress.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<x-netwok>, form: "prose", style: "ieee") zu lesen.
  ]

  #bibliographyx(
    prefix: "x",
    title: "Bibliography",
    //full: true,
    style: "apa",
  )

== Alexandria (IEEE) <ex-ieee>

  #alexandria-prefix("y")

  For further information on pirate and quark organizations, see #citegroup[@arrgh @quark].
  #cite(<distress>, form: "author") discusses bibliographical distress.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<netwok>, form: "prose", style: "apa") zu lesen.
  ]

  #bibliographyx(
    prefix: "y",
    title: "Bibliography",
    //full: true,
    style: "ieee",
  )
]

#pagebreak(weak: true)

= Splitting bibliographies <ex-split>

In the previous example, the bibliographies we created for separate parts of a document, and each had its own independent numbering.
This approach will not work when multiple bibliographies have to serve the same region of the document, because with overlapping numbers the citations become ambiguous.
For this scenario, Alexandria allows decoupling _collection_ of the references from their _rendering_.
Instead of a single #ref-fn("bibliographyx()") call:
- #ref-fn("collect-citations()") assembles the combined list of all bibliographical entries with prefixes that match the user-specified criteria
- #ref-fn("render-bibliography()") renders the subset of this list, further filtering its entries by the prefix or other properties. #ref-fn("render-bibliography()") could be called multiple times, each time with a different filter.

An example Typst code could look like this:

#context crudo.join(
  main: -1,
  crudo.map(
    ```typ
    #import "PACKAGE": *
    ```,
    line => line.replace("PACKAGE", package-import-spec()),
  ),
  ```typ
  #show: alexandria("bibliography.bib", reader: path => read(path))

  ...

  #collect-citations("a_and_b", prefix-filter: ("a", "b"))

  #render-bibliography("a_and_b",
    filter: ref => ref.prefixes.contains("a"),
    title: "A Bibliography",
  )

  #render-bibliography("a_and_b",
    filter: ref => ref.prefixes.contains("b") and ref.details.type != "book",
    title: "B Articles",
  )

  #render-bibliography("a_and_b",
    filter: ref => ref.prefixes.contains("b") and ref.details.type == "book",
    title: "B Books",
  )
  ```
)

Here's the rendered output:

#[
  #import alexandria: *
  #show: alexandria("bibliography.bib", reader: path => read(path))
  #alexandria-prefix("a")

  For further information on pirate and quark organizations, see #citegroup[@arrgh @quark].
  #cite(<b-distress>, form: "author") discusses bibliographical distress in @b-distress,
  and @b-psychology25 is a hefty volume on various aspects of psychology.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<b-netwok>, form: "prose", style: "apa") zu lesen.
  ]

  #collect-citations("a_and_b", prefix-filter: ("a", "b"))

  #render-bibliography("a_and_b",
    filter: ref => ref.prefixes.contains("a"),
    title: "A Bibliography",
  )

  #render-bibliography("a_and_b",
    filter: ref => ref.prefixes.contains("b") and ref.details.type != "book",
    title: "B Articles",
  )

  #render-bibliography("a_and_b",
    filter: ref => ref.prefixes.contains("b") and ref.details.type == "book",
    title: "B Books",
  )
]

#pagebreak(weak: true)

= Module reference

#module(
  read("/src/lib.typ"),
  name: "alexandria",
  label-prefix: none,
)
