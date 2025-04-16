#let config = state("__alexandria-config", (
  prefixes: (:),
  read: none,
))
#let bibliographies = state("__alexandria-bibliographies", (:))

#let set-read(read) = config.update(x => {
  x.read = read
  x
})

#let read(data) = {
  if type(data) == bytes {
    (path: none, data: str(data))
  } else if type(data) == str {
    let read = config.get().read
    assert.ne(read, none, message: "Alexandria is not configured. Make sure to use `#show: alexandria(...)`")
    (path: data, data: read(data))
  } else {
    panic("parameter must be a path string or data bytes")
  }
}

#let register-prefix(..prefixes) = {
  assert.eq(prefixes.named().len(), 0)
  let prefixes = prefixes.pos()

  config.update(x => {
    for prefix in prefixes {
      x.prefixes.insert(prefix, (
        citations: (),
      ))
    }
    x
  })

  bibliographies.update(x => {
    for prefix in prefixes {
      x.insert(prefix, none)
    }
    x
  })
}

#let get-citation-index(prefix) = {
  config.get().prefixes.at(prefix).citations.len()
}

#let add-citation(prefix, citation) = config.update(x => {
  x.prefixes.at(prefix).citations.push((citation,))
  x
})

#let get-only-prefix() = {
  let prefixes = config.get().prefixes
  if prefixes.len() != 1 {
    return none
  }
  prefixes.keys().first()
}

#let set-bibliography(prefix, hayagriva) = {
  let config = config.final().prefixes.at(prefix)
  bibliographies.update(x => {
    if x.at(prefix) == none {
      x.at(prefix) = (prefix: prefix, ..hayagriva(config.citations))
    }
    x
  })
}

#let get-bibliography(prefix) = bibliographies.final().at(prefix)
#let get-citation(prefix, index) = get-bibliography(prefix).citations.at(index)
