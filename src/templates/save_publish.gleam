import db/draft
import db/published
import db/session_key as db_skey
import db/template as db_t
import db/version
import gleam/bool.{guard}
import gleam/io.{debug}
import gleam/list.{length}
import gleam/option.{None, Some}
import gleam/result.{map_error, try}
import gleam/string
import templates/template.{type Template}

pub type SaveErr {
  InvalidSessionKey
  SaveDBErr(db_t.AddErr)
}

pub fn save_draft(conn, template: Template, session_key) -> Result(Int, SaveErr) {
  template |> debug
  use _user_id <- try(validate_session(conn, template.username, session_key))
  use template_id <- try(conn |> db_t.add(template) |> map_error(SaveDBErr))
  "template id:" |> debug
  template_id |> debug
  conn |> draft.add(template_id) |> map_error(SaveDBErr) |> debug
}

pub fn publish(
  conn,
  template: Template,
  session_key,
) -> Result(#(Int, Int), SaveErr) {
  //TODO check if published template with same title and language exists
  "publishing" |> debug
  template |> debug
  use user_id <- try(validate_session(conn, template.username, session_key))
  use template_id <- try(conn |> db_t.add(template) |> map_error(SaveDBErr))
  use published_id <- try(case template.published_id {
    Some(id) -> id |> Ok
    None ->
      conn
      |> published.add(template.args |> length)
      |> map_error(SaveDBErr)
      |> debug
  })
  use version_id <- try(case template.version_id {
    Some(id) ->
      conn
      |> version.edit(id, template_id)
      |> map_error(SaveDBErr)
      |> debug
    None ->
      conn
      |> version.add(template_id, user_id, published_id)
      |> map_error(SaveDBErr)
      |> debug
  })
  #(published_id, version_id) |> Ok
}

fn validate_session(conn, username, session_key) {
  conn
  |> db_skey.validate(username, session_key)
  |> map_error(fn(_) { InvalidSessionKey })
}
