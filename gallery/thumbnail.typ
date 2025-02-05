#import "/src/lib.typ" as alexandria: *

#set document(date: none)
#set page(width: 16cm, height: auto, margin: 5mm, columns: 2)
#set columns(gutter: 3mm)
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

#example-table(<netwok>)

#bibliography(
  "bibliography.bib",
  // full: true,
)

#colbreak()

= Alexandria

#example-table(<x-netwok>)

#bibliographyx(
  "bibliography.bib",
  title: "Bibliography",
  // full: true,
  // style: "ieee",
)
