use std::ffi::OsStr;
use std::fmt::Display;
use std::path::Path;

use hayagriva::{io::BibLaTeXError, Library};
use typst_syntax::Lines;

use crate::model::Resource;

// heavily based on https://github.com/typst/typst/blob/main/crates/typst-library/src/model/bibliography.rs#L306-L390

/// Decode on library from one data source.
pub fn decode_library(source: &Resource) -> Result<Library, String> {
    let Resource { path, data } = source;

    if let Some(path) = path {
        // If we got a path, use the extension to determine whether it is
        // YAML or BibLaTeX.
        let ext = Path::new(&path)
            .extension()
            .and_then(OsStr::to_str)
            .unwrap_or_default();

        match ext.to_lowercase().as_str() {
            "yml" | "yaml" => {
                hayagriva::io::from_yaml_str(data).map_err(|err| format_yaml_error(Some(path), err))
            }
            "bib" => hayagriva::io::from_biblatex_str(data)
                .map_err(|err| format_biblatex_error(Some(path), data, err)),
            _ => return Err("unknown bibliography format (must be .yaml/.yml or .bib)".to_string()),
        }
    } else {
        // If we just got bytes, we need to guess. If it can be decoded as
        // hayagriva YAML, we'll use that.
        let haya_err = match hayagriva::io::from_yaml_str(data) {
            Ok(library) => return Ok(library),
            Err(err) => err,
        };

        // If it can be decoded as BibLaTeX, we use that instead.
        let bib_errs = match hayagriva::io::from_biblatex_str(data) {
            // If the file is almost valid yaml, but contains no `@` character
            // it will be successfully parsed as an empty BibLaTeX library,
            // since BibLaTeX does support arbitrary text outside of entries.
            Ok(library) if !library.is_empty() => return Ok(library),
            Ok(_) => None,
            Err(err) => Some(err),
        };

        // If neither decoded correctly, check whether `:` or `{` appears
        // more often to guess whether it's more likely to be YAML or BibLaTeX
        // and emit the more appropriate error.
        let mut yaml = 0;
        let mut biblatex = 0;
        for c in data.chars() {
            match c {
                ':' => yaml += 1,
                '{' => biblatex += 1,
                _ => {}
            }
        }

        match bib_errs {
            Some(bib_errs) if biblatex >= yaml => Err(format_biblatex_error(None, data, bib_errs)),
            _ => Err(format_yaml_error(None, haya_err)),
        }
    }
}

pub fn format_yaml_error(path: Option<&str>, error: serde_yaml::Error) -> String {
    format_error(
        "failed to parse YAML",
        &error,
        path,
        error.location().map(|loc| (loc.line(), loc.column())),
    )
}

/// Format a BibLaTeX loading error.
fn format_biblatex_error(path: Option<&str>, text: &str, errors: Vec<BibLaTeXError>) -> String {
    // TODO: return multiple errors?
    let Some(error) = errors.into_iter().next() else {
        // TODO: can this even happen, should we just unwrap?
        return format_error(
            "failed to parse BibLaTeX",
            "something went wrong",
            path,
            None,
        );
    };

    let (range, msg) = match error {
        BibLaTeXError::Parse(error) => (error.span, error.kind.to_string()),
        BibLaTeXError::Type(error) => (error.span, error.kind.to_string()),
    };

    // TODO process range
    let loc = {
        let lines = Lines::new(text);
        lines
            .byte_to_line_column(range.start)
            .map(|(line, column)| (line + 1, column + 1))
    };
    format_error("failed to parse BibLaTeX", msg, path, loc)
}

fn format_error(
    msg: &str,
    detail: impl Display,
    path: Option<&str>,
    location: Option<(usize, usize)>,
) -> String {
    match (path, location) {
        (Some(path), Some((line, column))) => format!("{msg} ({path}:{line}:{column}: {detail})"),
        (Some(path), None) => format!("{msg} ({path}: {detail})"),
        (None, Some((line, column))) => format!("{msg} (<input>:{line}:{column}: {detail})"),
        (None, None) => format!("{msg} ({detail})"),
    }
}
