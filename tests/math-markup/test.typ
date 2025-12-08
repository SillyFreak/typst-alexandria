#import "../test-utils.typ": *
#show: alexandria.alexandria(prefix: "x-", read: path => read(path))

#bibliographyx(
  "refs.yaml",
  title: "Bibliography",
  full: true,
)
