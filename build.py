"""CV generator: data/*.yml -> website markdown (Jinja2) and PDF (Typst).

Usage:
    python build.py md [--lang LANG] [--out DIR]
    python build.py pdf [--profile NAME] [--lang LANG] [--png]
    python build.py all [--png]
    python build.py list

Languages are the top-level keys of templates/labels.yml; the first one is the
default and the fallback for missing translations. See AGENTS.md for the data
conventions.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

import jinja2
import yaml

ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data"
TEMPLATES_DIR = ROOT / "templates"
PROFILES_DIR = ROOT / "profiles"
OUT_DIR = ROOT / "out"

CHANNELS = ("web", "pdf")
META_KEYS = {"channels", "internal"}
# Keys whose values are never treated as inline markup in the PDF
PLAIN_KEYS = {"id", "tags", "email", "phone", "photo", "bg", "border", "start", "end", "date", "cat",
              "period", "date_fmt"}


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------
def load_yaml(path: Path):
    with path.open(encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


# UI strings per language; its keys define the supported languages (first = default)
LABELS: dict = load_yaml(TEMPLATES_DIR / "labels.yml")
LANGS = tuple(LABELS)
DEFAULT_LANG = LANGS[0]


def updated_text(lang: str) -> str:
    """Build date for the footer, month precision: 'September 2026' if the language
    defines `months_long` in labels.yml, otherwise '9/2026'."""
    today = date.today()
    months = LABELS[lang].get("months_long")
    if months:
        return f"{months[today.month - 1]} {today.year}"
    return f"{today.month}/{today.year}"


def load_data() -> dict:
    """Merge every data/*.yml into one namespace (top-level keys must be unique)."""
    data: dict = {}
    for path in sorted(DATA_DIR.glob("*.yml")):
        for key, value in load_yaml(path).items():
            if key in data:
                sys.exit(f"error: top-level key '{key}' defined twice (in {path.name})")
            data[key] = value
    return data


# ---------------------------------------------------------------------------
# Resolving: language, channel variants, internal items, filters, dates
# ---------------------------------------------------------------------------
class Resolver:
    def __init__(self, channel: str, lang: str, include_internal: bool = False):
        self.channel = channel
        self.lang = lang
        self.include_internal = include_internal
        self.warnings: set[str] = set()

    def resolve(self, node, path: str = ""):
        if isinstance(node, dict):
            if node and set(node) <= set(LANGS):
                return self.resolve(self._pick_lang(node, path), path)
            return self._resolve_dict(node, path)
        if isinstance(node, list):
            return [self.resolve(item, f"{path}[{i}]") for i, item in enumerate(node) if self._keep(item)]
        return node

    def _pick_lang(self, node: dict, path: str):
        if self.lang in node:
            return node[self.lang]
        if self.lang != DEFAULT_LANG:
            self.warnings.add(f"missing '{self.lang}' translation: {path}")
        return node.get(DEFAULT_LANG)

    def _keep(self, item) -> bool:
        if not isinstance(item, dict):
            return True
        if "channels" in item and self.channel not in item["channels"]:
            return False
        if item.get("internal") and not self.include_internal:
            return False
        return True

    def _resolve_dict(self, node: dict, path: str) -> dict:
        # For each base key pick the most specific variant: internal > channel > base
        chosen: dict[str, tuple[int, object]] = {}
        for key, value in node.items():
            if key in META_KEYS:
                continue
            base, _, suffix = key.rpartition("_")
            if suffix in CHANNELS and base:
                if suffix != self.channel:
                    continue
                prio = 1
            elif suffix == "internal" and base:
                if not self.include_internal or value is None:
                    continue
                prio = 2
            else:
                base, prio = key, 0
            if base not in chosen or prio > chosen[base][0]:
                chosen[base] = (prio, value)
        out = {k: self.resolve(v, f"{path}.{k}" if path else k) for k, (_, v) in chosen.items()}
        self._add_dates(out)
        return out

    # -- dates --------------------------------------------------------------
    # web: "Feb 2026" if the language defines `months` in labels.yml; pdf: "2026/02"
    def fmt_date(self, value) -> str:
        if value is None:
            return ""
        s = str(value)
        labels = LABELS[self.lang]
        if s.lower() == "present":
            return labels.get("present", "Present")
        m = re.fullmatch(r"(\d{4})-(\d{2})", s)
        if not m:
            return s
        year, month = m.group(1), int(m.group(2))
        if self.channel == "web" and labels.get("months"):
            return f"{labels['months'][month - 1]} {year}"
        return f"{year}/{month:02d}"

    def _add_dates(self, d: dict) -> None:
        if "start" in d and "period" not in d:
            start, end = self.fmt_date(d["start"]), self.fmt_date(d.get("end"))
            sep = " - " if self.channel == "web" else " – "
            d["period"] = start if (not end or end == start) else f"{start}{sep}{end}"
        if "date" in d:
            d["date_fmt"] = self.fmt_date(d["date"])
        if "period" in d:
            d["period"] = str(d["period"])


def apply_filters(data: dict, filters: dict) -> dict:
    """Profile filters for top-level lists: include_tags, exclude_tags, ids, max."""
    for section, rules in (filters or {}).items():
        items = data.get(section)
        if not isinstance(items, list):
            continue
        rules = rules or {}
        if "ids" in rules:
            by_id = {it.get("id"): it for it in items}
            items = [by_id[i] for i in rules["ids"] if i in by_id]
        if "include_tags" in rules:
            want = set(rules["include_tags"])
            items = [it for it in items if want & set(it.get("tags", []))]
        if "exclude_tags" in rules:
            drop = set(rules["exclude_tags"])
            items = [it for it in items if not drop & set(it.get("tags", []))]
        if rules.get("max"):
            items = items[: rules["max"]]
        data[section] = items
    return data


# ---------------------------------------------------------------------------
# Inline markdown -> Typst markup (PDF channel)
# ---------------------------------------------------------------------------
_MD_TOKEN = re.compile(
    r'\[(?P<ltext>[^\]]+)\]\((?P<url>[^)\s]+)(?:\s+"[^"]*")?\)'
    r"|\*\*(?P<bold>.+?)\*\*"
    r"|(?<![\w*])\*(?P<ital>[^*\s][^*]*?)\*"
    r"|`(?P<code>[^`]+)`"
)
_TYPST_SPECIAL = re.compile(r"([\\#$*_`<>@\[\]~/=])")


def _escape(text: str) -> str:
    text = _TYPST_SPECIAL.sub(r"\\\1", text)
    return re.sub(r"(^|\n)([-+])", r"\1\\\2", text)  # list markers at line start


def md_to_typst(text: str) -> str:
    out, pos = [], 0
    for m in _MD_TOKEN.finditer(text):
        out.append(_escape(text[pos:m.start()]))
        if m.group("url"):
            label, url = md_to_typst(m.group("ltext")), m.group("url")
            if re.match(r"(https?:|mailto:)", url):
                out.append(f'#link("{url}")[{label}]')
            else:  # site-relative / anchor links make no sense in a PDF
                out.append(label)
        elif m.group("bold"):
            out.append(f"*{md_to_typst(m.group('bold'))}*")
        elif m.group("ital"):
            out.append(f"_{md_to_typst(m.group('ital'))}_")
        else:
            out.append(f"#raw({json.dumps(m.group('code'))})")
        pos = m.end()
    out.append(_escape(text[pos:]))
    return "".join(out)


def to_typst_markup(node, key: str = ""):
    if isinstance(node, dict):
        return {k: to_typst_markup(v, k) for k, v in node.items()}
    if isinstance(node, list):
        return [to_typst_markup(v, key) for v in node]
    if isinstance(node, str) and key not in PLAIN_KEYS and not key.endswith("url"):
        return md_to_typst(node)
    return node


# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------
def report(resolver: Resolver) -> None:
    for w in sorted(resolver.warnings):
        print(f"  warning: {w}")


def build_md(out_dir: Path, lang: str = DEFAULT_LANG) -> None:
    """Render every templates/*.md.j2 with the web channel."""
    resolver = Resolver("web", lang)
    data = resolver.resolve(load_data())
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(TEMPLATES_DIR),
        # Custom delimiters so Jekyll/Liquid {{ }} and {% %} pass through untouched
        block_start_string="<%", block_end_string="%>",
        variable_start_string="<<", variable_end_string=">>",
        comment_start_string="<#", comment_end_string="#>",
        trim_blocks=True, lstrip_blocks=True, keep_trailing_newline=True,
        undefined=jinja2.StrictUndefined,
    )
    env.filters["tojson"] = lambda v: json.dumps(v, ensure_ascii=False)
    out_dir.mkdir(parents=True, exist_ok=True)
    for tpl in sorted(TEMPLATES_DIR.glob("*.md.j2")):
        target = out_dir / tpl.name.removesuffix(".j2")
        text = env.get_template(tpl.name).render(**data, labels=LABELS[lang], lang=lang)
        target.write_text(text, encoding="utf-8", newline="\n")
        print(f"wrote {target}")
    report(resolver)


def publish_as(profile: dict, lang: str) -> str | None:
    """Published file name for this profile + language, if any.

    `publish_as: name.pdf` applies to the default-language version only;
    `publish_as: {en: a.pdf, fi: b.pdf}` sets it per language.
    """
    value = profile.get("publish_as")
    if isinstance(value, dict):
        return value.get(lang)
    return value if lang == DEFAULT_LANG else None


def build_pdf(profile_name: str, lang: str | None, png: bool = False) -> None:
    import typst

    profile_path = PROFILES_DIR / f"{profile_name}.yml"
    if not profile_path.exists():
        sys.exit(f"error: no such profile: {profile_path}")
    profile = load_yaml(profile_path)
    lang = lang or profile.get("lang", DEFAULT_LANG)
    if lang not in LANGS:
        sys.exit(f"error: language '{lang}' is not defined in templates/labels.yml")
    resolver = Resolver("pdf", lang, profile.get("include_internal", False))
    data = resolver.resolve(load_data())
    data = apply_filters(data, profile.get("filters"))
    labels = dict(LABELS[lang])
    labels.update((profile.get("labels") or {}).get(lang) or {})  # per-profile heading overrides
    doc = {
        "lang": lang,
        "updated": updated_text(lang),
        "profile": {"name": profile_name, "layout": profile.get("layout", {}), "style": profile.get("style", {})},
        "labels": to_typst_markup(labels),
        "cv": to_typst_markup(data),
    }
    OUT_DIR.mkdir(exist_ok=True)
    resolved = OUT_DIR / f"_resolved_{profile_name}_{lang}.json"
    resolved.write_text(json.dumps(doc, ensure_ascii=False, indent=1), encoding="utf-8")

    kwargs = dict(
        root=str(ROOT),
        font_paths=[str(ROOT / "fonts")],
        sys_inputs={"data": "/" + resolved.relative_to(ROOT).as_posix()},
    )
    template = str(TEMPLATES_DIR / "cv.typ")
    target = OUT_DIR / f"cv_{profile_name}_{lang}.pdf"
    typst.compile(template, output=str(target), **kwargs)
    print(f"wrote {target}")
    publish_name = publish_as(profile, lang)
    if publish_name:
        published = OUT_DIR / publish_name
        published.write_bytes(target.read_bytes())
        print(f"wrote {published} (publish_as)")
    if png:
        pages = typst.compile(template, format="png", ppi=110, **kwargs)
        pages = pages if isinstance(pages, list) else [pages]
        for i, page in enumerate(pages, 1):
            p = OUT_DIR / f"preview_{profile_name}_{lang}_{i}.png"
            p.write_bytes(page)
            print(f"wrote {p}")
    report(resolver)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("target", choices=["md", "pdf", "all", "list"])
    ap.add_argument("--profile", default="full", help="PDF profile name (profiles/<name>.yml)")
    ap.add_argument("--lang", choices=LANGS,
                    help=f"language (md default: {DEFAULT_LANG}; pdf default: profile's lang)")
    ap.add_argument("--out", type=Path, default=OUT_DIR, help="output dir for markdown")
    ap.add_argument("--png", action="store_true", help="also write PNG page previews")
    ap.add_argument("--skip-internal", action="store_true",
                    help="all: skip profiles with include_internal: true (e.g. in CI)")
    args = ap.parse_args()

    if args.target == "list":
        for p in sorted(PROFILES_DIR.glob("*.yml")):
            print(f"{p.stem:12} {load_yaml(p).get('description', '')}")
        return
    if args.target in ("md", "all"):
        build_md(args.out, args.lang or DEFAULT_LANG)
    if args.target == "pdf":
        build_pdf(args.profile, args.lang, args.png)
    if args.target == "all":
        for p in sorted(PROFILES_DIR.glob("*.yml")):
            if args.skip_internal and load_yaml(p).get("include_internal"):
                print(f"skipped {p.stem} (include_internal)")
                continue
            for lang in LANGS:
                build_pdf(p.stem, lang, args.png)


if __name__ == "__main__":
    main()
