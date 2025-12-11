/// https://github.com/typst/typst/issues/5826#issuecomment-2641000784

#import "../test-utils.typ": *

#show: x-alexandria

#x-test-citations-no-misc

#x-bib(
  title: "Bibliography",
  // full: true,
  style: "chicago-notes",
)
