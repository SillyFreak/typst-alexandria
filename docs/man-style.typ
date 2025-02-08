// adapted from https://github.com/Mc-Zen/tidy/blob/v0.3.0/src/styles/minimal.typ

// ==== internal utilities

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

#let preview-block(no-codly: true, ..args) = {
  import "template.typ": codly

  show: if no-codly { codly.no-codly } else { it => it }
  block(
    stroke: 0.5pt + luma(200),
    radius: preview-radius,
    ..args
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
  box(outset: 2pt, fill: get-type-color(type), radius: 2pt, raw(type, lang: none))
  h(2pt)
}

#let show-function(
  fn, style-args,
) = {
  import "template.typ": tidy
  import tidy.utilities: *

  block(breakable: style-args.break-param-descriptions, {
    let parameter-list = (style-args.style.show-parameter-list)(fn, style-args)
    let lbl = if style-args.enable-cross-references {
      label(style-args.label-prefix + fn.name + "()")
    }
    [#parameter-list #lbl]
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
    )
  })

  if args.len() != 0 {
    [*#style-args.local-names.parameters:*]
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
) = block(
  breakable: style-args.break-param-descriptions,
  inset: 0pt, width: 100%,
  {
    set par(hanging-indent: 1em, first-line-indent: 0em)
    mono(name)
    [ (]
    show-types(types, style-args, joiner: [ #text(size: 0.6em)[or] ])
    if show-default [ \= #raw(lang: "typc", default)]
    [) -- ]
    content
  }
)

#let show-reference(label, name, style-args: none) = {
  link(label, raw(name, lang: none))
}

#let show-variable(
  var, style-args,
) = {
  import "template.typ": tidy
  import tidy.utilities: *

  signature-block(breakable: style-args.break-param-descriptions, {
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

// Adapted from https://github.com/Mc-Zen/tidy/blob/v0.3.0/src/show-example.typ
// see discussion here: https://discord.com/channels/1054443721975922748/1296208677371379813

/// Takes given code and both shows it and previews the result of its evaluation.
///
/// The code is by default shown in the language mode `lang: typc` (typst code)
/// if no language has been specified. Code in typst markup language (`lang: typ`)
/// is automatically evaluated in markup mode.
///
/// - code (raw): Raw object holding the example code.
/// - scope (dictionary): Additional definitions to make available for the evaluated
///          example code.
/// - scale-preview (auto, ratio): How much to rescale the preview. If set to auto, the the preview is scaled to fit the box.
/// - inherited-scope (dictionary): Definitions that are made available to the entire parsed
///          module. This parameter is only used internally.
#let show-example(
  code,
  dir: ltr,
  scope: (:),
  preamble: "",
  ratio: 1,
  scale-preview: auto,
  mode: "code",
  inherited-scope: (:),
  code-block: block,
  preview-block: preview-block,
  col-spacing: 5pt,
  ..options
) = {
  set raw(block: true)
  let lang = if code.has("lang") { code.lang } else { "typc" }
  if lang == "typ" {
    mode = "markup"
  }
  if mode == "markup" and not code.has("lang") {
    lang = "typ"
  }
  set raw(lang: lang)
  if code.has("block") and code.block == false {
    code = raw(code.text, lang: lang, block: true)
  }

  let preview = {
    set heading(numbering: none, outlined: false)
    [#eval(preamble + code.text, mode: mode, scope: scope + inherited-scope)]
  }

  let preview-outer-padding = 3pt
  let preview-inner-padding = 5pt

  show: if dir.axis() == "vertical" { pad.with(x: 4%) } else { it => it }

  layout(size => {
    let code-width
    let preview-width

    if dir.axis() == "vertical" {
      code-width = size.width
      preview-width = size.width
    } else {
      code-width = ratio / (ratio + 1) * size.width - 0.5 * col-spacing
      preview-width = size.width - code-width - col-spacing
    }

    let available-preview-width = preview-width - 2 * (preview-outer-padding + preview-inner-padding)

    let preview-size
    let scale-preview = scale-preview

    if scale-preview == auto {
      preview-size = measure(preview)
      assert(preview-size.width != 0pt, message: "The code example has a relative width. Please set `scale-preview` to a fixed ratio, e.g., `100%`")
      scale-preview = calc.min(1, available-preview-width / preview-size.width) * 100%
    } else {
      preview-size = measure(block(preview, width: available-preview-width / (scale-preview / 100%)))
    }

    set par(hanging-indent: 0pt) // this messes up some stuff in case someone sets it


    // We first measure this thing (code + preview) to find out which of the two has
    // the larger height. Then we can just set the height for both boxes.
    let arrangement(width: 100%, height: auto) = {
      let code-block = code-block(
        width: code-width,
        height: height,
        {
          set text(size: .9em)
          pad(x: -4.3%, code)
        }
      )
      let preview-block = preview-block(
        height: height,
        width: preview-width,
        inset: preview-outer-padding,
        box(
          width: 100%,
          fill: white,
          inset: preview-inner-padding,
          scale(
            scale-preview,
            origin: top + left,
            block(preview, height: preview-size.height, width: preview-size.width)
          )
        )
      )

      show: block.with(
        width: width,
        inset: 0pt,
      )

      grid(
        ..if dir.axis() == "horizontal" {
          (columns: 2, rows: 1, column-gutter: col-spacing)
        } else {
          (columns: 1, rows: 2, row-gutter: col-spacing)
        },
        ..if dir in (ltr, ttb) {
          (code-block, preview-block)
        } else {
          (preview-block, code-block)
        }
      )
    }
    let height = if dir.axis() == "vertical" { auto }
      else { measure(arrangement(width: size.width)).height }
    arrangement(height: height)
  })
}
