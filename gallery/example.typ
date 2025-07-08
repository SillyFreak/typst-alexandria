#import "@preview/alexandria:0.2.1": *

#set document(date: none)
#set page(height: auto, margin: 8mm)

#show: alexandria(prefix: "x-", read: path => read(path))
#show: alexandria(prefix: "y-", read: path => read(path))

= Section 1

For further information, see #cite(<x-netwok>, form: "prose").

#bibliographyx(
  "bibliography.bib",
  prefix: "x-",
  title: "Bibliography",
)

= Section 2

We will now look at pirate organizations. @y-arrgh

#bibliographyx(
  "bibliography.bib",
  prefix: "y-",
  title: "Bibliography",
)
