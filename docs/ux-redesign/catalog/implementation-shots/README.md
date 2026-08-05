# Catalog — implementation shots

Live Flutter screenshots that sit **next to** `../mockups/`.  
Used as dual ground truth for the next `area-ux-redesign` pass.

**Capture path (required):** Flutter MCP + Driver (`lib/main_mcp.dart` → `flutter_driver` `screenshot`), as part of `area-implement` **Verify** / **Capture**. Not optional OS paste unless Driver cannot run.

| Slice folder | Mockups | Status |
| --- | --- | --- |
| [`001-weapons/`](001-weapons/) | `../mockups/001-weapons-desktop.html`, `001-weapons-mobile.html` | **Capture 2026-08-04 complete** (grid, unowned, owned, can-roll, instance strip). See `COMPARE.md` |
| [`001-full/`](001-full/) | `../mockups/001-full-desktop.html`, `001-full-mobile.html` | **Capture 2026-08-04 complete** — residual pass matrix (grid, owned OFF, can-roll ON, unowned, exotic, instance strip). P0 equal-width closed; **P1 meta layout reopen** (full-width glyph bars vs compact strip). See [`001-full/COMPARE.md`](001-full/COMPARE.md) |
| [`001-residual-polish/`](001-residual-polish/) | `../mockups/001-residual-polish-desktop.html`, `001-residual-polish-mobile.html` | **Capture 2026-08-04 complete** — dual-truth re-shots close P1 meta + type silhouettes + ③ headers @400 + omit-empty catalyst. Live Enhanced gold/E + catalyst-present still open. See [`001-residual-polish/COMPARE.md`](001-residual-polish/COMPARE.md) |

See [template](../../_template-implementation-shots-compare.md) and [loop README](../../README.md).
