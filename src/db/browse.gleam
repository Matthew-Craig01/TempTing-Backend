import cake/insert as i
import cake/join as j
import cake/select as s
import cake/where as w
import db/db
import gleam/dynamic.{type DecodeError, type Decoder, type Dynamic}
import gleam/io.{debug}
import gleam/list.{concat, map}
import gleam/option.{None, Some}
import gleam/result.{map_error, try}
import gleam/string
import sqlight
import templates/template.{type Template, Template}

pub type GetErr {
  GetDBErr(String)
}

const u_table = "users"

const v_table = "versions"

const p_table = "published"

const t_table = "templates"

pub fn get(conn, page, where) {
  conn
  |> select(page, where)
  |> map_error(fn(e) { GetDBErr(e.message) })
}

fn select(conn, page, where) {
  let fields = [
    s.col(t_table <> ".title"),
    s.col(t_table <> ".description"),
    s.col(p_table <> ".id"),
    s.col(v_table <> ".id"),
    s.col(t_table <> ".args"),
    s.col(t_table <> ".language"),
    s.col(t_table <> ".raw"),
    s.col(t_table <> ".date"),
    s.col(u_table <> ".username"),
    s.col("creator" <> ".username"),
  ]
  let shape = fn(v) {
    use template <- try(template.decoder(v))
    use creator <- try(dynamic.element(9, dynamic.string)(v))
    #(template, creator) |> Ok
  }
  dynamic.tuple2(template.decoder, dynamic.string)
  let query =
    s.new()
    |> s.selects(fields)
    |> s.from_table(v_table)
    |> join_published
    |> join_templates
    |> join_users
    |> join_creator
    |> where
    |> s.order_by(t_table <> ".date", s.Desc)
    |> s.limit(30)
    |> s.offset(30 * { page - 1 })
    |> s.to_query
  conn |> db.select(query, shape)
}

fn join_published(in: s.Select) -> s.Select {
  let join =
    j.inner(
      with: j.table(p_table),
      on: w.col(v_table <> ".published_id") |> w.eq(w.col(p_table <> ".id")),
      alias: p_table,
    )
  in |> s.join(join)
}

fn join_templates(in: s.Select) -> s.Select {
  let join =
    j.inner(
      with: j.table(t_table),
      on: w.col(v_table <> ".template_id") |> w.eq(w.col(t_table <> ".id")),
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

fn join_creator(in: s.Select) -> s.Select {
  let join =
    j.inner(
      with: j.table(u_table),
      on: w.col(v_table <> ".creator_id") |> w.eq(w.col("creator" <> ".id")),
      alias: "creator",
    )
  in |> s.join(join)
}

pub fn where_browse(
  language: String,
  search: String,
) -> fn(s.Select) -> s.Select {
  let condition = case language |> debug, search |> debug {
    "all", "" -> None
    _, "" -> Some(language_condition(language))
    "all", _ -> Some(search_condition(search))
    _, _ ->
      Some([language_condition(language), search_condition(search)] |> w.and)
  }
  case condition {
    None -> fn(in) { in }
    Some(c) -> fn(in) { in |> s.where(c) }
  }
}

fn search_condition(search: String) -> w.Where {
  [
    w.col(t_table <> ".title") |> w.like("%" <> search <> "%"),
    w.col(t_table <> ".description") |> w.like("%" <> search <> "%"),
  ]
  |> w.or
}

fn language_condition(language: String) -> w.Where {
  w.col(t_table <> ".language") |> w.eq(w.string(language))
}

pub fn where_variants(published_id) {
  fn(in) {
    w.col(p_table <> ".id") |> w.eq(w.int(published_id)) |> s.where(in, _)
  }
}


pub fn where_mine(username) {
  fn(in) {
    w.col(u_table <> ".username") |> w.eq(w.string(username)) |> s.where(in, _)
  }
}
