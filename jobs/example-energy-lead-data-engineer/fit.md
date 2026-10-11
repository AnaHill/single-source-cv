# Lead Data Engineer – Example Energy Oy

Source: `jobs/example-energy-lead-data-engineer/ad.md` (fictional example ad) · Analysed: 2026-10-11 · CV: data/cv.yml @ f70344d

## Summary

**Must-haves:** 5 ✅ · 2 🟡 · 0 ❌ · 0 ❔ (of 7)

A strong match. Matti has 6.5 years of data engineering on exactly the requested core stack (Azure, Databricks, PySpark, Delta Lake, Python, SQL), has led a lakehouse build as Lead Data Engineer, mentors junior engineers, and has energy-sector time-series experience, which the ad lists as a plus. The two partial must-haves (data modelling, CI/CD and infrastructure as code) are probably more a CV-wording problem than a skills gap, but the CV does not prove them today. The clearest real gap is streaming, which is only a nice-to-have but appears in the responsibilities too ("batch and streaming pipelines").

**Lead with:**
- Lakehouse lead role: medallion lakehouse on Databricks, a dozen pipelines consolidated, nightly batch from five hours to 40 minutes (`projects:industrial-lakehouse`)
- Energy-sector time-series data quality work with a measurable result (−80 % manual fixes) (`projects:energy-dq`)
- People leadership: mentoring three juniors, internal study group, Colleague of the Year 2025 (`experience:example-data-sde`, `awards`)
- Databricks Certified Data Engineer Associate (`certifications`)

**Risks:**
- The role leads a team of four; the CV shows mentoring and a technical lead role, but not formal team leadership.
- No streaming experience in the CV.
- CI/CD and infrastructure as code are listed only as tools (Azure DevOps, Terraform), not as something Matti has set up or owned.

## Requirements

| # | Requirement | Type | Status | Evidence in CV | Notes |
|---|---|---|---|---|---|
| 1 | 5+ years of data engineering | Must | ✅ | `experience:sample-analytics-de` 2020/03–2023/12, `experience:example-data-sde` 2024/01– | ~6.5 years, plus research data work before that |
| 2 | Azure and Databricks (PySpark, Delta Lake) | Must | ✅ | `projects:industrial-lakehouse` stack Databricks, PySpark, Delta Lake, ADF; Databricks DE Associate | |
| 3 | Python and SQL | Must | ✅ | `skills.groups`; `projects:energy-dq`, `projects:retail-analytics` | |
| 4 | Data modelling (dimensional or Data Vault) | Must | 🟡 | "Data modeling" only in `skills.chart`; medallion design in `projects:industrial-lakehouse`; warehouse migration in `projects:public-sector-reporting` | No named method; see question 1 |
| 5 | CI/CD and infrastructure as code | Must | 🟡 | Azure DevOps in several stacks, Terraform in `skills.groups` (Other) | Tools listed, ownership not shown; see question 2 |
| 6 | Leading or mentoring engineers | Must | ✅ | `experience:example-data-sde` "mentor three junior engineers"; role Lead Data Engineer in `projects:industrial-lakehouse` | Mentoring yes; formal team lead not shown |
| 7 | Fluent Finnish and English | Must | ✅ | `languages`: Finnish mother tongue, English C1 | |
| 8 | Streaming (Kafka, Event Hubs, Structured Streaming) | Nice | ❌ | – | Also in responsibilities |
| 9 | Energy sector or time-series data | Nice | ✅ | `projects:energy-dq` – time-series metering data, energy company | |
| 10 | Unity Catalog or governance tooling | Nice | ❔ | Data quality yes (`projects:energy-dq` Great Expectations), governance tooling not mentioned | See question 3 |
| 11 | Power BI | Nice | ✅ | `projects:retail-analytics`, `projects:public-sector-reporting`, `skills.groups` | |
| 12 | Databricks or Azure DE certification | Nice | ✅ | Databricks Certified Data Engineer Associate (2025) | Azure only at fundamentals level |
| 13 | Lead lakehouse design and development | Resp. | ✅ | `projects:industrial-lakehouse` | |
| 14 | Batch and streaming pipelines | Resp. | 🟡 | Batch: `projects:industrial-lakehouse`, `projects:retail-analytics` | Streaming missing (#8) |
| 15 | Own CI/CD and IaC for the platform | Resp. | 🟡 | As #5 | |
| 16 | Coach and lead a team of four | Resp. | 🟡 | As #6 | |
| 17 | Drive data governance and data quality | Resp. | 🟡 | Data quality strong (`projects:energy-dq`, `experience:sample-analytics-de`); governance as #10 | |
| 18 | Helsinki, hybrid 2 days on site | Practical | ✅ | `basics.location`: Helsinki | |

## Gaps

### Real gaps
- **Streaming** (#8, #14): nothing in the CV. Medium-sized gap for this role because the responsibilities mention streaming pipelines. Can be narrowed with a small Spark Structured Streaming + Event Hubs side project or the relevant parts of the Databricks Data Engineer Professional certification.

### Possibly missing from the CV only (please confirm)
- **Data modelling method** (#4): did the lakehouse or the warehouse migration use dimensional modelling (star schemas) or Data Vault?
- **CI/CD and IaC ownership** (#5, #15): has Matti set up deployment pipelines or written the Terraform for a platform, rather than only used them?
- **Team leadership** (#6, #16): was "Lead Data Engineer" in the lakehouse project a lead of other engineers? How many?
- **Governance tooling** (#10, #17): Unity Catalog, access control, lineage?

## Keywords from the ad missing in the CV

- Add if true: dimensional modelling / Data Vault, CI/CD, infrastructure as code, GitHub Actions, Unity Catalog, data governance, team lead
- Real gaps: streaming, Kafka, Azure Event Hubs, Spark Structured Streaming

## Suggested CV changes (not applied)

- `projects:industrial-lakehouse` highlights: add, if true, "Led a team of N engineers" and "Set up CI/CD with Azure DevOps and the platform infrastructure with Terraform" — the role is already titled Lead, this makes it concrete.
- `projects:industrial-lakehouse` highlights: "Designed a medallion-architecture lakehouse …" → "Designed a medallion-architecture lakehouse with dimensional gold-layer models on Databricks …" (only if the gold layer is dimensional) — answers must-have #4 directly.
- `skills.groups` Data engineering: add "CI/CD, Terraform" (move Terraform from Other) and "Unity Catalog" if used — keywords for ATS screening.

## Questions for you

1. Which data modelling method did you use in the lakehouse or the warehouse migration?
2. Have you built CI/CD pipelines or written Terraform yourself? For which project?
3. Have you used Unity Catalog or another governance tool?
4. Did you lead other engineers in the lakehouse project, and how many?

## History

- 2026-10-11: first analysis
