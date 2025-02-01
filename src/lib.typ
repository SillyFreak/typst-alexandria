#let _p = plugin("alexandria.wasm")

#let _config = state("alexandria-config", none)

/// This configuration function should be called as a function at the beginning of the document.
/// The function makes sure that `ref()` and `cite()` commands can refer to Alexandria's custom
/// bibliography entries and stores configuration for use by @@bibliographyx().
///
/// ```typ
/// #show: alexandria(prefix: "x-", read: path => read(path))
/// ```
///
/// - prefix (string): a prefix that identifies labels referring to Alexandria bibliographies.
///   Bibliography entries will automatically get that prefix prepended.
/// - read (function): pass ```typc path => read(path)``` into this parameter so that Alexandria can
///   read your bibliography files.
///
/// -> function
#let alexandria(
  prefix: none,
  read: none,
) = body => {
  assert.ne(prefix, none, message: "usage without a prefix is not yet supported")
  assert.ne(read, none, message: "read is required; provide a function `path => read(path)`")

  let match(key) = prefix == none or str(key).starts-with(prefix)

  show ref: it => {
    if not match(it.target) {
      return it
    }
    link(it.target, it.element.value.normal)
  }

  show cite: it => {
    if not match(it.key) {
      return it
    }
    link(it.key, context query(it.key).first().value.at(it.form))
  }

  _config.update((prefix: prefix, read: read))

  body
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
/// - path (string, array): The path to the bibliography file.
/// - title (none, content, auto): The title of the bibliography. Note that `auto` is currently not
///   supported.
/// - full (boolean): Whether to render the full bibliography or only the references that are used
///   in the document. Note that `true` is currently not supported.
/// - style (string): The style of the bibliography. Currently only `ieee` is supported.
///
/// -> content
#let bibliographyx(
  path,
  title: auto,
  full: false,
  style: "ieee",
) = {
  assert.ne(type(path), array, message: "multiple bibliography files are not yet supported")
  assert.ne(title, auto, message: "automatic title is not yet supported")
  assert.eq(full, true, message: "only full bibliographies are currently supported")
  assert.eq(style, "ieee", message: "only ieee style is currently supported")

  if title != none {
    [= #title]
  }

  context {
    let config = _config.get()
    assert.ne(config, none, message: "Alexandria is not configured. Make sure to use `#show: alexandria(...)`")
    let (prefix, read) = config

    // TODO multiple paths with arrays
    let bib = read(path)

    let bib-entry(key, ..forms) = {
      assert.eq(forms.pos().len(), 0)
      let forms = forms.named()
      [#metadata(forms)#key]
      forms.normal
    }
    let ieee-entry(key, num, authors, year, rest) = (
      bib-entry(
        key,
        normal: [[#num]],
        prose: [#authors [#num]],
        full: [[#num] #authors, #rest],
        author: [#authors],
        year: [#year],
      ),
      [#authors, #rest],
    )

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
      ..ieee-entry(
        <x-netwok>,
        1,
        [R. Astley and L. Morris],
        [2020],
        ["At-scale impact of the Net Wok: A culinarically holistic investigation of distributed dumplings," _Armenian Journal of Proceedings_, vol. 61, pp. 192--219, 2020.],
      ),
    )
  }
}
