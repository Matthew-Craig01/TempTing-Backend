import cake.{get_params, get_sql}
import cake/dialect/sqlite_dialect.{
  type ReadQuery, type WriteQuery, query_to_prepared_statement,
  write_query_to_prepared_statement,
}
import cake/param.{BoolParam, FloatParam, IntParam, NullParam, StringParam}
import gleam/dynamic.{type Decoder, element}
import gleam/io.{debug}
import gleam/list.{map}
import gleam/result.{try}
import sqlight.{type Connection}

pub type ID = Int

pub fn select(
  conn: Connection,
  query: ReadQuery,
  decoder: Decoder(t),
) -> Result(List(t), sqlight.Error) {
  let statement = query |> query_to_prepared_statement
  let sql = statement |> get_sql |> debug
  let params =
    statement
    |> get_params
    |> params_to_sqlite
  sqlight.query(sql, conn, params, decoder)
}

pub type SelectLastIdError{
  DBErr(String)
  EmptyTable
}

pub fn select_last_id(
  conn: Connection,
  table: String,
) -> Result(Int, SelectLastIdError) {
  let query = "SELECT MAX(id) FROM " <> table
  let res = sqlight.query(
    query,
    conn,
    [],
    dynamic.element(0, dynamic.int)
  )
  case res |> debug{
     Ok([id, ..]) -> Ok(id)
    Ok([]) -> EmptyTable |> Error
    Error(e) -> e.message |> DBErr |> Error
  }
}

pub fn insert(
  conn: Connection,
  query: WriteQuery(t),
  decoder: Decoder(t),
) -> Result(Nil, sqlight.Error) {
  let statement = query |> write_query_to_prepared_statement
  let sql = statement |> get_sql |> debug
  let params =
    statement
    |> get_params
    |> params_to_sqlite
  use _ <- try(sqlight.query(sql, conn, params, decoder))
  Ok(Nil)
}

fn params_to_sqlite(params) {
  params
  |> map(fn(param) {
    case param {
      BoolParam(param) -> sqlight.bool(param)
      FloatParam(param) -> sqlight.float(param)
      IntParam(param) -> sqlight.int(param)
      StringParam(param) -> sqlight.text(param)
      NullParam -> sqlight.null()
    }
  })
}

pub fn connect(callback) {
  use conn <- sqlight.with_connection("temp_ting.db")
  callback(conn)
}
