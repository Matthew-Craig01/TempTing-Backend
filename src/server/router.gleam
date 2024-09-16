import db/session_key
import gleam/dynamic.{type Dynamic}
import gleam/http.{Get, Post}
import gleam/io.{debug}
import gleam/json
import gleam/list.{key_find}
import gleam/result.{try}
import gleam/string_builder
import server/middleware.{middleware}
import server/serialisation.{
  decode_browse, decode_mine, decode_save, decode_signin, decode_signup,
  decode_variants, encode_browse, encode_browse_err, encode_id, encode_id2,
  encode_save_err, encode_session_key, encode_sign_in_err, encode_sign_up_err,
  encode_template,
}
import sqlight.{type Connection}
import templates/browse.{browse, variants}
import templates/save_publish.{publish, save_draft}
import users/signin.{sign_in}
import users/signup.{sign_up}
import wisp.{
  type Request, type Response, created, json_response, path_segments,
  require_json, require_method, unprocessable_entity,
}

pub fn handle_request(req: Request, conn: Connection) -> Response {
  use req <- middleware(req)
  case path_segments(req) {
    ["signup"] -> handle_signup(req, conn)
    ["signin"] -> handle_signin(req, conn)
    ["save"] -> handle_save(req, conn)
    ["publish"] -> handle_publish(req, conn)
    ["browse"] -> handle_browse(req, conn)
    ["variants"] -> handle_variants(req, conn)
    ["mine"] -> handle_mine(req, conn)
    _ -> wisp.not_found()
  }
}

fn handle_mine(req: Request, conn: Connection) -> Response {
  "received mine request" |> debug
  use #(page, username) <- decode_then(req, decode_mine)
  case browse.mine(conn, page, username) {
    Ok(#(drafts, published)) -> response(serialisation.encode_mine(drafts, published) |> debug, 201)
    Error(e) -> response(e |> encode_browse_err, 409)
  }
}

fn handle_browse(req: Request, conn: Connection) -> Response {
  "received browse request" |> debug
  use #(page, language, search) <- decode_then(req, decode_browse)
  #(page, language, search) |> debug
  case browse(conn, page, language, search) {
    Ok(templates) -> response(templates |> encode_browse, 201)
    Error(e) -> response(e |> encode_browse_err, 409)
  }
}

fn handle_variants(req: Request, conn: Connection) -> Response {
  "received variants request" |> debug
  use #(page, published_id) <- decode_then(req, decode_variants)
  case variants(conn, page, published_id) {
    Ok(templates) -> response(templates |> encode_browse, 201)
    Error(e) -> response(e |> encode_browse_err, 409)
  }
}

fn handle_save(req: Request, conn: Connection) -> Response {
  "received draft save reqest" |> debug
  use #(session_key, template) <- decode_then(req, decode_save)
  template |> debug
  case save_draft(conn, template, session_key) {
    Ok(id) -> response(encode_id(id), 201)
    Error(e) -> response(e |> encode_save_err, 409)
  }
}

fn handle_publish(req: Request, conn: Connection) -> Response {
  use #(session_key, template) <- decode_then(req, decode_save)
  case publish(conn, template |> debug, session_key |> debug) {
    Ok(#(published_id, version_id)) ->
      response(encode_id2(published_id, version_id), 201)
    Error(e) -> response(e |> encode_save_err, 409)
  }
}

fn handle_signup(req: Request, conn: Connection) -> Response {
  use #(username, password) <- decode_then(req, decode_signup)
  case sign_up(conn, username, password) {
    Ok(session_key) -> response(session_key |> encode_session_key, 201)
    Error(e) -> response(e |> encode_sign_up_err, 409)
  }
}

fn handle_signin(req: Request, conn: Connection) -> Response {
  use #(username, password) <- decode_then(req, decode_signin)
  case sign_in(conn, username, password) {
    Ok(session_key) -> response(session_key |> encode_session_key, 201)
    Error(e) -> response(e |> encode_sign_in_err, 409)
  }
}

fn decode_then(
  req: Request,
  decoder: fn(Dynamic) -> Result(a, b),
  then: fn(a) -> Response,
) -> Response {
  "decoding request" |> debug
  use <- require_method(req, Post)
  use json <- require_json(req)
  "received json" |> debug
  json |> debug
  case decoder(json) {
    Error(_) -> unprocessable_entity() |> debug
    Ok(ok) -> {
      "decoded ok" |> debug
      ok |> debug
      then(ok)
    }
  }
}

fn response(json, code) {
  json_response(json |> json.to_string_builder, code)
}
