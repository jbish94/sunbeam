#!/usr/bin/env python3
"""Generate static legal pages in web/ from assets/legal/*.md.

The app stores its legal documents as markdown assets (rendered in-app
by LegalDocumentScreen). App stores additionally require a public URL
for the privacy policy, so this script converts the same markdown into
self-contained HTML pages that Vercel serves statically (the filesystem
route handler runs before the SPA rewrite).

Run from the repo root after editing anything in assets/legal/:

    python3 scripts/generate_legal_pages.py
"""

import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

PAGES = [
    ("privacy_policy.md", "privacy.html", "Privacy Policy"),
    ("terms_of_service.md", "terms.html", "Terms of Service"),
    ("medical_disclaimer.md", "disclaimer.html", "Medical Disclaimer"),
]

STYLE = """
  :root {
    --bg: #faf8f5; --ink: #26221c; --soft: #6d675e;
    --accent: #e07a2f; --rule: #e7e2da;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #191611; --ink: #ece8e1; --soft: #a49d92;
      --accent: #eb8f4a; --rule: #353028;
    }
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: var(--bg); color: var(--ink);
    font: 17px/1.65 -apple-system, "Segoe UI", Roboto, system-ui, sans-serif;
    padding: 3rem 1.25rem 4rem;
  }
  main { max-width: 42rem; margin: 0 auto; }
  .brand {
    display: flex; align-items: center; gap: 0.5rem;
    font-weight: 700; color: var(--accent); margin-bottom: 2.5rem;
    text-decoration: none; font-size: 1rem;
  }
  h1 { font-size: 1.7rem; line-height: 1.25; margin-bottom: 0.4rem; }
  .effective { color: var(--soft); font-size: 0.9rem; margin-bottom: 2rem; }
  h2 {
    font-size: 1.15rem; margin: 2rem 0 0.6rem;
    padding-top: 1.4rem; border-top: 1px solid var(--rule);
  }
  p, ul { margin-bottom: 0.9rem; }
  ul { padding-left: 1.4rem; }
  li { margin-bottom: 0.35rem; }
  a { color: var(--accent); }
  footer {
    margin-top: 3.5rem; padding-top: 1.25rem;
    border-top: 1px solid var(--rule);
    font-size: 0.88rem; color: var(--soft);
  }
  footer nav { display: flex; flex-wrap: wrap; gap: 1rem; }
"""

FOOTER_LINKS = [
    ("privacy.html", "Privacy Policy"),
    ("terms.html", "Terms of Service"),
    ("disclaimer.html", "Medical Disclaimer"),
    ("/", "Open Sunbeam"),
]


def md_to_html(md: str) -> tuple[str, str]:
    """Tiny converter for the subset of markdown these documents use:
    #/## headings, - lists, **bold**, and paragraphs. Returns
    (body_html, effective_date)."""
    out, in_list = [], False
    effective = ""

    def inline(text: str) -> str:
        text = html.escape(text, quote=False)
        text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
        # Turn bare email addresses into mailto links
        text = re.sub(
            r"([\w.+-]+@[\w-]+\.[\w.]+)", r'<a href="mailto:\1">\1</a>', text)
        return text

    def close_list():
        nonlocal in_list
        if in_list:
            out.append("</ul>")
            in_list = False

    for line in md.splitlines():
        stripped = line.strip()
        if not stripped:
            close_list()
        elif stripped.startswith("## "):
            close_list()
            out.append(f"<h2>{inline(stripped[3:])}</h2>")
        elif stripped.startswith("# "):
            close_list()
            out.append(f"<h1>{inline(stripped[2:])}</h1>")
        elif stripped.startswith("- "):
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append(f"<li>{inline(stripped[2:])}</li>")
        elif stripped.lower().startswith("effective date:"):
            effective = stripped
            out.append(f'<p class="effective">{inline(stripped)}</p>')
        else:
            close_list()
            out.append(f"<p>{inline(stripped)}</p>")
    close_list()
    return "\n".join(out), effective


def build_page(body: str, title: str, current: str) -> str:
    links = "\n      ".join(
        f'<a href="{href}">{label}</a>'
        for href, label in FOOTER_LINKS
        if href != current
    )
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <title>{title} — Sunbeam</title>
  <link rel="icon" href="favicon.png">
  <style>{STYLE}</style>
</head>
<body>
  <main>
    <a class="brand" href="/">☀️ Sunbeam</a>
    {body}
    <footer>
      <nav>
      {links}
      </nav>
    </footer>
  </main>
</body>
</html>
"""


def main() -> None:
    for src, dest, title in PAGES:
        md = (ROOT / "assets" / "legal" / src).read_text(encoding="utf-8")
        body, _ = md_to_html(md)
        page = build_page(body, title, dest)
        (ROOT / "web" / dest).write_text(page, encoding="utf-8")
        print(f"wrote web/{dest} from assets/legal/{src}")


if __name__ == "__main__":
    main()
