#import "/src/lib.typ" as alexandria: *

#set page(height: auto, margin: 5mm, fill: none)

// style thumbnail for light and dark theme
#let theme = sys.inputs.at("theme", default: "light")
#set text(white) if theme == "dark"

#set page(columns: 2)
#set columns(gutter: 6mm)
#set par(justify: true)

#show: alexandria(prefix: "x-", read: path => read(path))

#let example-table(
  key,
  style: auto,
  ..forms,
) = {
  assert.eq(forms.named().len(), 0)
  let forms = forms.pos()
  if forms.len() == 0 {
    forms = ("plain", "normal", "prose", "full", "author", "year")
  }

  table(
    columns: (auto, 1fr),
    inset: 1mm,
    align: (right, left),
    stroke: none,

    ..for form in forms {
      let (first, ..rest) = form.clusters()
      let label = (upper(first), ..rest).join()
      let citation = if form == "plain" {
        ref(key)
      } else {
        cite(key, form: form, style: style)
      }
      ([#label:], citation)
    }
  )
}

= Regular Bibliography

_IEEE style citations in German_

#text(lang: "de", example-table(<netwok>))

_APA style citations in English_

#example-table(<netwok>, "normal", "prose", "full", "author", "year", style: "apa")

#bibliography(
  "bibliography.bib",
  // full: true,
  // style: "apa",
)

#colbreak()

= Alexandria

_IEEE style citations in German_

#text(lang: "de", example-table(<x-netwok>))

_APA style citations in English_

#example-table(<x-netwok>, "normal", "prose", "full", "author", "year", style: "apa")

#bibliographyx(
  "bibliography.bib",
  title: "Bibliography",
  // full: true,
  // style: "apa",
)
