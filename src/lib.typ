#import "hayagriva.typ"

#let citation(prefix, key, form: "normal", style: auto, supplement: auto) = {
  import "state.typ"
  import "hayagriva.typ"

  context {
    let (citegroup_index, continue_citegroup) = state.current-citegroup-index()
    state.add-citation((
      key: key,
      prefix: prefix,
      form: form,
      ..if style != auto { (style: hayagriva.csl-to-string(style)) },
      supplement: supplement,
      locale: hayagriva.locale(),
    ))

    if not continue_citegroup {
      context {
        let content = state.get-citegroup-content(citegroup_index)
        if content != none {
          let (body, supplements) = content
          hayagriva.render(
            body,
            keys: (key,),
            ..supplements,
          )
        }
      }
    }
  }
}

/// Sets the default prefix for Alexandria references and citations.
///
/// ```typ
/// #alexandria-prefix(prefix: "x")
/// ```
///
/// - prefix (string | none): the default prefix to use for the Alexandria references and citations.
/// -> state
#let alexandria-prefix(
  prefix
) = {
  import "state.typ"

  if prefix == none or type(prefix) == str {
    state.default-prefix.update(x => prefix)
  } else {
    panic("prefix must be none or string, " + str(type(prefix)) + " provided")
  }
}

/// This configuration function should be called as a show rule at the beginning of the document.
/// It enables customized processing of the `ref()` and `cite()` commands.
///
/// ```typ
/// #show: alexandria(("books.bib", "papers.bib"), prefix: "x", reader: path => read(path))
/// ```
/// The `reader` parameter can be skipped, in which case the function will expect that `sources`
/// are the raw `bytes` file contents.
///
/// -> function
#let alexandria(
  /// The path to or binary file contents of the bibliography file(s).
  /// -> string | bytes | array
  sources,
  /// The delimiter that separates the prefix from the bibliographic key in the #ref-fn("cite()") command
  /// -> string | none
  prefix-delim: "-",
  /// pass ```typc path => read(path)``` into this parameter so that Alexandria can read your
  /// bibliography files.
  /// -> function
  reader: none,
  /// The default prefix to apply to citations that do not specify it explicitly.
  /// See #ref-an("alexandria-prefix()")
  /// -> string | none | auto
  prefix: auto
) = body => {
  import "state.typ"

  // assert.ne(reader, none, message: "reader is required; provide a function `sources => read(sources)`")
  if prefix != auto {
    alexandria-prefix(prefix)
  }
  let sources_ = if type(sources) == bytes or type(sources) == str {
    (sources,)
  } else if type(sources) == array {
    assert(sources.all(x => type(x) in (str, bytes)),
           message: "sources must be a string, bytes or an array of strings or bytes")
    sources
  } else {
    panic("sources must be a string, bytes or an array of strings or bytes")
  }
  state.bib-sources.update(x => {
    (sources: sources_, reader: reader, prefix-delim: prefix-delim)
  })

  show ref: it => {
    context {
      let prefix_match = state.match-prefix(it.target, prefix-delim)
      if prefix_match == none {
        return it
      }
      let (prefix, target) = prefix_match

      citation(
        prefix, target,
        form: cite.form, style: cite.style,
        supplement: if it.supplement != auto { it.supplement },
      )
    }
  }

  show cite: it => {
    context {
      let prefix_match = state.match-prefix(it.key, prefix-delim)
      if prefix_match == none {
        return it
      }
      let (prefix, key) = prefix_match

      citation(
        prefix, key,
        form: it.form, style: it.style,
        supplement: it.supplement,
      )
    }
  }

  // any non-whitespace content end the citation group
  // // FIXME does not work + seems slow, any other way to do this?
  // show regex("\S+"): it => {
  //   state.citations.update(x => {
  //     x.lastgroup-open = false
  //     x
  //   })
  //   it
  // }

  body
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
  import "state.typ"

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

  state.start-citation-group()
  // don't use the body since that may contain whitespace
  // the citations themselves won't render as anything, so they're fine
  children.join()
  context {
    let (citegroup_index, _) = state.current-citegroup-index()
    let (body, supplements) = state.get-citegroup-content(citegroup_index)
    hayagriva.render(
      body,
      keys: children.map(x => {
        if x.func() == ref { x.target }
        else if x.func() == cite { x.key }
      }),
      ..supplements,
    )
  }
  state.end-citation-group()
}


