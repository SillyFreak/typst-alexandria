#let _p = plugin("alexandria.wasm")

/// The identity function
///
/// #example(mode: "markup", ```typ
/// #alexandria.process("hello")
/// ```)
///
/// - x (str): some parameter
/// -> str
#let process(x) = {
  cbor.decode(_p.process(cbor.encode(x)))
}
