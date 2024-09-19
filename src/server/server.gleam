import server/router.{handle_request}
import gleam/erlang/process.{sleep_forever}
import wisp.{type Request, type Response, configure_logger, random_string, mist_handler}
import mist
import db/db

pub type Context {
  Context(secret: String)
}

pub fn start() {
  configure_logger()
  let secret_key = random_string(64)
  use conn <- db.connect()
  let assert Ok(_) =
    mist_handler(handle_request(_, conn), secret_key)
    |> mist.new
    |> mist.port(80)
    |> mist.start_http
  sleep_forever()
}
