#import "template.typ" as template: *
#import "/src/lib.typ" as alexandria

#import "@preview/crudo:0.1.1"

#show: manual(
  package-meta: toml("/typst.toml").package,
  title: "Alexandria",
  subtitle: [
    _Alexandria_ allows a single document to have multiple bibliographies.
  ],
  date: datetime(year: 2025, month: 7, day: 8),

  // logo: rect(width: 5cm, height: 5cm),
  // abstract: [
  //   A PACKAGE for something
  // ],

  scope: (alexandria: alexandria),
)

= Introduction

_Alexandria_ enables multiple bibliographies within the same Typst document.

In _Alexandria_, each citation is associated with a _prefix_.
#ref-fn("alexandria()") function declares a prefix, e.g. `"x-"`, for a group of bibliographical references.
After this, you can use regular Typst citations, prepending the prefix to a bibliographic key to indicate that it refers to a specific group, e.g. `@x-quark` or `#cite(<x-netwok>)`.
_Alexandria_'s #ref-fn("bibliographyx()") is the equivalent of the built-in `bibliography()` function for generating a bibliography limited to a specific prefix.

Typical usage looks like this:

#context crudo.join(
  main: -1,
  crudo.map(
    ```typ
    #import "PACKAGE": *
    ```,
    line => line.replace("PACKAGE", package-import-spec()),
  ),
  ```typ
  #show: alexandria(prefix: "x-", read: path => read(path))
  #show: alexandria(prefix: "y-", read: path => read(path))

  ... The text that references @x-quark and @x-netwok ...

  #bibliographyx(
    "bibliography.bib",
    prefix: "x-",
    title: "X Bibliography",
  )

  ... The section with references to @y-arggh and @y-distress ...

  #bibliographyx(
    "bibliography.bib",
    prefix: "y-",
    title: "Y Bibliography",
  )
  ```
)

Some known limitations:

- Internally, _Alexandria_ citations are converted to links and are thus affected by `link` rules.
- Native bibliographies have ```typc numbering: none``` applied to its title, while _Alexandria_'s haven't.
  ```typc show bibliography: set heading(...)``` also won't work on them.
- Citations that are shown as footnotes are not supported yet -- see #link("https://github.com/SillyFreak/typst-alexandria/issues/11")[issue \#11].

If you find additional limitations or other issues, please report them at https://github.com/SillyFreak/typst-alexandria/issues.

#pagebreak(weak: true)

= Separate bibliographies for document sections

Below we demonstrate how to create separate bibliographies with independent numbering for different sections of a document:
- @ex-native[Example] uses the native Typst bibliography
- @ex-apa[Example] uses Alexandria to generate APA style references for all bibliographical entries from _bibliography.bib_ (```typc full: true```)
- @ex-ieee[Example] shows a numbered IEEE style bibliography.

== Example

=== Native Typst (APA) <ex-native>

#[
  For further information on pirate and quark organizations, see @arrgh @quark.
  #cite(<distress>, form: "author") discusses bibliographical distress.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<netwok>, form: "prose", style: "apa") zu lesen.
  ]

  #set heading(offset: 3)
  #bibliography(
    "bibliography.bib",
    // title: "Bibliography",
    style: "apa",
  )
]

=== Alexandria (APA) <ex-apa>

#[
  #import alexandria: *
  #show: alexandria(prefix: "x-", read: path => read(path))

  For further information on pirate and quark organizations, see #citegroup(prefix: "x-")[@x-arrgh @x-quark].
  #cite(<x-distress>, form: "author") discusses bibliographical distress.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<x-netwok>, form: "prose", style: "ieee") zu lesen.
  ]

  #set heading(offset: 3, numbering: none)
  #bibliographyx(
    "bibliography.bib",
    prefix: "x-",
    title: "Bibliography",
    full: true,
    style: "apa",
  )
]

=== Alexandria (IEEE) <ex-ieee>

#[
  #import alexandria: *
  #show: alexandria(prefix: "y-", read: path => read(path))

  For further information on pirate and quark organizations, see #citegroup(prefix: "y-")[@y-arrgh @y-quark].
  #cite(<y-distress>, form: "author") discusses bibliographical distress.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<y-netwok>, form: "prose", style: "apa") zu lesen.
  ]

  #set heading(offset: 3, numbering: none)
  #bibliographyx(
    "bibliography.bib",
    prefix: "y-",
    title: "Bibliography",
    style: "ieee",
  )
]

#pagebreak(weak: true)

= Splitting bibliographies <ex-split>

In the previous example, the bibliographies were created for separate parts of a document, and each had its own independent numbering.
This approach will not work when multiple bibliographies have to serve the same region of the document, because with overlapping numbers the citations become ambiguous.
For this scenario, Alexandria allows decoupling _loading_ and _collection_ of the references from their _rendering_.
Instead of a single #ref-fn("bibliographyx()") call:
- #ref-fn("load-bibliography()") loads all bibliographical entries with a specific prefix
- #ref-fn("get-bibliography()") composes a list of entries referenced in the document
- the user can manually filter this list by specific criteria, e.g. by the reference type
- #ref-fn("render-bibliography()") renders the user-specified list of references. This function could be called multiple times, each time with a different subset of references.

A sample Typst code that separates book references from all other types could look like this:

#context crudo.join(
  main: -1,
  crudo.map(
    ```typ
    #import "PACKAGE": *
    ```,
    line => line.replace("PACKAGE", package-import-spec()),
  ),
  ```typ
  #show: alexandria(prefix: "x-", read: path => read(path))

  ... The text that cites entries from "x-" ...

  #load-bibliography("bibliography.bib")

  #context {
    // get the bibliography items + additional information
    let (references: bib_refs, ..bib_info) = get-bibliography("x-")

    // render the non-book bibliography
    render-bibliography(
      title: [Bibliography],
      (
        references: bib_refs.filter(ref => ref.details.type != "book"),
        ..bib_info, // provide other information from get-bibliography()
      ),
    )

    // render the books bibliography (could also be elsewhere in the document)
    render-bibliography(
      title: [Books],
      (
        references: bib_refs.filter(ref => ref.details.type == "book"),
        ..bib_info,
      ),
    )
  }
  ```
)

#pagebreak(weak: true)

Here's how the rendered output would look like.
Note that the numbering in the bibliographies is not sequential.
It is the result of making the lists non-overlapping to allow citations unambiguosly refer to specific bibliographic entries.

== Example

#[
  #import alexandria: *
  #show: alexandria(prefix: "z-", read: path => read(path))

  #load-bibliography(
    "bibliography.bib",
    prefix: "z-",
  )

  For further information on pirate and quark organizations, see #citegroup(prefix: "z-")[@z-arrgh @z-quark].
  #cite(<z-distress>, form: "author") discusses bibliographical distress in @z-distress,
  and @z-psychology25 is a hefty volume on various aspects of psychology.

  #text(lang: "de")[
    Über den "Netzwok" ist in der Arbeit von #cite(<z-netwok>, form: "prose", style: "apa") zu lesen.
  ]

  #set heading(offset: 3, numbering: none)
  #context {
    let (references: bib_refs, ..bib_info) = get-bibliography("z-")

    render-bibliography(
      title: [Bibliography],
      (
        references: bib_refs.filter(ref => ref.details.type != "book"),
        ..bib_info,
      ),
    )

    render-bibliography(
      title: [Books],
      (
        references: bib_refs.filter(ref => ref.details.type == "book"),
        ..bib_info,
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
)
