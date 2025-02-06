///[skip]

/// not entirely sure why this fails; seems like there is a rendering inconsistency between plain
/// "(Aldrin, n.d.)" and the same text produced by a citation.

#import "../test-utils.typ": *

#show: x-alexandria

#x-test-citations

#x-bib(
  title: "Bibliographie",
  // full: true,
  style: "apa",
)
