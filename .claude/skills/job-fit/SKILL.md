---
name: job-fit
description: Compare the CV in data/*.yml against a job ad (PDF, markdown, HTML or plain text in jobs/<slug>/), write a requirement-by-requirement fit and gap analysis to jobs/<slug>/fit.md, and on request build a CV tailored to that job. Use when the user adds a job ad, asks how well they match a position, what they are missing, or wants a CV version for a specific job.
argument-hint: "jobs/<slug> [tailor]"
---

# Job fit analysis

Goal: tell the user honestly how well their CV covers a job ad, where the gaps are, and (only when asked) produce a tailored CV for that job. Other agents than Claude Code follow the same steps; AGENTS.md points here.

## Folder convention

```
jobs/<slug>/            slug = company-role, lowercase with hyphens, e.g. example-energy-lead-data-engineer
  ad.pdf | ad.md | ad.html | ad.txt   the job ad as the user saved it (any name works)
  fit.md                the analysis (this skill writes it)
  profile.yml           tailored CV profile (only when the user asks for a tailored CV)
```

- If the user pastes the ad text into the chat, save it as `jobs/<slug>/ad.md` first, with the source (URL or "pasted") and today's date at the top.
- If the user gives only a URL, fetch it if you can and save the readable text as `ad.md`; if fetching fails, ask the user to paste the text or save the page.
- If the argument is a file instead of a folder, use its folder; if the file is not in `jobs/`, create `jobs/<slug>/` and copy it there.

## Analysis steps

1. **Read the ad** in whatever format it is (PDF and HTML directly; for HTML, ignore navigation, cookie banners and other boilerplate). Note the language of the ad.
2. **Read all of `data/*.yml`**, including `internal: true` items and `*_internal` fields: they are valid evidence of experience. Never copy internal details (e.g. real client names) into anything meant for the employer. Also read every `notes` field (on items and the top-level `notes:` list): they are facts the user has confirmed that are not CV text. Use them as evidence (mark them "confirmed, not in CV" in the table) and do not ask again what they already answer. Negative facts ("no experience with X") decide a status too.
3. **Extract the requirements** into groups, in the ad's own words but shortened:
   - Must-have (required, "you have", minimum years …)
   - Nice-to-have (a plus, preferred, bonus)
   - Responsibilities and soft skills (what the role does, how they work)
   - Practicalities (location, remote, language, travel, clearance, start date)
4. **Match each requirement** to the CV and give it one status:
   - ✅ Met — clear evidence in the CV
   - 🟡 Partial — related or weaker evidence (shorter experience, adjacent technology, older)
   - ❌ Missing — no evidence, and nothing suggests it
   - ❔ Not in CV — nothing in the CV, but it is plausible the user has it (e.g. a common tool next to ones listed); ask
   Evidence = item `id`s (e.g. `experience:example-data-sde`, `projects:industrial-lakehouse`, `skills.groups`) and a short quote or paraphrase. Count years from `start` / `end` when the ad asks for years.
5. **Summarise**: must-haves met (✅ + 🟡 counts out of the total), a one-paragraph verdict (realistic, not flattering), the 3–5 strongest selling points for this job, and risks (seniority mismatch, missing must-have, language, location).
6. **Suggest, do not apply**:
   - which experience and projects to lead with (ids, in order);
   - concrete wording changes to `data/cv.yml` as before → after quotes, only based on facts already in the CV or confirmed by the user;
   - ad keywords that are missing from the CV text (matters for ATS screening), split into "you seem to have this, add the word" and "real gap";
   - questions for the user that would change the assessment (the ❔ items).
7. **Write `jobs/<slug>/fit.md`** with the template below, in the language the user writes to you (not necessarily the ad's language). In the chat, give a short summary (verdict, must-have count, top gaps) and the file path; do not paste the whole report.

## User answers → `notes`

When the user answers the questions of an analysis, store the facts right away in `notes` fields of `data/cv.yml`, so that the information lives in one place and the next analysis can use it:

- A fact about an item goes into that item's `notes` list (e.g. `projects:industrial-lakehouse`). A general or negative fact ("no client leadership advisory") goes into the top-level `notes:` list at the end of the file.
- Format: one short sentence per fact, ending with `(confirmed YYYY-MM-DD)`. Record only what the user said; do not make it stronger.
- If a new answer corrects an old note, replace the old one (no contradicting notes).
- Tell the user in the chat which notes you added or changed.

**Promotion to CV text:** when the user accepts a suggestion that is based on a note, make the text change and remove that note in the same edit. A fact is either in the CV text or in a note, never both.

## Rules

- Internal data (`internal`, `*_internal`) is read as evidence, so it is sent to the model provider like the rest of the CV (see README "Privacy and AI agents"). In `fit.md`, refer to internal items by `id` and describe them generically; do not write real client names or other internal details there.
- Be honest. A gap is useful information; do not talk it away. Never invent experience, years, certificates, or numbers.
- Do not change CV text in `data/cv.yml`, existing profiles, or templates on your own. CV wording is the user's decision; suggest it in `fit.md`. Exceptions: the `notes` fields maintained as described above, and text changes the user has explicitly accepted.
- Re-running on the same job: update `fit.md` in place and add a line to a "History" section at the end (date + what changed, e.g. "CV updated with dbt").

## fit.md template

```markdown
# <Role> – <Company>

Source: <URL / file> · Analysed: <YYYY-MM-DD> · CV: data/cv.yml @ <short git hash, from `git log -1 --format=%h -- data/cv.yml`, or "uncommitted">

## Summary

**Must-haves:** <n> ✅ · <n> 🟡 · <n> ❌ · <n> ❔ (of <total>)

<One paragraph: overall fit and the main reason for it.>

**Lead with:** <3–5 strongest points for this job>

**Risks:** <biggest gaps or mismatches>

## Requirements

| # | Requirement | Type | Status | Evidence in CV | Notes |
|---|---|---|---|---|---|
| 1 | <short requirement> | Must | ✅ | `experience:<id>` – <quote/paraphrase> | |

## Gaps

### Real gaps
- <requirement> — <why it is a gap; how big; how it could be closed (course, side project, certificate)>

### Possibly missing from the CV only (please confirm)
- <requirement> — <question for the user>

## Keywords from the ad missing in the CV

- Add if true: <keywords>
- Real gaps: <keywords>

## Suggested CV changes (not applied)

- `<item id>` field `<field>`: "<current text>" → "<suggested text>" — <why>

## Questions for you

1. <question>

## History

- <YYYY-MM-DD>: first analysis
```

## Tailored CV (only when the user asks)

1. Create `jobs/<slug>/profile.yml`, starting from a copy of an existing profile (`profiles/ats.yml` for applications through job portals, `profiles/full.yml` for a direct contact). Keep `include_internal: false`, set `description:` to the role and company, and `lang:` to the ad's language.
2. Select and order content with `filters` (ids, most relevant first; drop items that do not help this application).
3. Use `overrides` for job-specific text without touching `data/cv.yml`; write only facts that are in the CV or confirmed by the user:
   ```yaml
   overrides:
     basics:                      # mappings merge deeply: only the English headline changes
       headline: { en: "Senior Data Engineer & Data Platform Lead" }
     summary_pdf:                 # other languages of the summary stay as they are
       en: "Data engineer with 6 years of ... (aimed at this role)"
     experience:                  # list: patch items by id
       example-data-sde:
         summary: { en: "..." }
   ```
   Mappings are merged deeply and other values replaced. Override the exact key that the data uses (`summary_pdf` if it exists, otherwise `summary`). A tailored headline must still be true: describe roles you have actually had.
4. Build and check: `python build.py pdf --profile jobs/<slug>/profile.yml --lang <lang> --png` → `out/cv_<slug>_<lang>.pdf`. Look at the PNG previews; for single-column profiles also run the ATS text check from AGENTS.md.
5. Tell the user the PDF path and list what you emphasised and changed compared with the base profile.
