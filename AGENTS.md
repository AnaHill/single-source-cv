# AGENTS.md — single-source-cv

Instructions for AI coding agents (Claude Code, Codex …) and humans. Read this first.

## What this is

A CV kept as **one source of truth** (`data/cv.yml`, plus any other `data/*.yml`), from which the build generates:

1. **Website markdown** (`out/<name>.md` from every `templates/*.md.j2`), e.g. for GitHub Pages / Jekyll.
2. **PDF CVs** (`out/cv_<profile>_<lang>.pdf`) with Typst. Profiles choose sections, order, filters, and style; every profile is built in every language.
3. The data file itself is also the place to copy from into LinkedIn or company CV systems.

The repository ships with fictional example data (Matti Meikäläinen). The owner of a clone replaces it with their own; see README "Make it yours".

**Privacy:** data may contain internal information (`internal: true`, `*_internal` fields). Never move internal content into public outputs, never add internal profiles to CI artifacts, and do not suggest making a repository with internal data public. Internal data is deliberately kept in the same file as the rest of the CV, so you will see it whenever you read `data/cv.yml` and when you open outputs of `include_internal` profiles. Read only what the task needs, do not quote internal details in chat or in files unless the task requires it, and if the user asks about privacy, point to README "Privacy and AI agents" (what you read is sent to the model provider; instructions are not a security boundary).

## Layout

```
data/cv.yml            ← the CV content (the only place content is edited)
data/*.yml             ← optional extra data files, merged into one namespace
templates/cv.md.j2     ← website page (Jinja2); every templates/*.md.j2 renders to out/<name>.md
templates/cv.typ       ← PDF template (Typst)
templates/labels.yml   ← PDF headings + date words per language; its keys define the languages
profiles/*.yml         ← PDF profiles: layout, filters, overrides, labels, style, publish_as
jobs/<slug>/           ← job ads, fit analyses (fit.md) and tailored profiles (profile.yml)
.claude/skills/        ← agent skills, e.g. job-fit
assets/                ← photo (optional)
fonts/                 ← Poppins (OFL)
build.py               ← the generator
out/                   ← generated files (gitignored)
.github/workflows/     ← CI: builds public outputs as a workflow artifact
```

## Commands

```bash
python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt   # once
python build.py md [--lang LANG]                 # website markdown (default: first language)
python build.py pdf --profile full --lang fi [--png]
python build.py pdf --profile jobs/<slug>/profile.yml [--png]   # profile given as a path
python build.py all [--png] [--skip-internal]    # md + every profile × language
python build.py list                             # profiles with descriptions
```

`--png` writes `out/preview_*.png`. **Always check PDF changes by looking at the PNGs** (page count, overflow, sidebar spilling to the next page).

## Data conventions

- **Languages:** a text value is either a plain string (same in all languages) or a mapping `{en: ..., fi: ...}`. The languages are the top-level keys of `templates/labels.yml`; the first is the default. A missing translation falls back to the default language and the build prints a warning.
- **Channel variant:** `field_web` / `field_pdf` overrides `field` in that channel (e.g. `summary_web`, `title_pdf`, `client_web`). Typical use: emojis only on the web, a shorter text in the PDF.
- **Channel-only items:** a list item with `channels: [web]` or `channels: [pdf]` appears only there (default: everywhere).
- **Internal data:** `internal: true` on an item, or `field_internal` (e.g. `client_internal: Real Client Oy`), is rendered only in profiles with `include_internal: true`. Priority: `_internal` > `_web`/`_pdf` > base field. `field_internal: null` is ignored.
- **Dates:** `start` / `end` as `"YYYY-MM"` or `YYYY`, plus `end: present`. The build adds `period` (web: `Feb 2026 - Present` if the language has `months`, else `2026/02 - Present`; PDF: `2026/02 – Present`). A hand-written `period:` wins. A single `date:` gets `date_fmt`.
- **Tags:** `tags: [...]` on items, used by profile filters. `id:` identifies items for `filters.<list>.ids`.
- **Notes:** `notes: [...]` on an item or as a top-level key = facts the user has confirmed that are not CV text (too small, context, or negative, e.g. "no streaming experience"). Never rendered: `notes` is in `META_KEYS`, so the resolver drops it from every output. The job-fit skill reads them and writes the user's answers into them; when a fact is promoted into CV text, the note is removed in the same edit, so the same fact never lives in two places.
- **Inline markdown** (`**bold**`, `*italic*`, `[text](url)`, `` `code` ``) works in text fields. For the PDF the build converts it to Typst markup and escapes special characters. Relative and anchor links (`#projects`, Liquid) become plain text in the PDF.
- `experience`: `highlights` = bullets (website), `summary` = paragraph (PDF). `org` is optional. An item with a `positions` list is a grouping entry: the PDF renders each position as a sub-entry with its own title, org, period and `summary` (e.g. "Academia 2015–2020" with two roles below).
- **Same background at two levels of detail:** the example data has `academia-summary` (grouping entry with `positions`, `channels: [pdf]`, tag `academia-summary`) and the detailed `university-ra` (tag `academia-detail`). Profiles pick one with `exclude_tags`: `full`, `one-page` and `projects` exclude `academia-detail`; `ats` excludes `academia-summary`.
- `projects`: `title`, `client`, `role`, `industry`, `data`, `highlights` (strings, or `{text, sub: [...]}` for nested bullets), `stack`.
- `skills.groups` = the skills list (`inline: true` → one comma-separated bullet). `skills.chart` = optional bubble chart, positioned by hand (`x`, `y` 0–100, `r` px of a 620 px chart, `cat` = category index).
- Keys in `PLAIN_KEYS` (build.py) are never treated as markup; add a key there if it holds raw values such as colours or IDs.

