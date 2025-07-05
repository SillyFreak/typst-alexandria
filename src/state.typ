#let bib-sources = state("__alexandria-bib-sources", (sources: none, reader: none, prefix-delim: "-"))
#let citations = state("__alexandria-config", (
  groups: (),             // array of citation groups in the order they were added
                          // each group is an array of citations, which are tuples of (prefix: str, citation: str)
  lastgroup-open: false,  // if the current citation group is open
))
#let default-prefix = state("__alexandria-default-prefix", none) // default prefix for citations
#let citation-collections = state("__alexandria-citation-collections", (:))
#let citegroup-to-collection = state("__alexandria-citegroup-to-collection", ()) // map of group index to collection index

#let bib-read(source, reader) = {
  if type(source) == bytes {
    (path: none, data: str(source))
  } else if type(source) == str {
    assert.ne(reader, none, message: "Alexandria is not configured. Make sure to use `#show: alexandria(...)`")
    (path: source, data: reader(source))
  } else {
    panic("parameter must be a path string or data bytes")
  }
}

#let match-prefix(delim, key) = {
  let m = str(key).match(delim) // check if key contains the delimiter
  if m != none {
    // split key into prefix and key
    (str(key).slice(0, m.start), str(key).slice(m.end))
  } else {
    // no delimiter found
    let def_prefix = default-prefix.get()
    if def_prefix != none {
      (def_prefix, key) // assume the key contains the default prefix
    } else {
      return none
    }
  }
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

#let add-citation(citation) = citations.update(x => {
  if x.lastgroup-open {
    // add a citation to the currently open group
    x.groups.last().push(citation)
  } else {
    // add a new citation group with a single element
    x.groups.push((citation,))
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

#let collect-and-process-citations(id, citation-filter, processor) = {
  let collected_citations = ()
  let group_to_collection = ()
  for (index, citation_group) in citations.final().groups.enumerate() {
    let ncollected = citation_group.map(x => if citation-filter(x) { 1 } else { 0 }).sum()
    if ncollected > 0 {
      assert.eq(
        ncollected, citation_group.len(),
        message: "collection should include all citations in a group or none, subsetting is not allowed"
      )
      group_to_collection.push((id, collected_citations.len()))
      collected_citations.push(citation_group)
    } else {
      group_to_collection.push(none) // no citations collected from this group
    }
  }
  //panic("Collected citation types: " + collected_citations.map(x => str(type(x))).join(","))

  let bib_sources = bib-sources.get()
  let processed_sources = bib_sources.sources.map(src => bib-read(src, bib_sources.reader))
  let processed_collection = (id: id, ..processor(collected_citations, processed_sources))
  citation-collections.update(x => {
    x.insert(id, processed_collection)
    x
  })

  citegroup-to-collection.update(x => {
    if x.len() == 0 {
      group_to_collection
    } else {
      assert.eq(
        x.len(), group_to_collection.len(),
        message: "citegroup-to-collection must have the same length as the number of citation groups"
      )
      for (index, citegroup) in group_to_collection.enumerate() {
        if citegroup != none {
          x.at(index) = citegroup
        }
      }
      x
    }
  })
}

#let get-citegroup-index() = {
  let citations = citations.get()
  if not citations.lastgroup-open {
    citations.groups.len()
  } else {
    -1
  }
}

#let get-citation(collection-id, incollection-index, citegroup-index) = {
  let processed-citation = citation-collections.final().at(collection-id).citations.at(incollection-index)
  let citegroup = citations.final().groups.at(citegroup-index)
  let supplements = citegroup.map(citation => citation.supplement)

  (body: processed-citation, supplements: supplements)
}

