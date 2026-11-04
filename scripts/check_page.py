"""Lint the web page without third-party tools.

    python3 scripts/check_page.py [www/index.html]

Checks, using only the standard library:
- every element is closed and nested properly (void elements excepted)
- no duplicate id attributes; every aria-labelledby / href="#..." target exists
- exactly one h1, and heading levels never skip (h1 -> h2 -> h3)
- every <img> has an alt attribute (alt="" is fine for decoration)
- visible text uses curly punctuation: no straight ' or " in text nodes
  (code, script and style contents are exempt)
Exits non-zero on any problem.
"""
import re
import sys
from html.parser import HTMLParser

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link",
        "meta", "source", "track", "wbr", "path"}
EXEMPT_TEXT = {"code", "script", "style", "pre", "svg"}


class Checker(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack, self.problems, self.ids = [], [], {}
        self.refs, self.headings = [], []

    def where(self):
        return f"line {self.getpos()[0]}"

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "id" in a:
            if a["id"] in self.ids:
                self.problems.append(f"{self.where()}: duplicate id '{a['id']}'")
            self.ids[a["id"]] = True
        for key in ("aria-labelledby", "aria-describedby"):
            if key in a:
                self.refs += [(self.where(), r) for r in a[key].split()]
        if tag == "a" and a.get("href", "").startswith("#") and len(a["href"]) > 1:
            self.refs.append((self.where(), a["href"][1:]))
        if tag == "img" and "alt" not in a:
            self.problems.append(f"{self.where()}: <img> without alt ({a.get('src')})")
        if re.fullmatch(r"h[1-6]", tag):
            self.headings.append((self.where(), int(tag[1])))
        if tag not in VOID:
            self.stack.append((tag, self.where()))

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if tag not in VOID and self.stack and self.stack[-1][0] == tag:
            self.stack.pop()

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        if not self.stack:
            self.problems.append(f"{self.where()}: stray </{tag}>")
            return
        open_tag, opened = self.stack[-1]
        if open_tag == tag:
            self.stack.pop()
        else:
            self.problems.append(f"{self.where()}: </{tag}> closes <{open_tag}> opened at {opened}")
            while self.stack and self.stack[-1][0] != tag:
                self.stack.pop()
            if self.stack:
                self.stack.pop()

    def handle_data(self, data):
        if any(t in EXEMPT_TEXT for t, _ in self.stack):
            return
        for ch in ("'", '"'):
            if ch in data:
                snippet = data.strip().replace("\n", " ")[:60]
                self.problems.append(f"{self.where()}: straight {ch} in text: “{snippet}”")


def main(path):
    c = Checker()
    c.feed(open(path, encoding="utf-8").read())
    c.close()
    for tag, opened in c.stack:
        if tag not in ("html", "body", "head"):
            c.problems.append(f"<{tag}> opened at {opened} is never closed")
    for where, ref in c.refs:
        if ref not in c.ids:
            c.problems.append(f"{where}: reference to missing id '{ref}'")
    h1s = [h for h in c.headings if h[1] == 1]
    if len(h1s) != 1:
        c.problems.append(f"expected one <h1>, found {len(h1s)}")
    prev = 0
    for where, level in c.headings:
        if level > prev + 1:
            c.problems.append(f"{where}: heading jumps from h{prev} to h{level}")
        prev = level
    outline = " ".join(f"h{l}" for _, l in c.headings)
    print(f"{path}: {len(c.ids)} ids, headings: {outline}")
    for p in c.problems:
        print("  PROBLEM " + p)
    print("clean" if not c.problems else f"{len(c.problems)} problem(s)")
    return 1 if c.problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "www/index.html"))
