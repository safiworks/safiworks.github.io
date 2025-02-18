import ctx
import gleam/javascript/promise
import lustre
import pages/page

pub fn main() {
  use ctx <- promise.try_await(ctx.fetch())
  let app = lustre.element(ctx |> page.home)

  let assert Ok(_) = lustre.start(app, "#app", Nil)
  promise.resolve(Ok(Nil))
}
