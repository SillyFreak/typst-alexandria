use hayagriva::{
    archive::ArchivedStyle, citationberg, io::from_biblatex_str, BibliographyDriver,
    BibliographyRequest, CitationItem, CitationRequest, CitePurpose, ElemChildren,
};
#[cfg(target_arch = "wasm32")]
use wasm_minimal_protocol::wasm_func;

mod model;
mod util;

use model::*;
use util::*;

#[cfg(target_arch = "wasm32")]
wasm_minimal_protocol::initiate_protocol!();

fn render(content: &ElemChildren) -> String {
    // TODO
    content.to_string()
}

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn read_biblatex(config: &[u8]) -> Result<Vec<u8>, String> {
    let config: Config = ciborium::from_reader(config).map_err_to_string()?;

    let library = from_biblatex_str(&config.file).map_err(|errs| {
        errs.iter()
            .map(|err| format!("{:?}", err))
            .collect::<Vec<_>>()
            .join("\n")
    })?;
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
            None,
            &[],
            None,
        ));

        for purpose in [P::Prose, P::Full, P::Author, P::Year] {
            driver.citation(CitationRequest::new(
                vec![CitationItem::with_entry(entry).kind(purpose)],
                &style,
                None,
                &[],
                None,
            ));
        }
    }
    let rendered = driver.finish(BibliographyRequest {
        style: &style,
        locale: None,
        locale_files: &[],
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
            let prefix = reference.first_field.as_ref().map(|f| f.to_string());
            let reference = render(&reference.content);

            let forms = ["normal", "prose", "full", "author", "year"]
                .iter()
                .map(ToString::to_string);
            let items = citations.iter().map(|item| render(&item.citation));
            let citations = forms.zip(items).collect();
            Entry {
                key,
                prefix,
                reference,
                citations,
            }
        })
        .collect();
    let bibliography = Bibliography { entries };

    let output = cbor_encode(&bibliography).map_err_to_string()?;
    Ok(output)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_process() {
        process(&cbor_encode("hello").unwrap()).unwrap();
    }
}
