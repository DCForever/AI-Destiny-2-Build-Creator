<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

## Domain & feature rules (always consult + keep current)

When **planning** or **implementing** product behavior:

1. **Read first** (domain wins on conflict):
   - [`specs/domain-business-rules.md`](specs/domain-business-rules.md) — `DBR-*`
   - [`specs/domain-acceptance-criteria.md`](specs/domain-acceptance-criteria.md) — `DAC-*`
   - [`specs/business-rules.md`](specs/business-rules.md) — `BR-*` (feature layer)

2. **Update those docs in the same change** when you ship or decide a product rule that is not already captured (new/changed DBR, DAC, BR; supersession notes; **Updated** date). Do not leave rules only in commits or chat.

3. **Pure UI polish** (density, chrome collapse, viewport lock) stays out of domain P1/P2 gates unless it encodes product semantics — note trackers under `docs/` if needed.

4. Feature specs under `specs/00N-*/` remain slice-level; still align them with domain when they contradict DBR/DAC.
