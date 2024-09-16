import wisp.{
  type Request, type Response, handle_head, log_request, method_override,
  rescue_crashes, set_header,
}
import gleam/http.{Options}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(Request) -> Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- log_request(req)
  use <- rescue_crashes
  use req <- cors(req)
  use req <- handle_head(req)
  handle_request(req)
}

fn cors(request: Request, handler: fn(Request) -> Response) -> Response {
  let response = case request.method {
    Options -> wisp.ok()
    _ -> handler(request)
  }
  response |> set_headers
}

fn set_headers(response: Response) -> Response {
  response
  |> set_header("Access-Control-Allow-Origin", "http://localhost:5173")
  |> set_header(
    "Access-Control-Allow-Methods",
    "GET, POST, PUT, DELETE, OPTIONS",
  )
  |> set_header("Access-Control-Allow-Headers", "Content-Type")
}
