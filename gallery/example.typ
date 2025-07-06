#import "@local/alexandria:0.3.0": *

#set document(date: none)
#set page(height: auto, margin: 8mm)

#show: alexandria("bibliography.bib", reader: path => read(path))

= Section 1

#alexandria-prefix("x")

For further information, see #cite(<netwok>, form: "prose").

#bibliographyx(prefix: "x", title: "Bibliography")

= Section 2

#alexandria-prefix("y")

We will now look at pirate and quark organizations @arrgh@y-quark.

#bibliographyx(prefix: "y", title: "Bibliography")

= Section 3

#alexandria-prefix("z")

A bit of psychology #citegroup([@mcintosh_anxiety @psychology25]).

#bibliographyx(prefix: "z", title: "Bibliography")
