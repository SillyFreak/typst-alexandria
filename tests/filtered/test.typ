#import "../test-utils.typ": *

#show: x-alexandria

#alexandria.load-bibliography(
  "bibliography.bib",
  full: true,
)

#context {
  let (references, ..rest) =  get-bibliography("x-")

  alexandria.render-bibliography(
    title: [Bibliography],
    (
      references: references.filter(x => x.details.type != "book"),
      ..rest,
    ),
  )

  alexandria.render-bibliography(
    title: [Books],
    (
      references: references.filter(x => x.details.type == "book"),
      ..rest,
    ),
  )
}
