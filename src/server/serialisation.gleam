import db/browse as b_db
import db/template as db_t
import gleam/dynamic.{
  type DecodeError, type Dynamic, decode2, decode3, decode6, decode7, decode9,
}
import gleam/http.{Options}
import gleam/io.{debug}
import gleam/json.{type Json}
import gleam/option.{None, Some}
import gleam/result.{map_error, try}
import gleam/string
import templates/save_publish.{type SaveErr, InvalidSessionKey, SaveDBErr}
import templates/template.{type Template}
import users/session_key.{type SessionKey}
import users/signin.{
  type SignInErr, InvalidPassword, InvalidUsername, SignInFailed,
}
import users/signup.{
  type SignUpErr, PasswordTooShort, SignUpFailed, UsernameTaken,
  UsernameTooShort, UsernameWhitespace,
}
import users/user.{User}

pub fn decode_mine(json: Dynamic) -> Result(#(Int, String), List(DecodeError)) {
  let decoder = mine_decoder()
  decoder(json)
}

pub fn decode_browse(
  json: Dynamic,
) -> Result(#(Int, String, String), List(DecodeError)) {
  let decoder = browse_decoder()
  decoder(json)
}

pub fn decode_variants(json: Dynamic) -> Result(#(Int, Int), List(DecodeError)) {
  let decoder = variants_decoder()
  decoder(json)
}

pub fn decode_signup(
  json: Dynamic,
) -> Result(#(String, String), List(DecodeError)) {
  //TODO will be different when icons are used
  decode_signin(json)
}

pub fn decode_signin(
  json: Dynamic,
) -> Result(#(String, String), List(DecodeError)) {
  let decoder = user_decoder()
  decoder(json)
}

pub fn decode_save(
  json: Dynamic,
) -> Result(#(String, Template), List(DecodeError)) {
  "decoding save draft" |> debug
  use #(session_key, username, template_json) <- try(save_decoder()(json))
  use
    #(title, description, published_id_int, version_id_int, args, language, raw)
  <- try(template_decoder()(template_json))
  let published_id = {
    case published_id_int {
      -1 -> None
      id -> Some(id)
    }
  }

  let version_id = {
    case version_id_int {
      -1 -> None
      id -> Some(id)
    }
  }

  let template =
    template.new(
      title,
      description,
      published_id,
      version_id,
      args,
      language,
      raw,
      username,
    )
  #(session_key, template |> debug) |> Ok
}

