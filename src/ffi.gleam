pub type DateTime = String

@external(erlang, "my_ffi", "format_iso8601")
pub fn now() -> DateTime
