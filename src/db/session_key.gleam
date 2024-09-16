import cake
import cake/dialect/sqlite_dialect.{query_to_prepared_statement}
import cake/insert as i
import cake/join as j
import cake/select as s
import cake/where as w
import db/db
import gleam/bit_array.{base64_encode}
import gleam/dynamic.{decode2, decode3}
import gleam/int
import gleam/io.{debug}
import gleam/list.{contains, map}
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result.{map_error, try}
import gleam/string
import sqlight
import users/session_key.{type SessionKey}
import users/user.{hash}

pub type AddErr {
  AddDBErr(String)
}

pub type GetErr {
  InvalidUser
  InvalidSessionKey
  GetDBErr(String)
}

const table = "sessionKeys"

pub fn validate(conn, username, key) -> Result(db.ID, GetErr) {
  "validating session key" |> debug
  case conn |> select(username) {
    Ok([]) -> InvalidUser |> Error |> debug
    Error(e) -> GetDBErr(e.message) |> Error |> debug
    Ok(pairs) -> {
      let assert Ok(#(u_id, _)) = pairs |> list.first
      let db_keys = pairs |> map(pair.second)
      case db_keys |> debug |> contains(key |> hash |> debug) {
        True -> Ok(u_id)
        False -> InvalidSessionKey |> Error
      }
    }
  }
}

pub fn add(conn, user_id, sesion_key) -> Result(Nil, AddErr) {
  conn
  |> insert(user_id, sesion_key |> hash)
  |> map_error(fn(e) { AddDBErr(e.message) })
}

fn insert(conn, user_id, session_key) -> Result(Nil, sqlight.Error) {
  let row = [i.string(session_key), i.int(user_id)]
  let fields = ["key", "user_id"]
  let query =
    i.from_values(table, fields, [row |> i.row])
    |> i.to_query
  let decoder =
    decode2(
      fn(key: String, user_id: String) { #(key, user_id) },
      dynamic.field("key", dynamic.string),
      dynamic.field("user_id", dynamic.string),
    )
  conn |> db.insert(query, decoder)
}

fn select(conn, username) -> Result(List(#(db.ID, SessionKey)), sqlight.Error) {
  let u_table = "users"
  let join =
    j.inner(
      with: j.table(u_table),
      on: w.col(u_table <> ".id") |> w.eq(w.col(table <> ".user_id")),
      alias: u_table,
    )
  let fields = [s.col(u_table <> ".id"), s.col(table <> ".key")]
  let condition =
    w.col(u_table <> ".username") |> w.eq(w.string(username |> debug))
  let shape = dynamic.tuple2(dynamic.int, dynamic.string)
  let query =
    s.new()
    |> s.selects(fields)
    |> s.from_table(table)
    |> s.join(join)
    |> s.where(condition)
    |> s.to_query
  conn |> db.select(query, shape)
}
