import db/session_key as db_s_key
import db/user as db_user
import gleam/bool.{guard}
import gleam/result.{map_error, try}
import sqlight.{type Connection}
import users/session_key.{type SessionKey}
import users/user.{check_password}

pub type SignInErr {
  InvalidUsername
  InvalidPassword
  SignInFailed(String)
}

pub fn sign_in(
  conn: Connection,
  username: String,
  password: String,
) -> Result(SessionKey, SignInErr) {
  use u <- try(conn |> get_user_from_db(username))
  use <- guard(check_password(password, u.password), Error(InvalidPassword))
  let key = session_key.generate()
  use Nil <- try(conn |> add_session_key_to_db(u.id, key))
  key |> Ok
}

fn add_session_key_to_db(conn, user_id, key) {
  conn
  |> db_s_key.add(user_id, key)
  |> map_error(fn(e) {
    let db_s_key.AddDBErr(s) = e
    SignInFailed(s)
  })
}

pub fn get_user_from_db(conn, username) {
  conn
  |> db_user.get(username)
  |> map_error(fn(e) {
    case e {
      db_user.InvalidUser -> InvalidUsername
      db_user.GetDBErr(s) -> SignInFailed(s)
    }
  })
}
