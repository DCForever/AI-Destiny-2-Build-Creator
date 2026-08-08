"""Audit Widgetbook use cases for knob coverage."""
from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "lib" / "use_cases"
rows = []

for p in sorted(root.rglob("*.dart")):
    text = p.read_text(encoding="utf-8")
    parts = re.split(r"@widgetbook\.UseCase\(", text)
    for part in parts[1:]:
        name_m = re.search(r"name:\s*['\"]([^'\"]+)['\"]", part)
        type_m = re.search(r"type:\s*(\w+)", part)
        path_m = re.search(r"path:\s*['\"]([^'\"]+)['\"]", part)
        fn_m = re.search(r"\)\s*\nWidget\s+(\w+)", part)
        fname = fn_m.group(1) if fn_m else "?"
        after = part[fn_m.end() :] if fn_m else part
        stop = re.search(r"\n@widgetbook|\nclass ", after)
        body = after[: stop.start()] if stop else after[:4000]
        knob_lines = re.findall(r"context\.knobs\.[^\n;]+", body)
        rows.append(
            {
                "file": str(p.relative_to(root)).replace("\\", "/"),
                "name": name_m.group(1) if name_m else "?",
                "type": type_m.group(1) if type_m else "?",
                "path": path_m.group(1) if path_m else "?",
                "fn": fname,
                "knob_count": len(knob_lines),
                "knobs": knob_lines,
            }
        )

by_type: dict[str, list] = defaultdict(list)
for r in rows:
    by_type[r["type"]].append(r)

print(f"Total use cases: {len(rows)}")
print(f"With knobs: {sum(1 for r in rows if r['knob_count'] > 0)}")
print(f"Without knobs: {sum(1 for r in rows if r['knob_count'] == 0)}")
print()
for t in sorted(by_type):
    cases = by_type[t]
    max_k = max(c["knob_count"] for c in cases)
    has = any(c["knob_count"] > 0 for c in cases)
    status = "HAS KNOBS" if has else "MISSING"
    print(f"[{status}] {t}  stories={len(cases)} max_knobs={max_k}")
    for c in cases:
        mark = f"  knobs={c['knob_count']}" if c["knob_count"] else "  (static)"
        print(f"  - {c['name']}{mark}")
