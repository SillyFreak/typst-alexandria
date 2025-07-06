#let _p = plugin("alexandria.wasm")

#let names = {
  // Typst 0.13: `cbor.decode` is deprecated, directly pass bytes to `cbor` instead
  let decode = if sys.version < version(0, 13, 0) { cbor.decode } else { cbor }

  decode(_p.names())
}

#let locale() = {
  let locale = text.lang
  if text.region != none { locale += "-" + text.region }
  locale
}

#let csl-to-string(csl) = {
  if type(csl) in (str, bytes) { return csl }

  let csl = repr(csl).slice(1, -1)
  assert.ne(csl, "..", message: "only named CSL styles can be converted to strings")
  csl
}

#let read(
  sources,
  full,
  style,
  locale,
  citations,
) = {
  // Typst 0.13: `cbor.decode` is deprecated, directly pass bytes to `cbor` instead
  let decode = if sys.version < version(0, 13, 0) { cbor.decode } else { cbor }

  let config = cbor.encode((sources: sources, full: full, style: style, locale: locale, citations: citations))
  decode(_p.read(config))
}

#let render(body, keys: none, ..transparent-contents) = {
  assert.eq(transparent-contents.named().len(), 0, message: "no named arguments allowed")
  let transparent-contents = transparent-contents.pos()
  let formatted(fmt) = it => {
    set text(style: "italic") if fmt.font-style == "italic"
    // TODO this is an absolute weight and not an offset
    set text(weight: "bold") if fmt.font-weight == "bold"
    set text(weight: "light") if fmt.font-weight == "light"
    if fmt.font-variant == "small-caps" {
      it = smallcaps(it)
    }
    if fmt.text-decoration == "underline" {
      it = underline(it)
    }
    if fmt.vertical-align == "sup" {
      it = h(0pt, weak: true) + super(it)
    } else if fmt.vertical-align == "sub" {
      it = h(0pt, weak: true) + sub(it)
    }
    it
  }

  let inner(body) = {
    if type(body) == array {
      body.map(inner).join()
    } else if "text" in body {
      let body = body.text
      show: formatted(body)
      body.text
    } else if "elem" in body {
      let body = body.elem
      show: it => {
        if "reference" in body.meta {
          assert.ne(keys, none, message: "Alexandria: internal error: citation keys are missing")
          assert(body.meta.reference < keys.len(), message: "Alexandria: internal error: unmatched key in citegroup")
          let entry = keys.at(body.meta.reference)
          it = link(entry, it)
        }
        it
      }
      // TODO handle body.display when present
      inner(body.children)
    } else if "link" in body {
      let body = body.link
      show: formatted(body)
      link(body.url, body.text)
    } else if "transparent" in body {
      let body = body.transparent
      show: formatted(body)
      assert(body.cite-idx < transparent-contents.len(), message: "Alexandria: internal error: unmatched transparent content")
      transparent-contents.at(body.cite-idx)
    } else {
      set text(red)
      repr(body)
    }
  }
  inner(body)
}
