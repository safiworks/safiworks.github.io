import gleam/dynamic/decode
import gleam/fetch
import gleam/http/request
import gleam/javascript/promise
import gleam/json

pub const username = "safiworks"

pub type UserContext {
  UserContext(full_name: String, username: String, avatar_url: String)
}

/// Fetches the user context from the GitHub API.
pub fn fetch() -> promise.Promise(Result(UserContext, fetch.FetchError)) {
  let api_url = "https://api.github.com/users/" <> username
  let assert Ok(request) = request.to(api_url)
  use response <- promise.try_await(fetch.send(request))
  use response <- promise.try_await(fetch.read_text_body(response))

  let decoder = {
    use full_name <- decode.field("name", decode.string)
    use username <- decode.field("login", decode.string)
    use avatar_url <- decode.field("avatar_url", decode.string)
    decode.success(UserContext(
      full_name: full_name,
      username: username,
      avatar_url: avatar_url,
    ))
  }
  let assert Ok(decoded) = json.parse(from: response.body, using: decoder)
  promise.resolve(Ok(decoded))
}
