// CV PDF template (Typst). Rendered by `python build.py pdf`.
// Input: sys.inputs.data -> JSON produced by build.py (already resolved for
// language, channel "pdf" and profile filters; text fields are Typst markup).
//
// Two layout modes (profile `layout.mode`):
//   sidebar (default) - coloured sidebar column + main column
//   single            - one full-width column, plain white page (ATS friendly);
//                       only `layout.main` is rendered

#let doc = json(sys.inputs.at("data"))
#let cv = doc.cv
#let L = doc.labels
#let layout-cfg = doc.profile.layout
#let style = doc.profile.style
#let single = layout-cfg.at("mode", default: "sidebar") == "single"

// ---------------------------------------------------------------- helpers
#let m(s) = if s == none { [] } else { eval(str(s), mode: "markup") }
#let has(d, k) = type(d) == dictionary and d.at(k, default: none) not in (none, "", ())
#let st(k, default) = style.at(k, default: default)

#let css-color(s) = {
  if s.starts-with("rgba") {
    let p = s.slice(5, -1).split(",").map(x => float(x.trim()))
    rgb(int(p.at(0)), int(p.at(1)), int(p.at(2)), int(p.at(3) * 255))
  } else { rgb(s) }
}

// ---------------------------------------------------------------- style
#let accent = rgb(st("accent", "#1f5fc2"))
#let ink = rgb(st("ink", "#3a2e28"))
#let sidebar-w = st("sidebar_width", 38.5) * 1%
#let base-size = st("font_size", 9.5) * 1pt
#let head-size = st("heading_size", if single { 12 } else { 15 }) * 1pt
#let font = st("font", "Poppins")
#let show-updated = st("show_updated", true)
#let show-page-numbers = st("show_page_numbers", true)
#let show-references = st("show_references", false)
#let chart-scale = st("chart_scale", 1.0)
// secondary text (dates, meta lines); sidebar text sits on the accent colour
#let muted(side) = if side { rgb(255, 255, 255, 215) } else { luma(105) }

#set document(title: cv.basics.name + " – CV", author: cv.basics.name)

#set page(
  paper: "a4",
  margin: if single { (top: 1.4cm, bottom: 1.5cm, x: 1.8cm) } else { (top: 1.1cm, bottom: 1.3cm, x: 0pt) },
  background: if not single { place(left + top, rect(width: sidebar-w, height: 100%, fill: accent)) },
  footer-descent: 40%,
  footer: context {
    let total = counter(page).final().first()
    let parts = ()
    if show-updated { parts.push([#L.updated #doc.updated]) }
    if show-page-numbers and total > 1 { parts.push([#counter(page).display() / #total]) }
    if parts.len() > 0 {
      align(right, pad(right: if single { 0pt } else { 0.75cm },
        text(size: 7.5pt, fill: luma(130), parts.join("  ·  "))))
    }
  },
)
// hyphenation follows justification (Typst default), so left-aligned text keeps words whole
#set text(font: font, size: base-size, fill: ink, lang: doc.lang)
#set par(leading: 0.55em, spacing: 0.7em, justify: st("justify", false))
#set list(indent: 0.6em, body-indent: 0.5em, spacing: 0.45em)
#show link: it => if single { text(fill: accent, it) } else { underline(it) }

// ---------------------------------------------------------------- building blocks
#let sec-head(title, side) = {
  if single {
    block(above: 1.15em, below: 0.6em, sticky: true, {
      text(size: head-size, weight: "bold", fill: accent, title)
      v(-0.65em)
      line(length: 100%, stroke: 0.6pt + accent)
    })
  } else {
    let c = if side { white } else { ink }
    block(above: 1.2em, below: 0.6em, sticky: true, {
      text(size: head-size, weight: "bold", fill: c, title)
      v(-0.7em)
      line(length: if side { 90% } else { 100% }, stroke: 1.1pt + c)
    })
  }
}

// Entry title on the left, date (`when`) right-aligned on the same line.
// A long title wraps inside its own column so the date stays at the right edge.
#let entry-head(title, when: none, side: false) = block(below: 0.45em, sticky: true, {
  let t = text(weight: "bold", size: base-size * 1.08, title)
  if when in (none, "") { t } else {
    grid(
      columns: (1fr, auto), column-gutter: 0.9em, align: (left + top, right + top),
      t, pad(top: 0.1em, text(size: base-size * 0.95, fill: muted(side), when)),
    )
  }
})

// ---------------------------------------------------------------- sections
// Round photo; without `basics.photo` a circle with the initials is drawn instead
// (remove `photo` from the profile layout to show nothing)
#let s-photo(side) = {
  let size = st("photo_size", 5.6) * 1cm
  let fg = if side { white } else { accent }
  let body = if has(cv.basics, "photo") { image("/" + cv.basics.photo, width: 100%) } else {
    let initials = cv.basics.name.split(regex("[\s-]+")).map(w => upper(w.first())).join()
    box(width: 100%, height: 100%, fill: fg.transparentize(85%),
      align(center + horizon, text(size: size * 0.32, weight: "bold", fill: fg, initials)))
  }
  align(center, box(width: size, height: size, radius: 50%, clip: true, stroke: 2pt + fg, body))
}

#let s-header(side) = if single {
  block(below: 0.35em, text(size: 21pt, weight: "bold", cv.basics.name))
  block(below: 0.5em, text(size: 11pt, weight: "semibold", fill: accent, m(cv.basics.headline)))
} else {
  block(below: 0.55em, text(size: 26pt, weight: "extrabold", upper(cv.basics.name)))
  block(below: 0.6em, text(size: 10.5pt, weight: "semibold", tracking: 2pt, upper(m(cv.basics.headline))))
}

