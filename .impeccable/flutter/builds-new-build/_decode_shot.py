import re
import base64
import pathlib
import sys

src = pathlib.Path(sys.argv[1])
out = pathlib.Path(sys.argv[2])
t = src.read_text(encoding="utf-8", errors="replace")
m = re.search(r"data:image/[^;]+;base64,([A-Za-z0-9+/=\n\r]+)", t)
if not m:
    m = re.search(r'"base64"\s*:\s*"([^"]+)"', t)
raw = None
if m:
    raw = m.group(1).replace("\n", "").replace("\r", "")
else:
    chunks = re.findall(r"[A-Za-z0-9+/]{200,}={0,2}", t)
    if chunks:
        raw = max(chunks, key=len)
if not raw:
    print("no base64 found; file len", len(t))
    print(t[:400])
    sys.exit(1)
data = base64.b64decode(raw)
out.write_bytes(data)
print("wrote", out, "bytes", len(data))