fn user_decoder() {
  decode2(
    fn(username: String, password: String) { #(username, password) },
    dynamic.field("username", dynamic.string),
    dynamic.field("password", dynamic.string),
  )
}

fn save_decoder() {
  decode3(
    fn(session_key, username, template) { #(session_key, username, template) },
    dynamic.field("sessionKey", dynamic.string),
    dynamic.field("username", dynamic.string),
    dynamic.field("template", dynamic.dynamic),
  )
}

fn template_decoder() {
  decode9(
    fn(
      title,
      description,
      published_id,
      version_id,
      args,
      language,
      raw,
      _date,
      _username,
    ) {
      #(title, description, published_id, version_id, args, language, raw)
    },
    dynamic.field("title", dynamic.string),
    dynamic.field("description", dynamic.string),
    dynamic.field("publishedId", dynamic.int),
    dynamic.field("versionId", dynamic.int),
    dynamic.field("args", dynamic.list(dynamic.string)),
    dynamic.field("language", dynamic.string),
    dynamic.field("raw", dynamic.string),
    dynamic.field("date", dynamic.string),
    dynamic.field("username", dynamic.string),
  )
}

fn browse_decoder() {
  decode3(
    fn(page, language, search) { #(page, language, search) },
    dynamic.field("page", dynamic.int),
    dynamic.field("language", dynamic.string),
    dynamic.field("search", dynamic.string),
  )
}

fn mine_decoder() {
  decode2(
    fn(page, username) { #(page, username) },
    dynamic.field("page", dynamic.int),
    dynamic.field("username", dynamic.string),
  )
}

fn variants_decoder() {
  decode2(
    fn(page, published_id) { #(page, published_id) },
    dynamic.field("page", dynamic.int),
    dynamic.field("publishedId", dynamic.int),
  )
}

pub fn encode_session_key(session_key: SessionKey) -> Json {
  json.object([#("sessionKey", json.string(session_key))])
}

pub fn encode_template(t: Template) -> Json {
  let v_id = case t.version_id {
    Some(v_id) -> v_id
    None -> -1
  }
  let p_id = case t.published_id {
    Some(p_id) -> p_id
    None -> -1
  }
  json.object([
    #("title", json.string(t.title)),
    #("description", json.string(t.description)),
    #("publishedId", json.int(p_id)),
    #("versionId", json.int(v_id)),
    #("args", json.array(t.args, json.string)),
    #("language", json.string(t.language)),
    #("raw", json.string(t.raw)),
    #("date", json.string(t.date)),
    #("username", json.string(t.username)),
  ])
}

pub fn encode_browse(browse) {
  browse
  |> json.array(fn(x) {
    let #(template, creator) = x
    json.object([
      #("template", encode_template(template)),
      #("creator", json.string(creator)),
    ])
  })
}

pub fn encode_mine(drafts, published) {
  json.object([
    #(
      "published",
      drafts
        |> encode_browse
    ),
    #("drafts", published |> json.array(encode_template)),
  ])
}

pub fn encode_browse_err(browse) {
  let code = case browse {
    b_db.GetDBErr(s) -> {
      s |> debug
      "DB_ERR"
    }
  }
  json.string(code)
}

pub fn encode_id(id: Int) -> Json {
  json.object([#("id", json.int(id))])
}

pub fn encode_id2(published_id, version_id) -> Json {
  json.object([
    #("published_id", json.int(published_id)),
    #("version_id", json.int(version_id)),
  ])
}

pub fn encode_save_err(e: SaveErr) {
  let code = case e {
    InvalidSessionKey -> "INVALID_SESSION_KEY"
    SaveDBErr(e) ->
      case e {
        db_t.InvalidUser -> "INVALID_USER"
        db_t.AddDBErr(_) -> "DB_ERR"
      }
  }
  json.string(code)
}

pub fn encode_sign_up_err(e: SignUpErr) {
  let #(code, field, message) = case e {
    UsernameTaken -> #(
      "USERNAME_TAKEN",
      "username",
      "This username is already being used. Please choose a different one.",
    )
    UsernameTooShort -> #(
      "USERNAME_TOO_SHORT",
      "username",
      "Username is too short. A minimum of 5 characters is required.",
    )
    PasswordTooShort -> #(
      "PASSWORD_TOO_SHORT",
      "password",
      "Password is too short. A minimum of 5 characters is required.",
    )
    UsernameWhitespace -> #(
      "USERNAME_WHITESPACE",
      "username",
      "Username cannot contain whitespace. Remove any spaces or tabs from your username.",
    )
    SignUpFailed(s) -> #("SIGNUP_FAILED", "", s)
  }
  jsonify_err(code, field, message)
}

pub fn encode_sign_in_err(e: SignInErr) {
  let #(code, field, message) = case e {
    InvalidPassword -> #(
      "INVALID_PASSWORD",
      "password",
      "Invalid password. Make sure to create an account (Sign Up) if you don't already have one.",
    )
    InvalidUsername -> #(
      "INVALID_USERNAME",
      "password",
      "Invalid username. Make sure to create an account (Sign Up) if you don't already have one. ",
    )
    SignInFailed(s) -> #("SIGNUP_FAILED", "", s)
  }
  jsonify_err(code, field, message)
}

fn jsonify_err(code, field, message) {
  json.object([
    #("code", json.string(code)),
    #("field", json.string(field)),
    #("message", json.string(message)),
  ])
}
