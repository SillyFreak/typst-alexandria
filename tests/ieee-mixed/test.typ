///[skip]

/// https://github.com/typst/typst/issues/5826#issuecomment-2641000784

#import "../test-utils.typ": *

#show: x-alexandria

#x-test-citations

#{
  set text(lang: "de")
  x-test-citations
}

#{
  set cite(style: "apa")
  // show "(": it => it + box()
  x-test-citations
}

#{
  set text(lang: "de")
  set cite(style: "apa")
  // show "(A": it => "(" + box() + "A"
  x-test-citations
}

#x-bib(
  title: "Bibliography",
  full: true,
  style: "ieee",
)
