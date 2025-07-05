#import "hayagriva.typ"

#let citation(prefix, key, form: "normal", style: auto, supplement: auto) = {
  import "state.typ": *
  import "hayagriva.typ": csl-to-string, locale

  let citegroup_index = get-citegroup-index()
  context add-citation((
    key: key,
    prefix: prefix,
    form: form,
    ..if style != auto { (style: csl-to-string(style)) },
    supplement: supplement,
    locale: locale(),
  ))
  if citegroup_index >= 0 {
    context {
      let (coll_id, incoll_index) = citegroup-to-collection.final().at(citegroup_index)
      let (body, supplements) = get-citation(coll_id, incoll_index, citegroup_index)
      hayagriva.render(
        body,
        keys: (key,),
        ..supplements,
      )
    }
  }
}

/// This configuration function should be called as a show rule at the beginning of the document.
/// The function makes sure that `ref()` and `cite()` commands can refer to Alexandria's custom
/// bibliography entries and stores configuration for use by @@load-bibliography().
///
/// ```typ
/// #show: alexandria(prefix: "x-", read: path => read(path))
/// ```
///
/// The `read` parameter can be skipped, in which case file paths can not be used for bibliography
/// files and custom styles. This means you will need to pass `bytes` values to @@bibliographyx()
/// and @@load-bibliography() instead of paths.
///
/// -> function
#let alexandria(
  /// The path to or binary file contents of the bibliography file(s).
  /// -> string | bytes | array
  sources,
  // -> string | none
  prefix-delim: "-",
  /// pass ```typc path => read(path)``` into this parameter so that Alexandria can read your
  /// bibliography files.
  /// -> function
  reader: none,
) = body => {
  import "state.typ": *

  // assert.ne(reader, none, message: "reader is required; provide a function `sources => read(sources)`")
  bib-sources.update(x => {
    (sources: sources, reader: reader, prefix-delim: prefix-delim)
  })

  show ref: it => {
    let prefix_match = match-prefix(prefix-delim, it.target)
    if prefix_match == none {
      return it
    }
    let (prefix, key) = prefix_match

    citation(
      prefix, key,
      form: cite.form, style: cite.style,
      supplement: if it.supplement != auto { it.supplement },
    )
  }

  show cite: it => {
    let prefix_match = match-prefix(prefix-delim, it.key)
    if prefix_match == none {
      return it
    }
    let (prefix, key) = prefix_match

    context citation(
      prefix, key,
      form: it.form, style: it.style,
      supplement: it.supplement,
    )
  }

  body
}

#let alexandria-prefix(
  prefix: none
) = {
  if prefix == none or type(prefix) == str {
    default-prefix.update(x => prefix)
  } else {
    panic("prefix must be none or string, " + str(type(prefix)) + " provided")
  }
}

/// Creates a group of collapsed citations. The citations are given as regular content, e.g.
/// ```typ
/// #citegroup[@a @b]
/// ```
/// Only citations, references and spaces may appear in the body. Whitespace is ignored, and the
/// rest is treated as a group of citations to collapse. It is an error to have non-alexandria
/// references, or references from different bibliographies, in the same citation group.
///
/// -> content
#let citegroup(
  /// The body, containing at least one but usually more citations
  /// -> content
  body,
) = {
  import "state.typ": *

  assert(
    type(body) == content and body.func() in ([].func(), ref, cite),
    message: "citegroup expected one or more citations in the form of content",
  )
  let children = if body.func() == [].func() {
    body.children
  } else {
    (body,)
  }.filter(x => x.func() != [ ].func())
  assert(
    children.all(x => x.func() in (ref, cite)),
    message: "citegroup expected a body consisting only of citations and references",
  )

  start-citation-group()
  // don't use the body since that may contain whitespace
  // the citations themselves won't render as anything, so they're fine
  children.join()
  context {
    let citegroup_index = get-citegroup-index()
    let (coll_id, incoll_index) = citegroup-to-collection.final().at(citegroup_index)
    let (body, supplements) = get-citation(coll_id, incoll_index, citegroup_index)
    hayagriva.render(
      body,
      keys: children.map(x => {
        if x.func() == ref { x.target }
        else if x.func() == cite { x.key }
      }),
      ..supplements,
    )
  }
  end-citation-group()
}


