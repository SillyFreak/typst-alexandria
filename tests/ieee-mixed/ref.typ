#import "../test-utils.typ": *

#test-citations

#{
  set text(lang: "de")
  test-citations
}

#{
  set cite(style: "apa")
  test-citations
}

#{
  set text(lang: "de")
  set cite(style: "apa")
  test-citations
}

#bib(
  // title: "Bibliography",
  full: true,
  style: "ieee",
)
