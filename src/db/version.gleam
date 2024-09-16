import cake
import cake/dialect/sqlite_dialect.{query_to_prepared_statement}
import cake/insert as i
import cake/update as u
import cake/join as j
import cake/select as s
import cake/where as w
import db/db
import db/template as db_t
import gleam/bit_array.{base64_encode}
import gleam/dynamic.{decode3}
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

const table = "versions"

pub fn add(conn, template_id, user_id, published_id) -> Result(Int, t_db.AddErr) {
  use Nil <- try(
    conn
    |> insert(template_id, user_id, published_id)
    |> map_error(fn(e) { t_db.AddDBErr(e.message) }),
  )
  conn
  |> db.select_last_id(table)
  |> map_error(fn(_) { t_db.AddDBErr("new version id-select failed") })
}

pub fn edit(conn, version_id, template_id) -> Result(Int, t_db.AddErr) {
  use Nil <- try(
    conn
    |> update(version_id, template_id)
    |> map_error(fn(e) { t_db.AddDBErr(e.message) }),
  )
  version_id |> Ok
}

fn update(conn, version_id, template_id) -> Result(Nil, sqlight.Error) {
  let query =
  u.new()
  |> u.table(table)
  |> u.sets(["template_id" |> u.set_int(template_id)])
  |> u.where(w.col("id") |> w.eq(w.int(version_id)))
  |> u.to_query |> debug
  conn |> db.insert(query, dynamic.dynamic)
}


fn insert(conn, template_id, user_id, published_id) -> Result(Nil, sqlight.Error) {
  let row = [i.int(template_id), i.int(user_id), i.int(published_id)]
  let fields = ["template_id", "creator_id", "published_id"]
  let query =
    i.from_values(table, fields, [row |> i.row])
    |> i.to_query
  conn |> db.insert(query, version_decoder())
}

fn version_decoder() {
  decode3(
    fn(template_id, creator_id, published_id) {#(template_id, creator_id, published_id)},
    dynamic.field("template_id", dynamic.int),
    dynamic.field("creator_id", dynamic.int),
    dynamic.field("published_id", dynamic.int),
  )
}
