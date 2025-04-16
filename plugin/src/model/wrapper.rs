use std::borrow::Cow;

use hayagriva::{ElemChild, ElemChildren, Formatted, Formatting};
use serde::{
    ser::{SerializeSeq, SerializeStructVariant},
    Serialize, Serializer,
};

pub fn ser_wrapped<S, T>(value: T, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
    SerWrapper<T>: Serialize,
{
    SerWrapper(value).serialize(serializer)
}

pub fn ser_wrapped_option<S, T>(value: &Option<T>, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
    for<'a> SerWrapper<&'a T>: Serialize,
{
    value.as_ref().map(SerWrapper).serialize(serializer)
}

pub fn ser_wrapped_seq<Seq, S, T>(value: Seq, serializer: S) -> Result<S::Ok, S::Error>
where
    Seq: IntoIterator<Item = T>,
    S: Serializer,
    SerWrapper<T>: Serialize,
{
    let iter = value.into_iter().map(SerWrapper);
    let mut seq = serializer.serialize_seq(match iter.size_hint() {
        (lower, Some(upper)) if lower == upper => Some(lower),
        _ => None,
    })?;
    for elem in iter {
        seq.serialize_element(&elem)?;
    }
    seq.end()
}

pub struct SerWrapper<T>(T);

impl Serialize for SerWrapper<&ElemChildren> {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let Self(children) = *self;

        SerWrapper((true, children)).serialize(serializer)
    }
}

impl Serialize for SerWrapper<(bool, &ElemChildren)> {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let Self((is_citation, ElemChildren(children))) = *self;

        let mut seq = serializer.serialize_seq(Some(children.len()))?;
        for (i, e) in children.iter().enumerate() {
            let mut e = Cow::Borrowed(e);
            if is_citation && i == 0 && matches!(*e, ElemChild::Text(Formatted { .. })) {
                let ElemChild::Text(Formatted { text, .. }) = e.to_mut() else {
                    panic!("pattern didn't match even thoughit did before")
                };
                // remove the whitespace prefix
                let prefix_len = text.len() - text.trim_start().len();
                text.drain(..prefix_len);
            }
            seq.serialize_element(&SerWrapper(e.as_ref()))?;
        }
        seq.end()
    }
}

impl Serialize for SerWrapper<&ElemChild> {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let Self(child) = *self;

        let serialize_formatting = |s: &mut S::SerializeStructVariant, formatting: &Formatting| {
            s.serialize_field("font-style", &formatting.font_style)?;
            s.serialize_field("font-variant", &formatting.font_variant)?;
            s.serialize_field("font-weight", &formatting.font_weight)?;
            s.serialize_field("text-decoration", &formatting.text_decoration)?;
            s.serialize_field("vertical-align", &formatting.vertical_align)?;
            Ok(())
        };

        match child {
            ElemChild::Text(Formatted { text, formatting }) => {
                let mut s = serializer.serialize_struct_variant("content", 0, "text", 6)?;
                s.serialize_field("text", text)?;
                serialize_formatting(&mut s, formatting)?;
                s.end()
            }
            ElemChild::Elem(elem) => {
                let mut s = serializer.serialize_struct_variant("content", 1, "elem", 2)?;
                s.serialize_field("children", &SerWrapper((false, &elem.children)))?;
                s.serialize_field("display", &elem.display)?;
                // s.serialize_field("meta", &elem.meta)?;
                s.end()
            }
            ElemChild::Markup(markup) => {
                serializer.serialize_newtype_variant("content", 2, "markup", markup)
            }
            ElemChild::Link { text, url } => {
                let mut s = serializer.serialize_struct_variant("content", 3, "link", 7)?;
                s.serialize_field("text", &text.text)?;
                serialize_formatting(&mut s, &text.formatting)?;
                s.serialize_field("url", url)?;
                s.end()
            }
            ElemChild::Transparent { cite_idx, format } => {
                let mut s = serializer.serialize_struct_variant("content", 4, "transparent", 6)?;
                s.serialize_field("cite-idx", cite_idx)?;
                serialize_formatting(&mut s, format)?;
                s.end()
            }
        }
    }
}
