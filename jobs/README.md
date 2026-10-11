# jobs

One folder per job ad: `jobs/<slug>/` (slug = company-role, e.g. `acme-senior-data-engineer`).

1. Save the job ad in the folder in any format: `ad.pdf`, `ad.md`, `ad.html`, `ad.txt`.
2. Ask your coding agent for the analysis. In Claude Code: `/job-fit jobs/<slug>` (the skill is in `.claude/skills/job-fit/SKILL.md`); other agents: "analyse jobs/<slug> as described in AGENTS.md".
3. Read `jobs/<slug>/fit.md`: requirement-by-requirement match against `data/cv.yml`, gaps, missing keywords, suggested CV wording, and questions for you.
4. Optional: ask for a tailored CV. The agent writes `jobs/<slug>/profile.yml`, and `python build.py pdf --profile jobs/<slug>/profile.yml --png` builds `out/cv_<slug>_<lang>.pdf`.

**Privacy:** the agent reads your whole CV for the analysis, including internal data, and your answers are stored as `notes` in `data/cv.yml`; see README "Privacy and AI agents". In this template, everything in `jobs/` except this README and the `example-*` folder is gitignored, so your applications do not end up in a public repository. In a private repository you can remove those lines from `.gitignore` to keep the history of your applications.

`example-energy-lead-data-engineer/` is a worked example for the fictional Matti Meikäläinen: a made-up ad, the analysis, and a tailored profile.
