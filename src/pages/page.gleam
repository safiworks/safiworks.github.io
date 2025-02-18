import ctx
import pages/home
import pages/layout

pub fn home(ctx: ctx.UserContext) {
  layout.layout(ctx |> home.page, ctx)
}
