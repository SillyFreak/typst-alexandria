root := justfile_directory()

export TYPST_ROOT := root

[private]
default:
	@just --list --unsorted

# generate manual
doc:
	typst compile docs/manual.typ docs/manual.pdf
	for f in $(find gallery -maxdepth 1 -name '*.typ'); do \
		typst compile "$f"; \
	done
	typst compile --ppi 250 "gallery/thumbnail.typ" "thumbnail-light.png"
	typst compile --ppi 250 --input theme=dark "gallery/thumbnail.typ" "thumbnail-dark.png"

# run test suite
test *args:
	cargo test
	typst-test run {{ args }}

# update test cases
update *args:
	typst-test update {{ args }}

# build the parser WASM plugin
plugin:
	cargo build --release --target wasm32-unknown-unknown
	cp target/wasm32-unknown-unknown/release/alexandria.wasm src/

# package the library into the specified destination folder
package target:
  ./scripts/package "{{target}}"

# install the library with the "@local" prefix
install: (package "@local")

# install the library with the "@preview" prefix (for pre-release testing)
install-preview: (package "@preview")

[private]
remove target:
  ./scripts/uninstall "{{target}}"

# uninstalls the library from the "@local" prefix
uninstall: (remove "@local")

# uninstalls the library from the "@preview" prefix (for pre-release testing)
uninstall-preview: (remove "@preview")

# run ci suite
ci: test doc
