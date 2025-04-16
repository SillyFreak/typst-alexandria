use hayagriva::{CitePurpose, ElemChild, ElemChildren};
use serde::{Deserialize, Deserializer, Serialize};

mod wrapper;

#[derive(Deserialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Config {
    pub sources: Vec<Resource>,
    pub full: bool,
    pub style: Style,
    pub locale: hayagriva::citationberg::LocaleCode,
    pub citations: Vec<Citation>,
}

#[derive(Deserialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Resource {
    pub path: Option<String>,
    pub data: String,
}

#[derive(Deserialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub enum Style {
    BuiltIn(String),
    Custom(String),
}

#[derive(Deserialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Citation {
    pub key: String,
    #[serde(deserialize_with = "deser_cite_purpose")]
    pub form: Option<CitePurpose>,
    pub style: Option<String>,
    pub has_supplement: bool,
    pub locale: hayagriva::citationberg::LocaleCode,
}

#[derive(Serialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Bibliography {
    pub references: Vec<Entry>,
    #[serde(serialize_with = "wrapper::ser_wrapped_seq")]
    pub citations: Vec<ElemChildren>,
    pub hanging_indent: bool,
}

#[derive(Serialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Entry {
    pub key: String,
    #[serde(serialize_with = "wrapper::ser_wrapped_option")]
    pub prefix: Option<ElemChild>,
    #[serde(serialize_with = "wrapper::ser_wrapped")]
    pub reference: ElemChildren,
    pub details: hayagriva::Entry,
}

fn deser_cite_purpose<'de, D>(deserializer: D) -> Result<Option<CitePurpose>, D::Error>
where
    D: Deserializer<'de>,
{
    use std::fmt;

    use serde::de::{self, Visitor};

    struct CitePurposeVisitor;

    impl<'de> Visitor<'de> for CitePurposeVisitor {
        type Value = Option<CitePurpose>;

        fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
            formatter.write_str("a valid citation form: normal, prose, full, author, or year")
        }

        fn visit_str<E>(self, value: &str) -> Result<Self::Value, E>
        where
            E: de::Error,
        {
            match value {
                "normal" => Ok(None),
                "prose" => Ok(Some(CitePurpose::Prose)),
                "full" => Ok(Some(CitePurpose::Full)),
                "author" => Ok(Some(CitePurpose::Author)),
                "year" => Ok(Some(CitePurpose::Year)),
                _ => Err(de::Error::invalid_value(de::Unexpected::Str(value), &self)),
            }
        }
    }

    deserializer.deserialize_str(CitePurposeVisitor)
}
