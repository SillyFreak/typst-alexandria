#let bib-sources = state("__alexandria-bib-sources", (:))
#let citations = state("__alexandria-config", (
  groups: (),             // array of citation groups in the order they were added
                          // each group is an array of citations, which are tuples of (prefix: str, citation: str)
  lastgroup-open: false,  // if the current citation group is open
))
#let citegroup-collections = state("__alexandria-citegroup-collections", (:))
#let citegroup-to-collection = state("__alexandria-citegroup-to-collection", (:)) // map of group index to collection index

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

#let register-bib-source(prefix, prefix-delim : str, path, read, full: bool) = {
  assert(type(prefix) in (str, regex),
         message: "prefix must be a string or a regex")
  bib-sources.update(x => {
    x.insert(prefix, (prefix: prefix, prefix-delim: prefix-delim, path: path, read: read, full: full))
    x
  })
}

#let match-prefix(prefix, delim: str, key) = {
  if type(prefix) == str {
    if str(key).starts_with(prefix) {
      let prefix_val = prefix
      let key = str(key).slice(prefix.len())
    } else {
      return none
    }
  } else if type(prefix) == regex {
    let m = str(key).match(regex("^(" + prefix.regex + ")"))
    if m == none {
      return none
    } else {
      let prefix_val = m.at(0)
      let key = str(key).slice(m.end())
    }
  }
  if delim != none {
    // strip key of the prefix delimiter
    if not str(key).starts_with(delim) {
      return none
    }
    key = str(key).slice(delim.len())
  }
  (prefix_val, key)
}

#let start-citation-group() = citations.update(x => {
  assert.eq(
    x.lastgroup-open, false,
    message: "can't start a citation group while one is already open",
  )
  x.groups.push(()) // start a new citation group
  x.lastgroup-open = true
  x
})

#let add-citation(prefix, citation) = citations.update(x => {
  let prefixed_citation = (prefix: prefix, citation: citation)
  if x.lastgroup-open {
    // add a citation to the currently open group
    x.groups.last().push(prefixed_citation)
  } else {
    // add a new citation group with a single element
    x.groups.push((prefixed_citation,))
  }
  x
})

#let end-citation-group() = config.update(x => {
  assert.eq(
    x.lastgroup-open, true,
    message: "can't end a citation group when none is open",
  )
  assert.ne(
    x.groups.last().len(), 0,
    message: "citation group must not be empty",
  )
  x.lastgroup-open = false
  x
})

#let get-only-prefix() = {
  let bib-sources = bib-sources.get()
  if bib-sources.len() != 1 {
    return none
  }
  bib-sources.keys().first()
}

#let collect-and-process-citations(id, citation-filter, hayagriva) = {
  if type(prefixes) == str {
    prefixes = (prefixes,)
  } else {
    assert(type(prefixes), array, message: "prefix must be a string or an array of strings")
  }

  let collected_citations = ()
  let group_to_collection = (:)
  for (index, citation_group) in citations.final().groups.enumerate() {
    let ncollected = sum[citation-filter(citation) for citation in citation_group]
    if ncollected > 0 {
      assert.eq(
        ncollected, citation_group.len(),
        message: "collection should include all citations in a group or none, subsetting is not allowed"
      )
      group_to_collection[index] = (id, collected_citations.len())
      collected_citations.push((index, citation_group.map((prefix, citation) => citation)))
    }
  }

  citegroup-to-collection.update(x => {
    x += group_to_collection
    x
  })
  let processed_collection = hayagriva(collected_citations)
  citegroup-collections.update(x => {
    x.at(id) = processed_collection
    x
  })
  processed_collection
}

#let get-citegroup-index() = {
  let citations = citations.get()
  if not citations.lastgroup-open {
    citations.groups.len()
  } else {
    -1
  }
}

#let get-citation(collection-id, incollection-index) = {
  let citation = citegroup-collections.final().at(collection-id).at(incollection-index)
  let supplements = citation.map(citation => citation.supplement)

  (body: citation, supplements: supplements)
}

