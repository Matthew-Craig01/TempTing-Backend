import gleam/erlang/os
import gleam/io.{debug, println}
import gleam/result.{try}
import sqlight
import wisp.{random_string}

pub fn create_db() {
  let result = {
    use conn <- sqlight.with_connection("temp_ting.db")
    use Nil <- try(create_user_table(conn))
    use Nil <- try(create_template_table(conn))
    use Nil <- try(create_published_table(conn))
    use Nil <- try(create_draft_table(conn))
    use Nil <- try(create_version_table(conn))
    create_session_key_table(conn)
  }
  case result {
    Ok(Nil) -> "Success" |> println
    Error(e) -> e.message |> println
  }
}

fn create_user_table(conn) {
  "Creating users table" |> println
  let sql =
    "
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    password BLOB NOT NULL,
    icon TEXT NOT NULL
);
"
  sqlight.exec(sql, conn)
}

fn create_template_table(conn) {
  "Creating templates table" |> println
  let sql =
    "
DROP TABLE IF EXISTS templates;
CREATE TABLE templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    args TEXT,
    language TEXT NOT NULL,
    raw TEXT NOT NULL,
    date TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
"
  sqlight.exec(sql, conn)
}

fn create_published_table(conn) {
  "Creating published table" |> println
  let sql =
    "
DROP TABLE IF EXISTS published;
CREATE TABLE published (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    numArgs Integer NOT NULL
);
"
  sqlight.exec(sql, conn)
}

fn create_draft_table(conn) {
  "Creating drafts table" |> println
  let sql =
    "
DROP TABLE IF EXISTS drafts;
CREATE TABLE drafts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    template_id INTEGER NOT NULL,
    FOREIGN KEY (template_id) REFERENCES templates(id)
);
"
  sqlight.exec(sql, conn)
}

//Verison = language version of the same published template
fn create_version_table(conn) {
  "Creating versions table" |> println
  let sql =
    "
DROP TABLE IF EXISTS versions;
CREATE TABLE versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    template_id INTEGER NOT NULL,
    creator_id INTEGER NOT NULL,
    published_id INTEGER NOT NULL,
    FOREIGN KEY (template_id) REFERENCES templates(id),
    FOREIGN KEY (creator_id) REFERENCES users(id),
    FOREIGN KEY (published_id) REFERENCES published(id)
);
"
  sqlight.exec(sql, conn)
}

fn create_session_key_table(conn) {
  "Creating sessionKeys table" |> println
  let sql =
    "
DROP TABLE IF EXISTS sessionKeys;
CREATE TABLE sessionKeys (
    key TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
"
  sqlight.exec(sql, conn)
}
