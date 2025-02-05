#let _p = plugin("alexandria.wasm")

#let read(
  sources,
  style,
  locale,
) = {
  let config = cbor.encode((sources: sources, style: style, locale: locale))
  cbor.decode(_p.read(config))
}
