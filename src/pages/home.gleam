import ctx
import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/ui
import pages/layout

const about_description = "I'm a self-taught hobbyist software developer and a high-schooler from Egypt, my go-to programming language is Rust."

const languages = [
  #(
    "Rust",
    "my go-to programming language.",
    "https://www.rust-lang.org/logos/rust-logo-128x128-blk.png",
    "https://www.rust-lang.org/",
  ),
  #(
    "Gleam",
    "my second favourite language (this website is powerd by it!).",
    "https://gleam.run/images/lucy/lucy.svg",
    "https://gleam.run/",
  ),
  #(
    "Zig",
    "my third favourite language.",
    "https://raw.githubusercontent.com/ziglang/logo/refs/heads/master/zig-mark.svg",
    "https://ziglang.org/",
  ),
  #(
    "",
    "",
    "https://camo.githubusercontent.com/1c218f47498d8637de949b2339161407b0b31d1a7ad1d3dee50e43fd7b127def/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f656e2f7468756d622f332f33302f4a6176615f70726f6772616d6d696e675f6c616e67756167655f6c6f676f2e7376672f33303070782d4a6176615f70726f6772616d6d696e675f6c616e67756167655f6c6f676f2e7376672e706e67",
    "https://www.java.com/",
  ),
  #(
    "",
    "",
    "https://upload.wikimedia.org/wikipedia/commons/1/19/C_Logo.png",
    "",
  ),
]

const projects = [
  #(
    "SafaOS",
    "A general purpose operating system written in Rust and Zig.",
    "SafaOS/SafaOS",
    "priv/imgs/SafaOS-small.png",
  ),
]

fn project_card(
  name: String,
  description: String,
  repo: String,
  icon_url: String,
) -> element.Element(e) {
  let url = "https://github.com/" <> repo
  let stars_url =
    "https://img.shields.io/github/stars/"
    <> repo
    <> "?style=flat&color="
    <> layout.extra_color

  let license_url =
    "https://img.shields.io/github/license/"
    <> repo
    <> "?style=flat&color="
    <> layout.extra_color

  let info_styles =
    [#("margin", "auto"), #("padding", "10px")]
    |> attribute.style

  let info_div =
    html.div([info_styles], [
      html.a([attribute.href(url)], [
        html.img([attribute.src(stars_url), info_styles]),
      ]),
      html.a([attribute.href(url)], [
        html.img([attribute.src(license_url), info_styles]),
      ]),
    ])

  let styles =
    [#("padding", "2.5rem"), #("text-align", "center"), #("flex-basis", "50%")]
    |> attribute.style

  let icon_styles =
    [
      #("padding", "1rem"),
      #("border-radius", "30%"),
      #("margin", "auto"),
      #("min-width", "10rem"),
      #("max-width", "10rem"),
    ]
    |> attribute.style

  let header_styles =
    [#("font-weight", "bold"), #("font-size", "1.2rem"), #("margin", "auto")]
    |> attribute.style

  let text_styles =
    [#("max-width", "10rem"), #("margin", "auto")]
    |> attribute.style

  let body = {
    [
      html.a([attribute.href(url)], [
        html.img([attribute.src(icon_url), icon_styles]),
      ]),
      html.h2([header_styles], [html.text(name)]),
      html.p([text_styles], [html.text(description)]),
      info_div,
    ]
  }
  html.div([styles], body)
}

fn projects_cards() -> List(element.Element(e)) {
  projects
  |> list.map(fn(p) {
    let #(name, description, repo, icon_url) = p
    project_card(name, description, repo, icon_url)
  })
}

fn language_card(
  language: String,
  description: String,
  icon_url: String,
  url: String,
) -> element.Element(e) {
  let styles =
    [#("padding", "2.5rem"), #("text-align", "center"), #("flex-basis", "50%")]
    |> attribute.style

  let icon_styles =
    [
      #("padding", "1rem"),
      #("border-radius", "30%"),
      #("margin", "auto"),
      #("min-width", "9rem"),
      #("max-width", "9rem"),
    ]
    |> attribute.style

  let header_styles =
    [#("font-weight", "bold"), #("font-size", "1.2rem"), #("margin", "auto")]
    |> attribute.style
  let text_styles =
    [#("max-width", "10rem"), #("margin", "auto")]
    |> attribute.style

  let body = {
    case language == "" {
      False -> [
        html.a([attribute.href(url)], [
          html.img([attribute.src(icon_url), icon_styles]),
        ]),
        html.h2([header_styles], [html.text(language)]),
        html.p([text_styles], [html.text(description)]),
      ]
      True -> [
        html.a([attribute.href(url)], [
          html.img([attribute.src(icon_url), icon_styles]),
        ]),
        html.p([text_styles], [html.text(description)]),
      ]
    }
  }
  html.div([styles], body)
}

fn user_image(ctx: ctx.UserContext) -> element.Element(e) {
  let styles = [
    #("padding", "20px"),
    #("border-radius", "30%"),
    #("min-width", "10rem"),
    #("max-width", "13rem"),
    #("margin", "auto"),
  ]
  html.a([attribute.href("https://github.com/" <> ctx.username)], [
    html.img([attribute.src(ctx.avatar_url), attribute.style(styles)]),
  ])
}

fn languages_cards() -> List(element.Element(e)) {
  languages
  |> list.map(fn(l) {
    let #(name, description, icon_url, url) = l
    language_card(name, description, icon_url, url)
  })
}

fn languages_section() -> element.Element(e) {
  let language_cards_styles =
    [
      #("padding", "2rem"),
      #("display", "flex"),
      #("flex-wrap", "wrap"),
      #("justify-content", "center"),
    ]
    |> attribute.style

  let section_style =
    [
      #("align-items", "center"),
      #("width", "50vw"),
      #("justify-content", "center"),
    ]
    |> attribute.style

  html.section([section_style], [
    html.h1([], [html.text("Languages")]),
    html.div([language_cards_styles], languages_cards()),
  ])
}

fn projects_section() -> element.Element(e) {
  let project_cards_styles =
    [
      #("padding", "2rem"),
      #("display", "flex"),
      #("flex-wrap", "wrap"),
      #("justify-content", "center"),
    ]
    |> attribute.style

  let section_style =
    [
      #("align-items", "center"),
      #("width", "50vw"),
      #("justify-content", "center"),
    ]
    |> attribute.style

  html.section([section_style], [
    html.h1([], [html.text("Projects")]),
    html.div([project_cards_styles], projects_cards()),
  ])
}

fn about_me(ctx: ctx.UserContext) -> element.Element(e) {
  let styles = [
    #("display", "flex"),
    #("justify-content", "center"),
    #("align-items", "center"),
    #("padding-bottom", "2rem"),
    #("width", "60vw"),
    #("margin", "auto"),
  ]
  html.div([attribute.style(styles)], [
    ctx |> user_image,
    html.p([], [
      element.text("Hello, I'm " <> ctx.full_name <> ", " <> about_description),
    ]),
  ])
}

pub fn page(ctx: ctx.UserContext) -> element.Element(e) {
  let styles = [
    #("min-width", "100%"),
    #("min-height", "100%"),
    #("padding", "4rem"),
  ]

  let about_me = ui.centre([], ctx |> about_me)
  let languages = ui.centre([], languages_section())
  let projects = ui.centre([], projects_section())

  html.div([attribute.style(styles)], [about_me, languages, projects])
}
