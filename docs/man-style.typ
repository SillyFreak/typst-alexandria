// adapted from https://github.com/Mc-Zen/tidy/blob/v0.3.0/src/styles/minimal.typ

// ==== internal utilities

// https://github.com/jneug/typst-mantys/blob/cb32c63394ef441eb6038d4090634c7d823b9e11/src/api/types.typ
/// Dictionary of builtin types, mapping the types name to its actual type.
#let _type-map = (
  "auto": auto,
  "none": none,
  // foundations
  arguments: arguments,
  array: array,
  bool: bool,
  bytes: bytes,
  content: content,
  datetime: datetime,
  decimal: decimal,
  dictionary: dictionary,
  duration: duration,
  float: float,
  function: function,
  int: int,
  label: label,
  module: module,
  regex: regex,
  selector: selector,
  string: str,
  symbol: symbol,
  type: type,
  version: version,
  // layout
  alignment: alignment,
  angle: angle,
  direction: direction,
  fraction: fraction,
  length: length,
  ratio: ratio,
  relative: relative,
  // visualize
  color: color,
  gradient: gradient,
  stroke: stroke,
  tiling: tiling,
  // introspection
  counter: counter,
  location: location,
  state: state,
)
/// Dictionary of allowed type aliases, like `dict` for `dictionary`.
#let _type-aliases = (
  boolean: "bool",
  str: "string",
  arr: "array",
  dict: "dictionary",
  integer: "int",
  func: "function",
)
#let _type-link-map = (
  "auto": "foundations/auto",
  "none": "foundations/none",
  // foundation
  arguments: "foundations/arguments",
  array: "foundations/array",
  bool: "foundations/bool",
  bytes: "foundations/bytes",
  content: "foundations/content",
  datetime: "foundations/datetime",
  decimal: "foundations/decimal",
  dictionary: "foundations/dictionary",
  duration: "foundations/duration",
  float: "foundations/float",
  function: "foundations/function",
  integer: "foundations/int",
  label: "foundations/label",
  module: "foundations/module",
  regex: "foundations/regex",
  selector: "foundations/selector",
  string: "foundations/str",
  symbol: "foundations/symbol",
  type: "foundations/type",
  version: "foundations/version",
  // layout
  alignment: "layout/alignment",
  angle: "layout/angle",
  direction: "layout/direction",
  fraction: "layout/fraction",
  length: "layout/length",
  ratio: "layout/ratio",
  relative: "layout/relative",
  // visualize
  color: "visualize/color",
  gradient: "visualize/gradient",
  stroke: "visualize/stroke",
  tiling: "visualize/tiling",
  // introspection
  counter: "foundations/counter",
  location: "foundations/location",
  state: "foundations/state",
)
#let type-link(t, body) = {
  if t in _type-aliases { t = _type-aliases.at(t) }
  if t in _type-link-map {
    link("https://typst.app/docs/reference/" + _type-link-map.at(t), body)
  } else {
    // probably a custom type
    body
  }
}

#let serif-font = "Libertinus Serif"
#let mono = text.with(font: "DejaVu Sans Mono", size: 0.85em, weight: 340)
#let name-fill = rgb("#1f2a63")
#let signature-fill = rgb("#d8dbed")
#let radius = 2pt
#let preview-radius = 0.32em

#let mono-fn(name, args: none, ret: none) = mono({
  text(name-fill, name)
  if args != none {
    let args = args.map(box)
    if args.len() <= 3 {
      "("
      args.join(", ")
      ")"
    } else {
      "(\n"
      args.map(arg => "  " + arg + ",").join("\n")
      "\n)"
    }
  }
  if ret != none {
    if args != none {
      box[~-> #ret]
    } else {
      box[: #ret]
    }
  }
})

#let get-type-color(type) = rgb("#eff0f3")

#let show-types(types, style-args, joiner: h(0.3em)) = {
  types.map(style-args.style.show-type.with(style-args: style-args)).join(joiner)
}

#let signature-block(..args) = {
  let bar-width = 1mm
  set par(justify: false)
  block(
    width: 100%,
    radius: radius,
    fill: signature-fill,
    stroke: (left: bar-width + name-fill),
    outset: (left: -bar-width / 2),
    inset: (x: 0.7em, y: 0.7em),
    ..args
  )
}

#let preview-block(body, no-codly: true, in-raw: true, ..args) = {
  import "template.typ": codly

  show: if no-codly { codly.no-codly } else { it => it }
  set heading(numbering: none, outlined: false)
  // counteract the font changes of raw blocks
  set text(font: serif-font, size: 1em/0.96) if in-raw

  block(
    pad(-2pt, body),
    stroke: 0.5pt + luma(200),
    radius: preview-radius,
    ..args
  )
}

#let layout-example(..args) = {
  import "template.typ": tidy, t4t
  import tidy.show-example as example

  example.default-layout-example(
    code-block: (body, ..args) => {
      // counteract the raw font size decrease of the template being applied twice
      set text(size: 1em/0.9)
      t4t.assert.no-pos(args)
      let args = args.named()
      _ = args.remove("inset", default: none)
      block(pad(x: -4.3%, body), ..args)
    },
    preview-block: preview-block,
    ..args,
  )
}