## Build pipeline (build.py)

1. `load_data()` merges all `data/*.yml` (duplicate top-level keys are an error).
2. `Resolver(channel, lang, include_internal)` picks languages and channel variants, drops items that do not belong to the channel or are internal, and formats dates.
3. **md:** channel `web`, one language; every `templates/*.md.j2` is rendered with the resolved data plus `labels` and `lang`. Jinja delimiters are `<< var >>`, `<% block %>`, `<# comment #>` so Liquid (`{{ }}`, `{% %}`) passes through. A markdown hard line break is written `<< br >>` because editors strip trailing spaces. Undefined variables raise errors (`StrictUndefined`).
4. **pdf:** channel `pdf`; the profile's `filters` (`include_tags`, `exclude_tags`, `ids`, `max`) apply to top-level lists; text is converted to Typst markup → `out/_resolved_<profile>_<lang>.json` → `templates/cv.typ` reads it via `sys.inputs.data`. If the profile has `publish_as`, the PDF is also copied to `out/<publish_as>`.

## PDF template and profiles

- **`layout.mode`:** `sidebar` (default) = coloured sidebar column + main column. `single` = one full-width column on a white page (ATS-friendly); only `layout.main` is rendered, and sections switch style: accent-coloured headings with a thin rule, contact details on one or two lines under the name, skills as text lines, one certification per line.
- `layout.sidebar` / `layout.main` = section order. Sections (the `sections` dictionary at the end of `cv.typ`): `photo, header, summary, contact, skills, skills_chart, experience, projects, projects_link, education, languages, certifications, merits, trainings`. Any section works in either column (`side` handles colours). `projects_link` = only a Projects heading and the link to the full list (`basics.web.projects_url`), for profiles that list no projects (`one-page`).
- Project section heading: profiles that show only some projects (`full`, `ats`) use `labels: {en: {projects: Selected Projects}}` and `style.show_projects_link: true`; `projects` shows all of them with the plain "Projects" heading and no link.
- Entries (experience, projects, education, trainings, awards) show the title on the left and the period right-aligned on the same line (`entry-head(title, when: ...)`).
- `photo`: `basics.photo` image, or a circle with the initials if there is no photo.
- `style` keys (defaults at the top of `cv.typ`): `accent, ink, font, font_size, heading_size` (15, single mode 12), `sidebar_width` (%), `photo_size` (cm), `justify` (default false; left-aligned text also avoids hyphenation), `chart_scale` (default 1.0), `chart_bubble_scale` (PDF-only bubble size factor, default 1.0) and `chart_height` (chart height / width, default 0.52) to tighten the PDF chart without changing the coordinates the website chart also uses, `show_references` (default false), `show_projects_link` (link to `basics.web.projects_url` after the projects, default false), `show_updated`, `show_page_numbers`, `header_links` (single mode: which `basics.links` labels to show under the name; default all).
- `labels: {en: {about: Summary}, ...}` in a profile overrides `labels.yml` for that profile only.
- `publish_as: name.pdf` copies the default-language PDF to `out/name.pdf`; `publish_as: {en: a.pdf, fi: b.pdf}` sets it per language.
- Footer: "Updated <month year>" (build date) and page numbers when there is more than one page; both can be switched off in `style`.
- New section: add `#let s-xxx(side) = ...`, register it in `sections`, branch on `single` if it should look different in one-column mode, and add its heading to every language in `labels.yml`.

## Job fit analysis and tailored CVs

When the user adds a job ad (`jobs/<slug>/ad.pdf|md|html|txt`) or asks how well they fit a position, follow `.claude/skills/job-fit/SKILL.md` (in Claude Code: `/job-fit jobs/<slug>`). In short:

- Write `jobs/<slug>/fit.md`: every requirement of the ad with a status (✅ met, 🟡 partial, ❌ missing, ❔ not in CV) and evidence by item `id`, a realistic verdict, real gaps vs. things missing from the CV text only, missing ATS keywords, suggested wording (not applied), and questions.
- Check for an existing `jobs/*/` folder of the same company and role before creating a new one (the same position is often posted in several places); update that one instead.
- Never invent experience and never edit `data/cv.yml` for a job; suggest changes in `fit.md`.
- A tailored CV is a profile next to the ad, `jobs/<slug>/profile.yml` (`include_internal: false`), with `filters` for selection and order and `overrides` for job-specific text. Build it with `python build.py pdf --profile jobs/<slug>/profile.yml --png` → `out/cv_<slug>_<lang>.pdf`.
- Profile `overrides`: mappings are merged deeply and other values replaced, so `basics: {headline: {en: ...}}` changes only the English headline and `summary_pdf: {en: ...}` keeps the other languages; for a top-level list, `{item_id: {field: value}}` patches those items. Override the exact key the data uses (`summary_pdf` if it exists). Overrides are applied to the raw data before resolving, so language mappings work as usual.
- `jobs/` is gitignored in this template except `jobs/README.md` and `jobs/example-*`.

## Checks

- After a data or template change: `python build.py all --png` must run without errors; look at the PNGs. Keep one-page profiles on one page.
- After a website template change: read the generated `out/*.md`, and if the site already has a published version, diff against it (`git diff --no-index <site>/cv.md out/cv.md`). Differences should be intentional only.
- ATS check for single-column profiles: `pip install pypdf`, then `python -c "from pypdf import PdfReader; print('\n'.join(p.extract_text() for p in PdfReader('out/cv_ats_en.pdf').pages))"`. The text must be in reading order with whole words.

## Writing rules for this repo

- Do not hard-wrap markdown files: one paragraph or list item = one line.
- Do not rewrite the owner's CV content on your own initiative; suggest wording changes and ask first.