#let s-summary(side) = if has(cv, "summary") {
  sec-head(L.about, side)
  m(cv.summary)
}

// display form of a URL for print: no scheme, no "www.", no trailing slash
#let short-url(u) = u.replace(regex("^https?://(www\.)?"), "").trim("/", at: end)

#let s-contact(side) = {
  let b = cv.basics
  if single {
    // one or two lines under the name, no heading
    let row1 = ()
    if has(b, "location") { row1.push(m(b.location)) }
    row1.push(b.phone)
    row1.push(link("mailto:" + b.email, b.email))
    let wanted = st("header_links", none)
    let links = b.at("links", default: ()).filter(l => wanted == none or l.label in wanted)
    block(below: 0.4em, text(size: base-size * 0.98, {
      row1.join("  ·  ")
      if links.len() > 0 { linebreak(); links.map(l => link(l.url, short-url(l.url))).join("  ·  ") }
    }))
  } else {
    sec-head(L.contact, side)
    [*#L.phone:* #b.phone \ ]
    [*#L.email:* #link("mailto:" + b.email, b.email) \ ]
    if has(b, "location") [*#L.location:* #m(b.location)]
    if has(b, "links") {
      v(0.8em)
      for l in b.links [#m(l.label): #link(l.url, m(l.text)) \ ]
    }
    if show-references { v(0.4em); m(L.references) }
  }
}

#let s-skills(side) = if has(cv, "skills") and has(cv.skills, "groups") {
  sec-head(L.skills, side)
  if single {
    block(breakable: false, for g in cv.skills.groups {
      block(below: 0.45em)[*#m(g.name):* #g.items.map(m).join(", ")]
    })
  } else {
    for g in cv.skills.groups {
      block(below: 0.4em, sticky: true, text(weight: "semibold", size: base-size * 1.1, m(g.name)))
      if g.at("inline", default: false) { list(g.items.map(m).join(", ")) } else { list(..g.items.map(m)) }
    }
  }
}

#let s-skills-chart(side) = if has(cv, "skills") and has(cv.skills, "chart") {
  let ch = cv.skills.chart
  let cats = ch.categories
  block(above: 1em, below: 1em, layout(size => {
    let w = size.width * chart-scale
    let s = w / 620pt * 0.95  // chart.js px -> pt scale
    let h = w * 0.52
    let inner = 24pt * s
    align(center, box(width: w, height: h, {
      for it in ch.items {
        let c = cats.at(it.cat)
        let rr = it.r * s * 1pt
        let cx = inner + (w - 2 * inner) * it.x / 100
        let cy = inner + (h - 2 * inner) * (1 - it.y / 100)
        place(dx: cx - rr, dy: cy - rr, circle(radius: rr, fill: css-color(c.bg), stroke: 1.2pt + css-color(c.border)))
        let fs = calc.max(9, calc.round(it.r * 0.27)) * s * 1pt
        place(dx: cx - rr, dy: cy - rr, box(width: 2 * rr, height: 2 * rr,
          align(center + horizon, text(fill: white, weight: "bold", size: fs,
            it.label.split("\n").map(m).join(linebreak())))))
      }
    }))
    align(center, {
      for c in cats {
        box(inset: (x: 0.5em), [#box(width: 0.9em, height: 0.6em, fill: css-color(c.bg), stroke: 1pt + css-color(c.border)) #text(size: base-size * 0.85, fill: muted(side), m(c.label))])
      }
    })
  }))
}

#let s-experience(side) = if has(cv, "experience") {
  sec-head(L.experience, side)
  for x in cv.experience {
    block(breakable: false, below: 1.0em, {
      entry-head([#m(x.title), #m(x.org)], when: x.at("period", default: none), side: side)
      if has(x, "summary") { m(x.summary) }
      else if has(x, "highlights") { list(..x.highlights.map(m)) }
    })
  }
}

#let s-projects(side) = if has(cv, "projects") {
  sec-head(L.projects, side)
  for p in cv.projects {
    block(breakable: false, below: 1.0em, {
      entry-head(m(p.title), when: p.at("period", default: none), side: side)
      let meta = (m(p.client), [#L.role: #m(p.role)])
      if has(p, "industry") { meta.push([#L.industry: #m(p.industry)]) }
      block(below: 0.35em, text(size: base-size * 0.92, fill: muted(side), meta.join("  ·  ")))
      list(..p.highlights.map(h => if type(h) == dictionary {
        [#m(h.text) #list(..h.sub.map(m))]
      } else { m(h) }))
      if has(p, "stack") {
        block(above: 0.35em, text(size: base-size * 0.92, [*#L.stack:* #p.stack.map(m).join(", ")]))
      }
    })
  }
}

#let s-education(side) = if has(cv, "education") {
  sec-head(L.education, side)
  for e in cv.education {
    block(breakable: false, below: 0.85em, {
      let when = if has(e, "date_fmt") { e.date_fmt } else { e.at("period", default: none) }
      entry-head(
        [#m(e.degree)#if has(e, "degree_note") [ #text(weight: "regular", m(e.degree_note))]],
        when: when, side: side,
      )
      m(e.school)
      if has(e, "place") [, #m(e.place)]
      if has(e, "details") [ \ #m(e.details)]
    })
  }
}

#let s-languages(side) = if has(cv, "languages") {
  sec-head(L.languages, side)
  for l in cv.languages { block(below: 0.4em)[*#m(l.name)*: #m(l.level)] }
}

#let s-certifications(side) = if has(cv, "certifications") {
  sec-head(L.certifications, side)
  let credly = has(cv.basics, "web") and has(cv.basics.web, "credly_url")
  if single {
    // one certification per line: name (issuer, note) ... date
    grid(
      columns: (1fr, auto), column-gutter: 0.9em, row-gutter: 0.5em, align: (left, right),
      ..cv.certifications.map(c => (
        [#m(c.name) #text(fill: muted(side), [(#m(c.issuer)#if has(c, "note") [, #m(c.note)])])],
        text(fill: muted(side), c.at("date_fmt", default: "")),
      )).flatten(),
    )
    if credly { block(above: 0.6em, [#L.certifications_more #link(cv.basics.web.credly_url)[Credly]]) }
  } else {
    if credly { block(below: 0.9em, [#L.certifications_more #link(cv.basics.web.credly_url)[Credly]]) }
    // group by issuer, in order of first appearance
    let issuers = ()
    for c in cv.certifications { if c.issuer not in issuers { issuers.push(c.issuer) } }
    for i in issuers {
      block(breakable: false, below: 0.9em, {
        text(weight: "bold", m(i))
        for c in cv.certifications.filter(c => c.issuer == i) [ \ #m(c.name)]
      })
    }
  }
}

#let s-merits(side) = {
  sec-head(L.merits, side)
  let item(title, body, when: none) = block(breakable: false, below: 0.85em, {
    entry-head(title, when: when, side: side)
    body
  })
  for a in cv.at("awards", default: ()) {
    item(m(a.title), list(m(a.description)), when: str(a.year))
  }
  for x in cv.at("merits", default: ()) {
    item(m(x.title), if has(x, "items") { list(..x.items.map(m)) } else { m(x.text) })
  }
  if has(cv, "hobbies") { item(L.hobbies, m(cv.hobbies)) }
}

#let s-trainings(side) = if has(cv, "trainings") {
  sec-head(L.trainings, side)
  for t in cv.trainings {
    block(breakable: false, below: 0.85em, {
      entry-head([#m(t.title), #m(t.org)], when: t.at("period", default: none), side: side)
      m(t.description)
    })
  }
}

#let sections = (
  photo: s-photo, header: s-header, summary: s-summary, contact: s-contact,
  skills: s-skills, skills_chart: s-skills-chart, experience: s-experience,
  projects: s-projects, education: s-education, languages: s-languages,
  certifications: s-certifications, merits: s-merits, trainings: s-trainings,
)

#let render(names, side) = for n in names {
  if n not in sections { panic("unknown section in profile: " + n) }
  (sections.at(n))(side)
}

// ---------------------------------------------------------------- page
#if single {
  render(layout-cfg.at("main", default: ()), false)
} else {
  grid(
    columns: (sidebar-w, 1fr),
    {
      set text(fill: white, size: base-size * 1.02)
      show link: set text(fill: white)
      pad(left: 0.55cm, right: 0.35cm, render(layout-cfg.at("sidebar", default: ()), true))
    },
    {
      pad(left: 0.45cm, right: 0.75cm, render(layout-cfg.at("main", default: ()), false))
    },
  )
}
