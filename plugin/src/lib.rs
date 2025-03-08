// Parts of code in this file are based on
// https://github.com/typst/typst/blob/26e65bfef5b1da7f6c72e1409237cf03fb5d6069/crates/typst-library/src/model/bibliography.rs
// licensed from the authors under Apache License 2.0

use std::ffi::OsStr;
use std::path::Path;
use std::sync::LazyLock;

use hayagriva::{
    archive::ArchivedStyle, citationberg, BibliographyDriver, BibliographyRequest, CitationItem,
    CitationRequest, Library,
};
use indexmap::{map, IndexMap};
use typed_arena::Arena;
#[cfg(target_arch = "wasm32")]
use wasm_minimal_protocol::wasm_func;

mod model;
mod util;

use model::*;
use util::*;

#[cfg(target_arch = "wasm32")]
wasm_minimal_protocol::initiate_protocol!();

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn names() -> Result<Vec<u8>, String> {
    let names = ArchivedStyle::all()
        .iter()
        .map(|style| style.names().into_iter().copied())
        .flatten()
        .collect::<Vec<_>>();
    let output = cbor_encode(&names).map_err_to_string()?;
    Ok(output)
}

static LOCALES: LazyLock<Vec<citationberg::Locale>> = LazyLock::new(hayagriva::archive::locales);

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn read(config: &[u8]) -> Result<Vec<u8>, String> {
    let config: Config = ciborium::from_reader(config).map_err_to_string()?;
    let bibliography = read_impl(config)?;
    let output = cbor_encode(&bibliography).map_err_to_string()?;
    Ok(output)
}

fn read_library(source: &Resource) -> Result<Library, String> {
    let Resource { path, data } = source;
    if let Some(path) = path {
        let ext = Path::new(&path)
            .extension()
            .and_then(OsStr::to_str)
            .unwrap_or_default();
        let library = match ext.to_lowercase().as_str() {
            "yml" | "yaml" => hayagriva::io::from_yaml_str(&data)
                .map_err(|err| format!("failed to parse YAML ({err})"))?,
            "bib" => hayagriva::io::from_biblatex_str(&data)
                .map_err(|_errors| format!("failed to parse BibLaTeX file ({path})"))?,
            _ => return Err("unknown bibliography format (must be .yml/.yaml or .bib)".to_string()),
        };
        Ok(library)
    } else {
        hayagriva::io::from_yaml_str(data)
            .or_else(|_| hayagriva::io::from_biblatex_str(data))
            .map_err(|_errors| {
                "failed to parse bibliography (must be .yml/.yaml or .bib)".to_string()
            })
    }
}

fn read_libraries(sources: &[Resource]) -> Result<IndexMap<String, hayagriva::Entry>, String> {
    let mut map = IndexMap::new();
    let mut duplicates = Vec::new();

    // We might have multiple bib/yaml files
    for source in sources {
        let library = read_library(source)?;

        for entry in library {
            match map.entry(entry.key().into()) {
                map::Entry::Vacant(vacant) => {
                    vacant.insert(entry);
                }
                map::Entry::Occupied(_) => {
                    duplicates.push(entry.key().to_string());
                }
            }
        }
    }

    if !duplicates.is_empty() {
        return Err(format!(
            "duplicate bibliography keys: {}",
            duplicates.join(", ")
        ));
    }

    Ok(map)
}

fn read_impl(config: Config) -> Result<Bibliography, String> {
    let entries = read_libraries(&config.sources)?;

    let style = match config.style {
        Style::BuiltIn(name) => ArchivedStyle::by_name(&name)
            .ok_or(format!("Unknown style: {}", name))?
            .get(),
        Style::Custom(source) => citationberg::Style::from_xml(&source).map_err_to_string()?,
    };
    let citationberg::Style::Independent(style) = style else {
        return Err("style is not an IndependentStyle".to_string());
    };

    let styles = Arena::new();
    let mut driver = BibliographyDriver::new();
    for citation in config.citations {
        let Some(entry) = entries.get(&citation.key) else {
            return Err(format!(
                "key `{}` does not exist in the bibliography",
                citation.key
            ));
        };

        let citation_style = citation
            .style
            .map(|style| {
                let style =
                    ArchivedStyle::by_name(&style).ok_or(format!("Unknown style: {}", style))?;
                let citationberg::Style::Independent(style) = style.get() else {
                    return Err("style is not an IndependentStyle".to_string());
                };
                let style = styles.alloc(style);
                Ok(&*style)
            })
            .transpose()?
            .unwrap_or(&style);

        driver.citation(CitationRequest::new(
            vec![CitationItem::new(entry, None, None, false, citation.form)],
            citation_style,
            Some(citation.locale),
            &LOCALES,
            None,
        ));
    }

    if config.full {
        for entry in entries.values() {
            driver.citation(CitationRequest::new(
                vec![CitationItem::new(entry, None, None, true, None)],
                &style,
                Some(config.locale.clone()),
                &LOCALES,
                None,
            ));
        }
    }
    let rendered = driver.finish(BibliographyRequest {
        style: &style,
        locale: Some(config.locale),
        locale_files: &LOCALES,
    });

    let Some(rendered_bib) = rendered.bibliography else {
        return Err("no bibliography".to_string());
    };

    let references = rendered_bib
        .items
        .into_iter()
        .map(|reference| {
            let key = reference.key;
            let prefix = reference.first_field.map(Content::Child);
            let reference = Content::Children(false, reference.content);

            let details = entries
                .get(&key)
                .cloned()
                .expect("key has been found before but not anymore");

            Entry {
                key,
                prefix,
                reference,
                details,
            }
        })
        .collect();
    let citations = rendered
        .citations
        .into_iter()
        .map(|item| Content::Children(true, item.citation))
        .collect();

    let hanging_indent = rendered_bib.hanging_indent;

    Ok(Bibliography {
        references,
        citations,
        hanging_indent,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_process() {
        let bib = r#"
        @article{netwok,
            title={At-scale impact of the {Net Wok}: A culinarically holistic investigation of distributed dumplings},
            author={Astley, Rick and Morris, Linda},
            journal={Armenian Journal of Proceedings},
            volume={61},
            pages={192--219},
            year={2020},
            publisher={Automattic Inc.}
        }
        "#;
        read_impl(Config {
            sources: vec![Resource {
                path: Some("bibliography.bib".to_string()),
                data: bib.to_string(),
            }],
            full: true,
            style: Style::BuiltIn("ieee".to_string()),
            locale: hayagriva::citationberg::LocaleCode::en_us(),
            citations: vec![],
        })
        .unwrap();
    }
}
