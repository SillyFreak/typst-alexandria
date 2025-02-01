#let _p = plugin("alexandria.wasm")

#let alexandria(
  prefix: none,
  read: none,
) = body => {
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

  body
}

#let bibliography(
  path,
  title: auto,
  full: false,
  style: "ieee",
) = {
  assert.ne(title, auto, message: "automatic title is not yet supported")
  assert.eq(full, true, message: "only full bibliographies are currently supported")
  assert.eq(style, "ieee", message: "only ieee style is currently supported")

  if title != none {
    [= #title]
  }

  context {
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
