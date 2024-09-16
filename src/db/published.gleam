import cake
import cake/dialect/sqlite_dialect.{query_to_prepared_statement}
import cake/insert as i
import cake/join as j
import cake/select as s
import cake/where as w
import db/db
import db/template as db_t
import gleam/bit_array.{base64_encode}
import gleam/dynamic.{decode1}
import gleam/int
import gleam/io.{debug}
import gleam/list.{map}
import gleam/option.{type Option, None, Some}
import gleam/result.{map_error, try}
import gleam/string
import sqlight
import templates/template.{type Template}
import users/user.{type User, User, hash}
import db/template as t_db

pub type GetErr {
  GetDBErr(String)
}

const table = "published"

pub fn add(conn, num_args) -> Result(Int, t_db.AddErr) {
  use Nil <- try(
    conn
    |> insert(num_args)
    |> map_error(fn(e) { t_db.AddDBErr(e.message) }),
  )
  conn
  |> db.select_last_id(table)
  |> map_error(fn(_) { t_db.AddDBErr("new published id-select failed") })
}

fn insert(conn, num_args) -> Result(Nil, sqlight.Error) {
  let row = [i.int(num_args)]
  let fields = ["numArgs"]
  let query =
    i.from_values(table, fields, [row |> i.row])
    |> i.to_query
  conn |> db.insert(query, published_decoder())
}

fn published_decoder() {
  decode1(
    fn(num_args: Int) {num_args},
    dynamic.field("template_id", dynamic.int),
  )
}