// ==== functions required from styles

#let show-outline(module-doc, style-args: (:)) = {
  let prefix = module-doc.label-prefix
  let gen-entry(name, args: none) = {
    let entry = mono-fn(name, args: args)
    if style-args.enable-cross-references {
      let lbl = prefix + name
      if args != none { lbl += "()" }
      entry = link(label(lbl), entry)
    }
    entry
  }
  let entries = (
    ..module-doc.functions.map(fn => gen-entry(fn.name, args: ())),
    ..module-doc.variables.map(var => gen-entry(var.name)),
  )

  show: block.with(sticky: true)
  grid(
    columns: (1fr,) * 3,
    column-gutter: 0.5em,
    ..if entries.len() != 0 {
      entries.chunks(calc.ceil(entries.len() / 3)).map(entries => {
        block(
          fill: gray.lighten(80%),
          width: 100%,
          inset: (y: 0.6em),
          radius: radius,
          list(..entries)
        )
      })
    },
  )
}

// Create beautiful, colored type box
#let show-type(type, style-args: (:)) = {
  h(2pt)
  type-link(type, {
    box(outset: 2pt, fill: get-type-color(type), radius: 2pt, raw(type, lang: none))
  })
  h(2pt)
}

#let show-function(
  fn, style-args,
) = {
  import "template.typ": tidy
  import tidy.utilities: *

  block(breakable: style-args.break-param-descriptions, sticky: true, {
    let parameter-list = (style-args.style.show-parameter-list)(fn, style-args)
    let lbl = if style-args.enable-cross-references {
      label(style-args.label-prefix + fn.name + "()")
    }
    [#parameter-list#lbl]
  })
  pad(x: 0em, eval-docstring(fn.description, style-args))

  let args = fn.args.pairs()
  if style-args.omit-private-parameters {
    args = args.filter(((arg-name, info)) => not arg-name.starts-with("_"))
  }
  if style-args.omit-empty-param-descriptions {
    args = args.filter(((arg-name, info)) => info.at("description", default: "") != "")
  }
  args = args.map(((arg-name, info)) => {
    let types = info.at("types", default: ())
    let description = info.at("description", default: "")
    (style-args.style.show-parameter-block)(
      arg-name, types, eval-docstring(description, style-args),
      style-args,
      show-default: "default" in info,
      default: info.at("default", default: none),
      function-name: style-args.label-prefix + fn.name,
    )
  })

  if args.len() != 0 {
    let parameters-string = get-local-name("parameters", style-args: style-args)
    [*#parameters-string:*]
    args.join()
  }
  v(4em, weak: true)
}

#let show-parameter-list(fn, style-args) = {
  signature-block(breakable: style-args.break-param-descriptions, {
    mono-fn(
      fn.name,
      args: {
        let args = fn.args.pairs()
        if style-args.omit-private-parameters {
          args = args.filter(((arg-name, info)) => not arg-name.starts-with("_"))
        }
        args = args.map(((arg-name, info)) => {
          if style-args.enable-cross-references and not (info.at("description", default: "") == "" and style-args.omit-empty-param-descriptions) {
            arg-name = link(label(style-args.label-prefix + fn.name + "." + arg-name.trim(".")), arg-name)
          }
          arg-name
          if "types" in info [: #show-types(info.types, style-args)]
        })
        args
      },
      ret: if fn.return-types != none { show-types(fn.return-types, style-args) },
    )
  })
}

// Create a parameter description block, containing name, type, description and optionally the default value.
#let show-parameter-block(
  name, types, content, style-args,
  show-default: false,
  default: none,
  function-name: none,
) = block(
  breakable: style-args.break-param-descriptions,
  inset: 0pt, width: 100%,
  {
    set par(hanging-indent: 1em, first-line-indent: 0em)
    let lbl = if function-name != none and style-args.enable-cross-references {
      label(function-name + "." + name.trim("."))
    }
    [#mono(name)#lbl]
    [ (]
    show-types(types, style-args, joiner: [ #text(size: 0.6em)[or] ])
    if show-default [ \= #raw(lang: "typc", default)]
    [) -- ]
    content
  }
)

#let show-reference(label, name, style-args: none) = {
  let (name, args) = if name.ends-with("()") {
    (name.slice(0, -2), ())
  } else {
    (name, none)
  }
  link(label, mono-fn(name, args: args))
}

#let show-variable(
  var, style-args,
) = {
  import "template.typ": tidy
  import tidy.utilities: *

  signature-block(breakable: style-args.break-param-descriptions, sticky: true, {
    let var-signature = mono-fn(
      var.name,
      ret: if "type" in var { (style-args.style.show-type)(var.type, style-args: style-args) },
    )
    let lbl = if style-args.enable-cross-references {
      label(style-args.label-prefix + var.name)
    }
    [#var-signature #lbl]
  })
  pad(x: 0em, eval-docstring(var.description, style-args))

  v(4em, weak: true)
}

#let show-example(no-codly: true, in-raw: true, ..args) = {
  import "template.typ": tidy
  import tidy.show-example as example

  example.show-example(
    layout: layout-example.with(
      preview-block: preview-block.with(no-codly: no-codly, in-raw: in-raw),
    ),
    ..args,
  )
}
