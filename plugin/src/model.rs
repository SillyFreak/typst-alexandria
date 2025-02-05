use hayagriva::{CitePurpose, ElemChild, ElemChildren, Formatted};
use serde::{
    ser::{SerializeSeq, SerializeStructVariant},
    Deserialize, Deserializer, Serialize, Serializer,
};

#[derive(Deserialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Config {
    pub sources: Vec<Source>,
    pub style: String,
    pub locale: hayagriva::citationberg::LocaleCode,
    pub citations: Vec<Citation>,
}

#[derive(Deserialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Source {
    pub path: String,
    pub content: String,
}

#[derive(Deserialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Citation {
    pub key: String,
    #[serde(deserialize_with = "deser_cite_purpose")]
    pub form: Option<CitePurpose>,
}

#[derive(Serialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Bibliography {
    pub references: Vec<Entry>,
    pub citations: Vec<Content>,
}

#[derive(Serialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Entry {
    pub key: String,
    pub prefix: Option<Content>,
    pub reference: Content,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Content {
    Children(ElemChildren),
    Child(ElemChild),
}

impl Serialize for Content {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match self {
            Self::Children(children) => {
                let mut seq = serializer.serialize_seq(Some(children.0.len()))?;
                for e in &children.0 {
                    seq.serialize_element(&Self::Child(e.clone()))?;
                }
                seq.end()
            }
            Self::Child(ElemChild::Text(Formatted { text, formatting })) => {
                let mut s = serializer.serialize_struct_variant("content", 0, "text", 6)?;
                s.serialize_field("text", text)?;
                s.serialize_field("font-style", &formatting.font_style)?;
                s.serialize_field("font-variant", &formatting.font_variant)?;
                s.serialize_field("font-weight", &formatting.font_weight)?;
                s.serialize_field("text-decoration", &formatting.text_decoration)?;
                s.serialize_field("vertical-align", &formatting.vertical_align)?;
                s.end()
            }
            Self::Child(ElemChild::Elem(elem)) => {
                let mut s = serializer.serialize_struct_variant("content", 1, "elem", 1)?;
                s.serialize_field("children", &Self::Children(elem.children.clone()))?;
                s.end()
            }
            Self::Child(ElemChild::Markup(markup)) => {
                serializer.serialize_newtype_variant("content", 2, "markup", markup)
            }
            Self::Child(ElemChild::Link { text, url }) => {
                let mut s = serializer.serialize_struct_variant("content", 3, "link", 2)?;
                s.serialize_field("text", &Self::Child(ElemChild::Text(text.clone())))?;
                s.serialize_field("url", url)?;
                s.end()
            }
            Self::Child(ElemChild::Transparent { .. }) => {
                todo!()
            }
        }
    }
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
