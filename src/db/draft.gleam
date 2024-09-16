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

const table = "drafts"


const u_table = "users"

const t_table = "templates"

pub fn add(conn, template_id) -> Result(Int, t_db.AddErr) {
  use Nil <- try(
    conn
    |> insert(template_id)
    |> map_error(fn(e) { t_db.AddDBErr(e.message) }),
  )
  conn
  |> db.select_last_id(table)
  |> map_error(fn(_) { t_db.AddDBErr("new draft id-select failed") })
}

pub fn get(conn, page, username) {
  conn
  |> select(page, username)
  |> map_error(fn(e) { GetDBErr(e.message) })
}

fn select(conn, page, username) {
  let fields = [
    s.col(t_table <> ".title"),
    s.col(t_table <> ".description"),
    s.col(t_table <> ".args"),
    s.col(t_table <> ".language"),
    s.col(t_table <> ".raw"),
    s.col(t_table <> ".date"),
    s.col(u_table <> ".username"),
  ]
  let shape =
    template.draft_decoder
  let query =
    s.new()
    |> s.selects(fields)
    |> s.from_table(table)
    |> join_templates
    |> join_users
    |> where_mine(username)
    |> s.order_by(t_table <> ".date", s.Desc)
    |> s.limit(30)
    |> s.offset(30 * { page - 1 })
    |> s.to_query
  conn |> db.select(query, shape)
}


fn insert(conn, template_id) -> Result(Nil, sqlight.Error) {
  let row = [i.int(template_id)]
  let fields = ["template_id"]
  let query =
    i.from_values(table, fields, [row |> i.row])
    |> i.to_query
  conn |> db.insert(query, draft_decoder())
}

fn draft_decoder() {
  decode1(
    fn(template_id: Int) { template_id },
    dynamic.field("template_id", dynamic.int),
  )
}

fn join_templates(in: s.Select) -> s.Select {
  let join =
    j.inner(
      with: j.table(t_table),
      on: w.col(table <> ".template_id") |> w.eq(w.col(t_table <> ".id")),
      alias: t_table,
    )
  in |> s.join(join)
}

fn join_users(in: s.Select) -> s.Select {
  let join =
    j.inner(
      with: j.table(u_table),
      on: w.col(t_table <> ".user_id") |> w.eq(w.col(u_table <> ".id")),
      alias: u_table,
    )
  in |> s.join(join)
}

pub fn where_mine(username) {
  fn(in) {
    w.col(u_table <> ".username") |> w.eq(w.string(username)) |> s.where(in, _)
  }
}