/// Assembles a list of citations that reference specified prefixes and prepares the citations
/// and bibliographical references for rendering by #ref-fn("render-bibliography()").
///
/// -> content
#let collect-citations(
  /// The unique identifier to assign to the collection.
  /// -> string
  id,
  /// The filter for the citation prefixes to include into this list.
  /// Could be a single prefix, an array of prefixes or a function that gets the prefix and returns true
  /// if it has to be included.
  /// `auto` filters by the default prefix set by #ref-an("alexandria-prefix()"),
  /// and `none` instructs to accept all prefixes.
  /// -> string | array | function | auto | none
  prefix-filter: auto,
  /// The style of the bibliography. Either a #link("https://typst.app/docs/reference/model/bibliography/#parameters-style")[built-in style],
  /// a file name that is read by the `read()` function registered via #ref-fn("alexandria()"), or binary
  /// file contents of a CSL file.
  /// -> string | bytes
  style: "ieee",
) = {
  import "state.typ"
  import "hayagriva.typ"

  let style_ = {
    let s_ = hayagriva.csl-to-string(style)
    if s_ in hayagriva.names {
      (built-in: s_)
    } else {
      (custom: if (type(s_) == bytes) { str(s_) } else { read(s_) })
    }
  }

  context {
    let prefix_filter_ = if prefix-filter == none {
      (x) => true  // no prefix filter
    } else if prefix-filter == auto {
      let def_prefix = state.default-prefix.final()
      if def_prefix != none {
        (x) => str(x).starts-with(def_prefix)
      } else {
        (x) => true  // no prefix filter
      }
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

    let locale = hayagriva.locale()

    state.collect-and-process-citations(id,
      citation => prefix_filter_(citation.prefix),
      (citations, sources) => hayagriva.read(
        sources,
        false,
        style_,
        locale,
        citations.map((group) => group.map(((supplement, ..citation)) => {
            let has-supplement = supplement != none
            (..citation, has-supplement: has-supplement)
          })
        )
    ))
  }
}

/// Renders the subset of the bibliographical references from the list generated by the
/// `collect-citations()` call.
///
/// -> content
#let render-bibliography(
  /// The unique identifier of the list created by `collect-citations()`
  /// -> string
  id,
  /// The function to filter the references. It receives a reference as an input
  /// and should return true if the reference has to be included.
  /// The reference has a `prefixes` field, which is an array of all prefixes that
  /// are used in the citations (from the `id` list) referencing this entry.
  /// The `details` field contains the actual information about the reference.
  /// -> none | function
  filter: none,
  /// The title of the bibliography. Note that `auto` is currently not supported.
  /// -> none | content | auto
  title: auto,
) = {
  import "state.typ"

  assert.ne(title, auto, message: "automatic title is not yet supported")

  if title != none {
    [= #title]
  }

  context {
    let bib = state.citation-collections.final().at(id)

    let refs = if filter != none {
      bib.references.filter(filter)
    } else {
      bib.references
    }

    set par(hanging-indent: 1.5em) if bib.hanging-indent

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
///   style: "ieee",
/// )
/// ```
///
/// The function is a simple wrapper that calls @@collect-citations() and @@render-bibliography()
/// to render the bibliographic list for a specific prefix without modifications.
///
/// -> content
#let bibliographyx(
  /// The prefix for which reference labels should be provided and citations should be processed.
  /// -> string | auto
  prefix: auto,
  /// The title of the bibliography. Note that `auto` is currently not supported.
  /// -> none | content | auto
  title: auto,
  /// pass ```typc path => read(path)``` into this parameter so that Alexandria can read your
  /// bibliography files.
  /// -> function
  reader: none,
  /// The style of the bibliography.
  /// -> string | bytes
  style: "ieee",
) = {
  collect-citations(prefix, prefix-filter: prefix, style: style)
  render-bibliography(prefix, filter: ref => ref.prefixes.contains(prefix), title: title)
}
