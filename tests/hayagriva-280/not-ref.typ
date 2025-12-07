// Not using this as a reference since the test style seems to use footnotes,
// which Alexandria doesn't support, so the test would fail for unrelated issues.

Par 1 @katalog[p. 5-8]. Should use "different" path.

Par 2 @katalog[p. 5-8]. Should use "ibid" path.

Par 3 @katalog[p. 9-10]. Should use "ibid-with-locator" path.

#bibliography("./bib.yaml", style: "./style.csl")
