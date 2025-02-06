///[skip]

/// not entirely sure why this fails; seems like there is a rendering inconsistency between plain
/// "(Aldrin, n.d.)" and the same text produced by a citation.

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
