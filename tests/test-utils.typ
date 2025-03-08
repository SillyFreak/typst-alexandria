#import "/src/lib.typ": *

#let bib-file = read("bibliography.bib", encoding: none)
#let csl-file = read("ieee.csl", encoding: none)

#let citations(..lbls) = for lbl in lbls.pos() [

  #ref(lbl)

  #cite(lbl, form: "prose")

  #cite(lbl, form: "full")

  #cite(lbl, form: "author")

  #cite(lbl, form: "year")
]

#let test-citations = citations(<tolkien54>, <distress>)

#let bib(..args) = bibliography("bibliography.bib", ..args)

#let x-alexandria = alexandria(prefix: "x-", read: path => read(path))

#let x-test-citations = citations(<x-tolkien54>, <x-distress>)

#let x-bib(..args) = bibliographyx("bibliography.bib", ..args)

#import "/src/lib.typ" as alexandria
