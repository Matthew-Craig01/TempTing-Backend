import gleam/crypto.{Sha256}
import gleam/bit_array.{base64_encode}

pub type User {
  User(id: Int, username: String, password: String, icon: String)
}

pub fn hash(password) -> String {
  crypto.hash(Sha256, password |> bit_array.from_string) |> base64_encode(True)
}

pub fn check_password(password, db_password) -> Bool{
  password |> hash == db_password
}
