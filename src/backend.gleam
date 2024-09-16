import gleam/io.{println}
import argv
import db/create.{create_db}
import wisp.{type Request, type Response}
import server/server

pub fn main() {
  case argv.load().arguments {
   ["create"] -> create_db()
   _ -> server.start()
  }
}
