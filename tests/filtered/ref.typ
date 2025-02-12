#import "../test-utils.typ": *

#show bibliography: it => {
  show grid: it => {
    let (children, ..fields) = it.fields()

    let entries = children.chunks(2)

    if entries.len() != 10 { return it }

    let books = (
      entries.remove(5),  // [6]
      entries.remove(6),  // [8]
      entries.remove(7),  // [10]
    )

    grid(..fields, ..entries.join())

    [= Books]
    grid(..fields, ..books.join())
  }
  it
}

#bib(
  // title: "Bibliography",
  full: true,
)
