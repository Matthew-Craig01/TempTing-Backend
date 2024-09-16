pub type DateTime = String

@external(erlang, "ffi", "format_iso8601")
pub fn now() -> DateTime{}
