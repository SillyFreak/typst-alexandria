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

#let match-prefix(key, allowed-prefixes, prefix-delim) = {
  let m = str(key).match(prefix-delim) // check if key contains the delimiter
  let (prefix_, key_) = if m != none {
    // split key into prefix and key
    (str(key).slice(0, m.start), str(key).slice(m.end))
  } else {
    // no delimiter found
    let def_prefix = default-prefix.get()
    if def_prefix != none {
      (def_prefix, str(key)) // assume the key contains the default prefix
    } else {
      (none, str(key)) // no prefix found
    }
  }
  if prefix_ != none and (
    allowed-prefixes == auto or
    type(allowed-prefixes) == array and allowed-prefixes.contains(prefix_) or
    type(allowed-prefixes) == regex and allowed-prefixes.match(prefix_) != none
  ) {
    (prefix_, key_) // prefix is allowed
  } else {
    none // prefix is not or not matched allowed
  }
}

#let current-citegroup-index() = {
  let citations = citations.get()
  let offset = if citations.lastgroup-open { -1 } else { 0 }
  (citations.groups.len() + offset, citations.lastgroup-open)
}

#let add-citation(citation) = citations.update(x => {
  if x.lastgroup-open {
    // assert(x.lastgroup-open, message: "cannot continue a closed citation group")
    // add a citation to the currently open group
    x.groups.last().push(citation)
  } else {
    // add a new citation group with a single element
    x.groups.push((citation,))
  }
  x
})

#let start-citation-group() = citations.update(x => {
  assert.eq(
    x.lastgroup-open, false,
    message: "can't start a citation group while one is already open",
  )
  x.groups.push(()) // start a new citation group
  x.lastgroup-open = true
  x
})

#let end-citation-group() = citations.update(x => {
  assert.eq(
    x.lastgroup-open, true,
    message: "can't end a citation group when none is open",
  )
  // assert.ne(
  //   x.groups.last().len(), 0,
  //   message: "citation group must not be empty",
  // )
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

#let get-citegroup-content(citegroup-index) = {
  let citegroup_to_coll = citegroup-to-collection.final()
  if citegroup_to_coll.len() > citegroup-index {
    let processed_index = citegroup_to_coll.at(citegroup-index)
    if processed_index != none {
      let (coll_id, incoll_index) = processed_index
      let processed_citation = citation-collections.final().at(coll_id).citations.at(incoll_index)
      let citegroup = citations.final().groups.at(citegroup-index)
      let supplements = citegroup.map(citation => citation.supplement)
      (body: processed_citation, supplements: supplements)
    } else {
      panic("Citation group " + citations.final().groups.at(citegroup-index).map(citation => citation.key).join(",") +
            " not found in any collection")
    }
  } else {
    panic("Citation group #" + str(citegroup-index) + " does not exist")
  }
}
