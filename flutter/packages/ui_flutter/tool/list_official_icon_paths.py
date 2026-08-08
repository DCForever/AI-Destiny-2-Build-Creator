import re
from pathlib import Path

text = Path("lib/src/destiny_official_icons.dart").read_text(encoding="utf-8")
paths = sorted(set(re.findall(r"/common/destiny2_content/icons/[^'\"]+", text)))
print(len(paths))
for p in paths:
    print(p)
