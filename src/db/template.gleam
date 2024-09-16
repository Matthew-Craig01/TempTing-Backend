import cake
import cake/dialect/sqlite_dialect.{query_to_prepared_statement}
import cake/insert as i
import cake/join as j
import cake/select as s
import cake/where as w
import db/db
import db/user as user_db
import gleam/bit_array.{base64_encode}
import gleam/dynamic.{decode7}
import gleam/int
import gleam/io.{debug}
import gleam/list.{map}
import gleam/option.{type Option, None, Some}
import gleam/result.{map_error, try}
import gleam/string
import sqlight
import templates/template.{type Template}
import users/user.{type User, User, hash}

const table = "templates"

pub type AddErr {
  InvalidUser
  AddDBErr(String)
}

pub fn add(conn, template t: Template) -> Result(Int, AddErr) {
  "saving template" |> debug
  use u <- try(
    conn |> user_db.get(t.username) |> map_error(fn(_) { InvalidUser }),
  )
  "Valid user" |> debug
  use Nil <- try(
    conn
    |> insert(
      t.title,
      t.description,
      t.args |> string.join(","),
      t.language,
      t.raw,
      t.date,
      u.id,
    )
    |> map_error(fn(e) { AddDBErr(e.message) |> debug }),
  )
  "Added to db" |> debug
  conn
  |> db.select_last_id(table)
  |> map_error(fn(_) { AddDBErr("new template id-select failed") })
  |> debug
}

fn insert(
  conn,
  title,
  description,
  args,
  language,
  raw,
  date,
  user_id,
) -> Result(Nil, sqlight.Error) {
  let row = [
    i.string(title),
    i.string(description),
    i.string(args),
    i.string(language),
    i.string(raw),
    i.string(date),
    i.int(user_id),
  ]
  let fields = [
    "title", "description", "args", "language", "raw", "date", "user_id",
  ]
  let query =
    i.from_values(table, fields, [row |> i.row])
    |> i.to_query
  conn |> db.insert(query |> debug, template_decoder())
}

fn template_decoder() {
  decode7(
    fn(
      title: String,
      description: String,
      args: String,
      language: String,
      raw: String,
      date: String,
      user_id: Int,
    ) {
      #(title, description, args, language, raw, date, user_id)
    },
    dynamic.field("title", dynamic.string),
    dynamic.field("description", dynamic.string),
    dynamic.field("args", dynamic.string),
    dynamic.field("language", dynamic.string),
    dynamic.field("raw", dynamic.string),
    dynamic.field("date", dynamic.string),
    dynamic.field("user_id", dynamic.int),
  )
}