/// Returns a previously loaded bibliography. This is used implicitly by @@bibliographyx() and
/// Alexandria citations to retrieve rendered data, and can be used directly for more complex use
/// cases. Usually, the returned data will be ultimately rendered using @@render-bibliography().
///
/// The result is a dictionary with the following keys:
/// - `prefix`: the string prefix used by Alexandria to identify this bibliography (and passed to
///   this function), used as a prefix for all labels rendered by Alexandria.
/// - `references`: an array of reference dictionaries which can be rendered into a bibliography.
///   The array is sorted by the appearance of references according to the style used.
/// - `citations`: an array of citations dictionaries which can be rendered into the various
///   citations in the document. The array is sorted by the appearance of citations in the document.
/// - `hanging-indent`: a boolean indicating whether the citation style uses a hanging indent for
///   its entries.
///
/// The `references` in turn each contain
/// - `key`: the reference key without prefix.
/// - `reference`: a representation of the Typst content that should be rendered; this is processed
///   by @@render-bibliography() to produce the actual context.
/// - optionally `prefix`: this is _not_ the Alexandria prefix but another Typst content
///   representation for styles that require it. For example, in IEEE style this would represent
///   "[1]" and so on.
/// - `details`: a dictionary containing several fields of structured data about the reference.
///   Among these are `type`, `title`, `author`, `date`, etc. A full list can be found in the
///   #link("https://github.com/typst/hayagriva/blob/main/docs/file-format.md")[Hayagriva docs].
///
/// The `citations` are representations of the Typst content that should be rendered at their
/// respective citation sites.
///
/// This function is contextual.
///
/// -> dict
#let collect-citations(
  id,
  /// The prefix or an array of prefixes for which the bibliography should be retrieved,
  /// or `auto` if there is only one bibliography and that one should be retrieved.
  /// -> string | array | function | auto
  prefix-filter: auto,
  /// The style of the bibliography. Either a #link("https://typst.app/docs/reference/model/bibliography/#parameters-style")[built-in style],
  /// a file name that is read by the `read()` function registered via @@alexandria(), or binary
  /// file contents of a CSL file.
  /// -> string | bytes
  style: "ieee",
) = {
  import "state.typ": *
  import "hayagriva.typ": csl-to-string, locale, read

  let prefix_filter = if prefix-filter == auto {
    (x) => true
  } else if type(prefix-filter) == str {
    (x) => str(x) == prefix-filter
  } else if type(prefix-filter) == array {
    assert(prefix-filter.all(x => type(x) == str),
           message: "prefixes must be a string, an array of strings or a regex")
    (x) => str(x) in prefix-filter
  } else if type(prefix-filter) == regex {
    (x) => {
      let m = str(x).match(prefix-filter)
      m != none and m.start == 0
    }
  } else if type(prefix-filter) == function {
    prefix-filter
  } else {
    assert(type(prefix-filter), array, message: "prefixes must be a string, an array of strings or a regex")
    prefix-filter
  }

  let style = csl-to-string(style)
  if style in hayagriva.names {
    style = (built-in: style)
  } else {
    style = (custom: read(style).data)
  }

  let locale = locale()

  collect-and-process-citations(id,
    citation => prefix_filter(citation.prefix),
    (citations, sources) => hayagriva.read(
      sources,
      false,
      style,
      locale,
      citations.map((group) => group.map(((supplement, ..citation)) => {
          let has-supplement = supplement != none
          (..citation, has-supplement: has-supplement)
        })
      )
  ))
}

/// Renders the provided bibliography data (as returned by @@get-bibliography();) with the given
/// title. For simple use cases, @@bibliographyx() can be used directly, which also handles the data
/// retrieval.
///
/// You will usually only need to call this directly if you _don't_ pass the exact return value of
/// @@get-bibliography() as an argument. Instead, you'll want to preprocess that data, e.g. by
/// filtering out some `references` entries that should appear elsewhere in the document. Note that
/// generally, you'll need to ultimately render all references, or you'll get unresolved citations.
///
/// -> content
#let render-bibliography(
  /// The bibliography data
  /// -> string
  id,
  /// -> none | function
  filter: none,
  /// The title of the bibliography. Note that `auto` is currently not supported.
  /// -> none | content | auto
  title: auto,
) = {
  import "state.typ": citation-collections

  assert.ne(title, auto, message: "automatic title is not yet supported")

  if title != none {
    [= #title]
  }

  let bib = citation-collections.final().at(id)

  set par(hanging-indent: 1.5em) if bib.hanging-indent

  let refs = if filter != none {
    bib.references.filter(filter)
  } else {
    bib.references
  }
  if refs.any(e => e.first-field != none) {
    grid(
      columns: 2,
      // rows: (),
      column-gutter: 0.65em,
      // row-gutter: 13.2pt,
      row-gutter: par.spacing,
      // fill: none,
      // align: auto,
      // stroke: (:),
      // inset: (:),
      ..for e in refs {
        (
          {
            [#metadata(none)#label(bib.id + e.key)]
            if e.first-field != none {
              hayagriva.render(e.first-field)
            }
          },
          hayagriva.render(e.content),
        )
      },
    )
  } else {
    let gutter = v(par.spacing, weak: true)
    for (i, e) in refs.enumerate() {
      if i != 0 { gutter }
      [#metadata(none)#label(bib.id + e.key)]
      hayagriva.render(e.content)
    }
  }
}

/// Renders an additional bibliography. The interface is similar to the built-in
/// #link("https://typst.app/docs/reference/model/bibliography/")[`bibliography()`], but not all
/// features are supported (yet). In particular, the default values reflect `bibliography()`, but
/// some of these are not supported yet and need to be set manually.
///
/// ```typ
/// #bibliographyx(
///   "bibliography.bib",
///   title: "Bibliography",
///   full: true,
///   style: "ieee",
/// )
/// ```
///
/// This function is based on @@load-bibliography(), @@get-bibliography(), and
/// @@render-bibliography() and simply reproduces the rendering of the built-in bibliography without
/// modification.
///
/// -> content
#let bibliographyx(
  /// The path to or binary file contents of the bibliography file(s).
  /// -> string | bytes | array
  path,
  /// The prefix for which reference labels should be provided and citations should be processed.
  /// -> string | auto
  prefix: auto,
  /// The title of the bibliography. Note that `auto` is currently not supported.
  /// -> none | content | auto
  title: auto,
  /// Whether to render the full bibliography or only the references that are used in the document.
  /// -> boolean
  full: false,
  /// The style of the bibliography.
  /// -> string | bytes
  style: "ieee",
) = {
  bibliography-source(path, prefix: prefix, full: full)

  context {
    let bib = collect-and-process-citations(id: prefix, prefix-filter: prefix, style: style)
    render-bibliography(bib, title: title)
  }
}
