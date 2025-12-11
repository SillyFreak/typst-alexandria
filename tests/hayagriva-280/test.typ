#import "../test-utils.typ": *
#show: alexandria.alexandria(prefix: "x-", read: path => read(path))

Par 1 @x-katalog[p. 5-8]. Should use "different" path.

Par 2 @x-katalog[p. 5-8]. Should use "ibid" path.

Par 3 @x-katalog[p. 9-10]. Should use "ibid-with-locator" path.

#bibliographyx("./bib.yaml", title: "Bibliography", style: "./style.csl")
