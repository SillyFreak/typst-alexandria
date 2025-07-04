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

_Alexandria_ enables multiple bibliographies in the same Typst document.

#ref-fn("alexandria()") function declares that a group of bibliographical entries will be associated with a user-specified prefix (e.g. `x-`).
Now, to reference an entry from a specific group, one has to add its prefix (e.g. `@x-quark` instead of `@quark`).
The document may contain multiple #ref-fn("alexandria()") calls that declare multiple bibliographical groups, each with its own unique prefix.
Importantly, #ref-fn("alexandria()") has to be called before any of its bibliographical entries are referenced in the document.
#ref-fn("bibliographyx()") function is an extension of Typst-native #ref-fn("bibliography()") function that generates a bibliography limited to a specific prefix.

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
- Native bibliographies have `numbering: none` applied to its title, while Alexandrias' haven't. ```typc show bibliography: set heading(...)``` also won't work on them.
- Citations that are shown as footnotes are not supported yet -- see #link("https://github.com/SillyFreak/typst-alexandria/issues/11")[issue \#11].

If you find additional limitations or other issues, please report them at https://github.com/SillyFreak/typst-alexandria/issues.

The example on the next page demonstrates using separate bibliographies with independent numbering for different parts of a document:
- @ex-native[Example] used the native bibliography
- @ex-apa[Example] used Alexandria to show APA style references
- @ex-ieee[Example] showed a numbered IEEE style.

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

The previous example demonstrated how to use Alexandria to create separate bibliographies for different parts of a document, each with its own independent numbering.
This approach is not suitable for generating multiple bibliographies that serve the same region of a document and have non-overlapping numbering.
For this purpose, Alexandria allows you to specify the references that go into each bibliography list. To do this, instead of a single #ref-fn("bibliographyx()") call, you split _loading_, _collecting_ and _rendering_ bibliographical references:
- #ref-fn("load-bibliography()") loads all bibliographical entries
- #ref-fn("get-bibliography()") composes a list of entries actually referenced in the document
- #ref-fn("render-bibliography()") renders the list of bibliographical entries. You can call #ref-fn("render-bibliography()") multiple times, providing different subsets of the list generated at the previous step.

An example typst code could look like this:

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

Note how all references are rendered once, although in a different presentation from usual. This is generally a requirement for citations being able to refer to their corresponding reference's label. In this particular case, this is not a concern since there are no citations and references were rendered due to the #ref-fn("load-bibliography.full") option, but in general this is a concern.

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
)
