import gleam/result.{map_error, try}
import gleam/dynamic.{type DecodeError, type Decoder, type Dynamic}
import ffi.{type DateTime, now}
import gleam/option.{type Option, None, Some}
import users/user.{type User}
import gleam/string

pub type Template {
  Template(
    title: String,
    description: String,
    published_id: Option(Int),
    version_id: Option(Int),
    args: List(String),
    language: String,
    raw: String,
    date: DateTime,
    username: String,
  )
}

pub fn new(
  title,
  description,
  published_id,
  version_id,
  args,
  language,
  raw,
  username,
) {
  Template(
    title,
    description,
    published_id,
    version_id,
    args,
    language,
    raw,
    now(),
    username,
  )
}

pub fn decoder(v){
    use title <- try(dynamic.element(0, dynamic.string)(v))
    use description <- try(dynamic.element(1, dynamic.string)(v))
    use published_id <- try(dynamic.element(2, dynamic.int)(v))
    use version_id <- try(dynamic.element(3, dynamic.int)(v))
    use args <- try(dynamic.element(4, dynamic.string)(v))
    use language <- try(dynamic.element(5, dynamic.string)(v))
    use raw <- try(dynamic.element(6, dynamic.string)(v))
    use date <- try(dynamic.element(7, dynamic.string)(v))
    use username <- try(dynamic.element(8, dynamic.string)(v))
      Template(
        title,
        description,
        published_id |> Some,
        version_id |> Some,
        args |> string.split(","),
        language,
        raw,
        date,
        username,
      )
    |> Ok
}

pub fn draft_decoder(v){
    use title <- try(dynamic.element(0, dynamic.string)(v))
    use description <- try(dynamic.element(1, dynamic.string)(v))
    use args <- try(dynamic.element(2, dynamic.string)(v))
    use language <- try(dynamic.element(3, dynamic.string)(v))
    use raw <- try(dynamic.element(4, dynamic.string)(v))
    use date <- try(dynamic.element(5, dynamic.string)(v))
    use username <- try(dynamic.element(6, dynamic.string)(v))
      Template(
        title,
        description,
        None,
        None,
        args |> string.split(","),
        language,
        raw,
        date,
        username,
      )
    |> Ok
}
