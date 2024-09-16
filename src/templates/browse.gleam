import templates/template.{type Template}
import db/browse as b_db
import gleam/result.{try, map_error}
import gleam/io.{debug}
import db/draft as d_db

pub fn browse(conn, page, language, search) -> Result(List(#(Template, String)), b_db.GetErr){
  conn |> b_db.get(page, b_db.where_browse(language, search)) |> debug
}

pub fn variants(conn, page, published_id) -> Result(List(#(Template, String)), b_db.GetErr){
  conn |> b_db.get(page, b_db.where_variants(published_id)) |> debug
}


pub fn mine(conn, page, username) -> Result(#(List(#(Template, String)), List(Template)), b_db.GetErr){
  use published <- try(conn |> b_db.get(page, b_db.where_mine(username)) |> debug)
  use drafts <- try(conn |> d_db.get(page, username) |> map_error(fn(e){
    let d_db.GetDBErr(s) = e
    b_db.GetDBErr(s)
  }))
  #(published, drafts) |> Ok
}
