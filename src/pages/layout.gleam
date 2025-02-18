import ctx
import lustre/attribute
import lustre/element
import lustre/element/html

pub const border_color = "497D74"

pub const extra_color = "A27B5C"

fn footer(ctx: ctx.UserContext) -> element.Element(e) {
  let footer_styles = [
    #("padding", "1rem"),
    #("text-align", "center"),
    #("border-top", "1px solid #" <> border_color),
  ]

  let footer_styles = footer_styles |> attribute.style
  html.footer([footer_styles], [element.text("© 2025 " <> ctx.full_name)])
}

/// Applies the layout to the given page.
pub fn layout(
  page: element.Element(e),
  ctx: ctx.UserContext,
) -> element.Element(e) {
  let styles = [#("width", "100vw"), #("height", "100vh")] |> attribute.style
  html.div([styles], [page, footer(ctx)])
}
