use std::collections::HashMap;

use hayagriva::{ElemChild, ElemChildren, Formatted};
use serde::{
    ser::{SerializeSeq, SerializeStructVariant},
    Deserialize, Serialize, Serializer,
};

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Config {
    pub file: String,
    pub style: String,
    pub locale: hayagriva::citationberg::LocaleCode,
}

#[derive(Serialize, Debug, Clone, PartialEq)]
#[serde(transparent)]
pub struct Bibliography {
    pub entries: Vec<Entry>,
}

#[derive(Serialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub struct Entry {
    pub key: String,
    pub prefix: Option<Content>,
    pub reference: Content,
    pub citations: HashMap<String, Content>,
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
