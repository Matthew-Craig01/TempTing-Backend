import cake
import cake/dialect/sqlite_dialect.{query_to_prepared_statement}
import cake/insert as i
import cake/join as j
import cake/select as s
import cake/where as w
import db/db
import gleam/bit_array.{base64_encode}
import gleam/dynamic.{decode3}
import gleam/int
import gleam/io.{debug}
import gleam/list.{map}
import gleam/option.{type Option, None, Some}
import gleam/result.{map_error, try}
import gleam/string
import sqlight
import users/user.{type User, User, hash}

pub type AddErr {
  UsernameTaken
  AddDBErr(String)
}

pub type GetErr {
  InvalidUser
  GetDBErr(String)
}

const table = "users"

pub fn get(conn, username) -> Result(User, GetErr) {
  case conn |> select(username) {
    Ok([#(id, name, pw, icon), ..]) -> User(id, name, pw, icon) |> Ok
    Ok([]) -> InvalidUser |> Error
    Error(e) -> GetDBErr(e.message) |> Error
  }
}

pub fn add(conn, username, password, icon) -> Result(Nil, AddErr) {
  use Nil <- try(conn |> select(username) |> validate_add)
  conn
  |> insert(username, password |> hash, icon)
  |> map_error(fn(e) { AddDBErr(e.message) |> debug })
}

fn select(
  conn,
  username,
) -> Result(List(#(Int, String, String, String)), sqlight.Error) {
  let condition = w.col("username") |> w.eq(w.string(username))
  let fields = [
    s.col("id"),
    s.col("username"),
    s.col("password"),
    s.col("icon"),
  ]
  let shape =
    dynamic.tuple4(dynamic.int, dynamic.string, dynamic.string, dynamic.string)
  let query =
    s.new()
    |> s.selects(fields)
    |> s.from_table(table)
    |> s.where(condition)
    |> s.limit(1)
    |> s.to_query
  conn |> db.select(query, shape)
}

fn insert(conn, username, password, icon) -> Result(Nil, sqlight.Error) {
  #(username, password, icon) |> debug
  let row = [i.string(username), i.string(password), i.string(icon)]
  let fields = ["username", "password", "icon"]
  let query =
    i.from_values(table, fields, [row |> i.row])
    |> i.to_query
  conn |> db.insert(query |> debug, user_decoder())
}

fn validate_add(result: Result(List(a), sqlight.Error)) -> Result(Nil, AddErr) {
  case result {
    Ok([]) -> Ok(Nil)
    Ok(_) -> Error(UsernameTaken)
    Error(e) -> Error(AddDBErr(e.message))
  }
}

fn user_decoder(){
    decode3(
      fn(username: String, password: String, icon: String) { #(username, password, icon) },
      dynamic.field("username", dynamic.string),
      dynamic.field("password", dynamic.string),
      dynamic.field("icon", dynamic.string),
    )
}
