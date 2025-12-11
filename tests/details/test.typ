#import "../test-utils.typ": *

#show: x-alexandria

#x-test-citations

#x-bib(
  title: "Bibliography",
)

#context {
  let details = get-bibliography("x:").references.find(x => x.key == "tolkien54").details
  assert.eq(details, (
    type: "book",
    title: "The Fellowship of the Ring",
    author: "Tolkien, J. R. R.",
    date: "1954-07-29",
    publisher: (name: "Allen & Unwin", location: "London"),
    volume: 1,
    parent: (type: "book", title: "The Lord of the Rings"),
  ))
}
