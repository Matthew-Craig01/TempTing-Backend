import db/db
import db/session_key as db_s_key
import db/user as db_user
import gleam/bool.{guard}
import gleam/list.{Continue, Stop, fold_until}
import gleam/result.{is_ok, map_error, try}
import gleam/string.{contains, to_graphemes}
import sqlight.{type Connection}
import users/session_key.{type SessionKey}
import users/user.{type User}

pub type SignUpErr {
  UsernameTaken
  UsernameTooShort
  UsernameWhitespace
  PasswordTooShort
  SignUpFailed(String)
}

pub fn sign_up(
  conn: Connection,
  username: String,
  password: String,
) -> Result(SessionKey, SignUpErr) {
  use <- guard(username |> string.length < 5, Error(UsernameTooShort))
  use <- guard(username |> contains_whitespace, Error(UsernameWhitespace))
  use <- guard(password |> string.length < 5, Error(PasswordTooShort))
  use Nil <- try(conn |> add_user_to_db(username, password))
  use user <- try(conn |> get_user_from_db(username))
  let key = session_key.generate()
  use Nil <- try(conn |> add_session_key_to_db(user.id, key))
  key |> Ok
}

fn add_user_to_db(conn, username, password) {
  conn
  |> db_user.add(username, password, "default")
  |> map_error(fn(e) {
    case e {
      db_user.UsernameTaken -> UsernameTaken
      db_user.AddDBErr(s) -> SignUpFailed(s)
    }
  })
}

fn get_user_from_db(conn, username) {
  conn
  |> db_user.get(username)
  |> map_error(fn(e) {
    case e {
      db_user.InvalidUser ->
        SignUpFailed("Invalid User (THIS SHOULD BE IMPOSSIBLE)")
      db_user.GetDBErr(s) -> SignUpFailed(s)
    }
  })
}

fn add_session_key_to_db(conn, user_id, key) {
  conn
  |> db_s_key.add(user_id, key)
  |> map_error(fn(e) {
    let db_s_key.AddDBErr(s) = e
    SignUpFailed(s)
  })
}

fn contains_whitespace(username) -> Bool {
  username
  |> to_graphemes
  |> fold_until(False, fn(_, c) {
    case " \t\n" |> contains(c) {
      True -> True |> Stop
      False -> False |> Continue
    }
  })
}
