#[cfg(target_arch = "wasm32")]
use wasm_minimal_protocol::wasm_func;

fn cbor_encode<T>(value: &T) -> Result<Vec<u8>, ciborium::ser::Error<std::io::Error>>
where
    T: serde::Serialize + ?Sized,
{
    let mut writer = Vec::new();
    ciborium::into_writer(value, &mut writer)?;
    Ok(writer)
}

trait MapErrToString<T> {
    fn map_err_to_string(self) -> Result<T, String>;
}

impl<T, E: ToString> MapErrToString<T> for Result<T, E> {
    fn map_err_to_string(self) -> Result<T, String> {
        self.map_err(|err| err.to_string())
    }
}

#[cfg(target_arch = "wasm32")]
wasm_minimal_protocol::initiate_protocol!();

#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn process(input: &[u8]) -> Result<Vec<u8>, String> {
    let input: String = ciborium::from_reader(input).map_err_to_string()?;
    let output = input;
    let output = cbor_encode(&output).map_err_to_string()?;
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