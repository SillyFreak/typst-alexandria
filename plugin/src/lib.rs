use std::{ffi::OsStr, path::Path, sync::LazyLock};

use hayagriva::{
    archive::ArchivedStyle, citationberg, BibliographyDriver,
    BibliographyRequest, CitationItem, CitationRequest, CitePurpose, Library,
};
#[cfg(target_arch = "wasm32")]
use wasm_minimal_protocol::wasm_func;

mod model;
mod util;

use model::*;
use util::*;

#[cfg(target_arch = "wasm32")]
wasm_minimal_protocol::initiate_protocol!();

static LOCALES: LazyLock<Vec<citationberg::Locale>> = LazyLock::new(hayagriva::archive::locales);

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn read(config: &[u8]) -> Result<Vec<u8>, String> {
    let config: Config = ciborium::from_reader(config).map_err_to_string()?;
    let bibliography = read_impl(config)?;
    let output = cbor_encode(&bibliography).map_err_to_string()?;
    Ok(output)
}

fn read_library(source: Source) -> Result<Library, String> {
    let Source { path, content } = source;
    let ext = Path::new(&path)
        .extension()
        .and_then(OsStr::to_str)
        .unwrap_or_default();
    let library = match ext.to_lowercase().as_str() {
        "yml" | "yaml" => hayagriva::io::from_yaml_str(&content)
            .map_err(|err| format!("failed to parse YAML ({err})"))?,
        "bib" => hayagriva::io::from_biblatex_str(&content)
            .map_err(|_errors| format!("failed to parse BibLaTeX file ({path})"))?,
        _ => return Err("unknown bibliography format (must be .yml/.yaml or .bib)".to_string()),
    };
    Ok(library)
}

fn read_impl(mut config: Config) -> Result<Bibliography, String> {
    let source = {
        if config.sources.len() != 1 {
            return Err("exactly one bibliography file is required".to_string());
        }
        config.sources.pop().unwrap()
    };

    let library = read_library(source)?;
    let style =
        ArchivedStyle::by_name(&config.style).ok_or(format!("Unknown style: {}", config.style))?;
    let citationberg::Style::Independent(style) = style.get() else {
        return Err("style is not an IndependentStyle".to_string());
    };

    let mut driver = BibliographyDriver::new();
    for entry in library.iter() {
        use CitePurpose as P;

        driver.citation(CitationRequest::new(
            vec![CitationItem::with_entry(entry)],
            &style,
            Some(config.locale.clone()),
            &LOCALES,
            None,
        ));

        for purpose in [P::Prose, P::Full, P::Author, P::Year] {
            driver.citation(CitationRequest::new(
                vec![CitationItem::with_entry(entry).kind(purpose)],
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

    let references = rendered_bib.items.into_iter();
    let citations = rendered.citations.chunks(5);
    let entries = references
        .zip(citations)
        .map(|(reference, citations)| {
            let key = reference.key;
            let prefix = reference.first_field.map(Content::Child);
            let reference = Content::Children(reference.content);

            let forms = ["normal", "prose", "full", "author", "year"]
                .iter()
                .map(ToString::to_string);
            let items = citations
                .iter()
                .map(|item| Content::Children(item.citation.clone()));
            let citations = forms.zip(items).collect();
            Entry {
                key,
                prefix,
                reference,
                citations,
            }
        })
        .collect();

    Ok(Bibliography { entries })
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
            sources: vec![Source {
                path: "bibliography.bib".to_string(),
                content: bib.to_string(),
            }],
            style: "ieee".to_string(),
            locale: hayagriva::citationberg::LocaleCode::en_us(),
        })
        .unwrap();
    }
}
