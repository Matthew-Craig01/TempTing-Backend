import users/user.{hash}
import wisp.{random_string}

pub type SessionKey =
  String

pub fn generate() -> SessionKey {
  let secret_key = random_string(64)
  secret_key |> hash
}
