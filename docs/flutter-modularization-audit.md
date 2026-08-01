# Flutter workspace audit: modularization, shared UI, simplification

**Status (2026-08):** Do-first items **implemented** in package code (see below).  
**Workspace:** `flutter/` Melos packages + `apps/{windows,mobile,web}_host`  
**Layering constraints (do not violate):** pure packages stay pure (`domain`, `sandbox_data`); no Flutter/Jaspr in pure code; `ui_tokens` pure; `ui_flutter` Flutter-only (not imported by Jaspr web_host).

### Implemented homes

| Audit item | New home |
|------------|----------|
| M1 formatters | `packages/app/lib/src/presentation/*_format.dart` (hosts re-export) |
| M2 equip | `packages/app/lib/src/equip/equip_session.dart` |
| M2 DIM | `packages/app/lib/src/dim_export/dim_export_session.dart` |
| S1 page split | `builds_library_page_*.dart` part/extension sections |
| U1 ItemRichness | `packages/ui_flutter/lib/src/item_richness.dart` |
| M4/S4 compose | `packages/app/lib/src/builds/builds_compose_session.dart` (mobile/windows/web wrap core; identity+finish host extras only) |

---

## 1. Modularization opportunities (path-backed)

### M1 — Triple-copied pure presentation formatters → `packages/app` (or thin `presentation` barrel)

| Host copy | Path | Lines |
|-----------|------|------:|
| Windows | `apps/windows_host/lib/builds/soft_guidance_format.dart` | 87 |
| Web | `apps/web_host/lib/compose/soft_guidance_format.dart` | 85 |
| Mobile | `apps/mobile_host/lib/builds/soft_guidance_format.dart` | 85 |

**Evidence:** Bodies are effectively identical (trimmed-line overlap ~97%): `kSoftGuidanceAdvisoryCaption`, `formatCoverageTierLabel`, `coverageTierToneKey`, `formatSynergyCoverageChipLabel`, etc. Same pattern for:

- `variant_compose_format.dart` (win / web / mobile) — ~98% overlap  
- `finish_gaps_format.dart` (win / web / mobile)  
- `equip_format.dart` (win ~99 lines / web ~102) — ~98%  
- `dim_export_format.dart` (win / web) — ~97%  
- Build identity: `build_identity_format.dart` (win) vs `build_format.dart` (mobile/web) — ~73–83% (same wire keys; web adds display chrome)

**Recommendation:** Move pure `destiny2_domain`-only formatters into `packages/app` next to existing `designation_chrome.dart` / presentation modules. Hosts keep zero logic, only import. Tests consolidate to one package suite.

**Boundary:** Stays out of `domain` (presentation strings, not rules). Fits `app` (already hosts `formatDesignationChrome`, set/synergy presentation).

---

### M2 — Near-duplicate host orchestration controllers → shared non-UI core

| Pair | Windows | Web | Overlap (trimmed lines) |
|------|---------|-----|------------------------:|
| Equip | `.../equip/equip_controller.dart` (414) | `.../equip/equip_controller.dart` (408) | **~92%** |
| DIM export | `.../dim_export/dim_export_controller.dart` (208) | same basename (207) | **~94%** |
| Owned catalog | `.../catalog/owned_catalog_bridge.dart` (254) | same (266) | **~82%** |
| Inventory sync | `.../settings/inventory_sync_controller.dart` (342) | same (214) | **~57%** (web thinner) |

**Evidence:** Equip controllers share the same fields, getters (`canApply`, `readinessSummary`), and methods (`bind`, `loadCharacters`, `refreshReadiness`, `requestEquip`, `confirmGapsAndEquip`, `_executeEquip`). Divergence is mostly session type (`WindowsOAuthSession` vs `WebOAuthSession`) and inventory-sync injection.

**Recommendation:** Extract session-agnostic core (interface on tokens/membership + profile/write clients) into `packages/app` or `packages/bungie` orchestration types; hosts only adapt ChangeNotifier + platform session. Same for DIM export and OwnedCatalogBridge (DB + OfflineCatalog + user resolve).

**Defer full merge of inventory sync** until web DART-056 depth and Windows post-sync suggestions paths are reconciled (web controller is intentionally smaller).

---

### M3 — OAuth token codec / TokenStore port

| Piece | Windows | Web |
|-------|---------|-----|
| Codec | `apps/windows_host/lib/auth/token_codec.dart` (57) | `apps/web_host/lib/auth/token_codec.dart` (57) |
| Store | `MemoryTokenStore` + `SecureTokenStore` in `auth/token_store.dart` | Memory + browser storage in web `auth/token_store.dart` |

**Evidence:** `encodeBungieTokens` / `decodeBungieTokens` JSON shapes and comments match (shared keys `access_token`, `refresh_token`, `expires_at`, `membership_id`). Overlap ~90% on codec.

**Recommendation:** Move codec (+ abstract `TokenStore`) into `packages/bungie` next to `BungieTokens`. Platform stores stay in hosts (`SecureTokenStore` Flutter; web storage on Jaspr).

---

### M4 — Builds compose orchestration triplicated across hosts

| Host | Controller | Lines |
|------|------------|------:|
| Windows | `builds_library_controller.dart` | 1465 |
| Web | `builds_controller.dart` | 1145 |
| Mobile | `builds_controller.dart` | 778 |

**Evidence:** Shared surface area: draft synergy types, `createBuild`, `selectVariant`, `attachSet`/`detachSet`, `pinSlot`, `refreshSoftCoverage`, `saveSoftStatTargets`, view DTOs (`AttachmentView`, `SlotPinView`), soft coverage list getters. All call into `packages/app` use cases but reimplement orchestration + view models.

**Recommendation:** Introduce a pure (or package-app) `BuildsComposeSession` / facade that owns attach/pin/coverage state; hosts become thin adapters (Flutter ChangeNotifier vs Jaspr notifier). Highest leverage after formatters because it cuts three large files.

---

### M5 — Designation chrome already half-shared

| Location | Role |
|----------|------|
| `packages/app/lib/src/designation_chrome.dart` | Canonical wire + human chrome |
| `apps/windows_host/lib/synergies/synergy_designation.dart` | Thin wrapper → `formatDesignationChrome` / wire |
| Host `build_*format.dart` | Reimplements wire keys again |

**Evidence:** Windows synergy module correctly delegates to app; build format helpers still re-copy `type::subType` logic on all three hosts.

**Recommendation:** Hosts should only call `designationWireKey` / `formatDesignationChrome` from `destiny2_app`; delete local wire helpers when consolidating M1.

---

### M6 — Layering already healthy (do not “modularize” away)

- Pure domain/sandbox_data: enforced by `tool/pure_package_graph_guard.dart` / P0 gate.  
- `ui_flutter` correctly unused by Jaspr (web maps tokens in CSS).  
- Generated `packages/db/lib/src/app_database.g.dart` (~8.8k lines) is Drift codegen — not a split candidate.

---

## 2. Reusable UI component candidates

### Placement legend

| Layer | Package / host | Stack |
|-------|----------------|-------|
| **Token** | `packages/ui_tokens` | Pure ARGB/layout contracts |
| **Flutter kit** | `packages/ui_flutter` | Theme + board widgets |
| **Flutter host widget** | `windows_host` / `mobile_host` | Material only |
| **Jaspr host** | `web_host` | HTML/CSS components |
| **Shared non-UI** | `packages/app` | Strings/DTOs only |

### U1 — `ItemRichnessPanel` → `ui_flutter` (Flutter-only)

- **Path:** `apps/windows_host/lib/widgets/item_richness.dart` (**933 lines**)  
- **Used by:** `catalog_page.dart` instance dossier (definition / stats / perks / tags sections).  
- **Why extract:** Single largest reusable product UI chunk not in the design kit; catalog detail depends on it; set picker / equip flows will want the same dossier.  
- **Not for web as-is:** Web renders plug/stats ad hoc in `apps/web_host/lib/pages/catalog_page.dart` (~1090 lines) with Jaspr nodes — parallel *concept*, not shared widget. Shared piece is **data** (`CatalogInstanceProjection` / plug cards from `db`/`app`).

### U2 — Dual-pane library shell already in kit; pages still fat

- **Kit:** `packages/ui_flutter/lib/src/library_workspace.dart` (`LibraryWorkspace`)  
- **Consumers:** `builds_library_page.dart`, `sets_library_page.dart`, `synergies_library_page.dart` (each wraps rail+detail).  
- **Gap:** Rail row builders still hand-roll `FlapBoardHeader`/`FlapBoardRow` + ListTile noise differently per library. Candidate: `LibraryRailList<T>` / `FlapSelectableRow` in `ui_flutter` with selection + search slot.

### U3 — Soft guidance chip strip (cross-host pattern)

- **Logic:** triple formatters (M1).  
- **UI:** `_buildSoftGuidance` embedded in `builds_library_page.dart` (~2147+); mobile sheets; web compose page.  
- **Candidate:** Flutter `SoftGuidancePanel(controller-or-coverage)` in `ui_flutter`; Jaspr twin stays host-specific but same DTO/formatters from `app`.

### U4 — Settings cards (Flutter)

| Widget | Path | Notes |
|--------|------|-------|
| `OAuthAccountCard` | `windows_host/lib/settings/oauth_account_card.dart` | Win Material; web has Jaspr twin under `components/oauth_account_card.dart` |
| `InventorySyncCard` | `windows_host/lib/settings/inventory_sync_card.dart` (**334 lines**) | Diagnostics + post-sync banner; web Jaspr twin |
| `_ManifestStatusCard` | Private in both win + mobile `settings_page.dart` | Nearly same Card/ListTile status UI — extract to `ui_flutter` |

Do **not** force-share Flutter cards into Jaspr; share **controller + format** (M2/M1).

### U5 — Catalog filter chrome (host-specific shells)

- Windows: `catalog_page.dart` (**1206 lines**) — filters, grouping, scope chips, detail, create set/synergy from hit.  
- Web: `pages/catalog_page.dart` (**1090 lines**) — same product surface, different DOM.  
- **Shared extract:** filter state machine / facet model (may already partially live in `manifest` OfflineCatalog + `app` dense meta); UI chips stay host-native.

### U6 — Equip panel / DIM panel (Windows widgets)

- Controllers highly shareable (M2); UI panels remain Flutter widgets. After controller extraction, panel becomes thin and testable with fakes.

### Already good in `ui_flutter` (extend, don’t reinvent)

- `FlapPalette`, `buildFlapThemeBase`, `FlapBoardHeader`/`Row`/`Seal`, `flapTone`/`flapElement`, `LibraryWorkspace`, theme toggle.  
- Hosts only thin-wrap theme (`apps/*/lib/theme/flap_theme.dart`).

---

## 3. Simplification opportunities (impact-ordered)

| Rank | Opportunity | Impact | Evidence |
|-----:|-------------|--------|----------|
| **S1** | **Shatter `builds_library_page.dart` (2444 lines)** | Highest | Single State class owns rail, create strip, identity edit, variant compose, finish gaps, soft guidance, armor optimize embed (`_FinishArmorOptimizeEmbed`). Extract private widgets/files even before shared package work. |
| **S2** | **Collapse triple format copies** | High, low risk | Soft/variant/finish/equip/DIM formatters (M1). Deletes ~6–8 files and duplicate tests. |
| **S3** | **Unify equip + DIM controllers** | High | ~92–94% twin files (M2). Stops double bugfixes (gaps confirm, equip-ready). |
| **S4** | **Thin builds controllers via session facade** | High | 1465 + 1145 + 778 lines of parallel orchestration (M4). |
| **S5** | **Split catalog_page responsibilities** | Medium-high | 1206-line page mixes load, filter cycle methods (~10 `_cycle*`), detail, instance cards, set/synergy create. |
| **S6** | **Move ItemRichness into ui_flutter** | Medium | 933-line host widget blocks reuse/tests; catalog should compose kit. |
| **S7** | **OwnedCatalogBridge single implementation** | Medium | 82% twin; inventory annotate + plug name resolve belongs next to catalog use cases. |
| **S8** | **Token codec to bungie package** | Low-medium | Trivial drift risk today (57-line twins). |
| **S9** | **Stop re-wrapping designation chrome** | Low | Prefer `destiny2_app` only (M5). |
| **S10** | **Mobile host stays thin on purpose** | N/A | Only builds+settings; do not force dual-pane or full catalog modularization onto mobile until product scope expands. |

**Complexity to avoid “simplifying”:**

- Drift generated schema (`app_database.g.dart`).  
- Jaspr vs Flutter UI trees (do not invent a cross-framework widget layer).  
- Web workspace isolation (analyzer/meta pin) — keep web_host non-member until toolchains align.

---

## 4. Recommended next-work set vs deferrals

### Do first (ordered)

1. **S2 / M1 — Consolidate pure format helpers into `packages/app`**  
   - Soft guidance, variant compose, finish gaps, equip, DIM formats.  
   - Point all three hosts at one export; delete triplicates.  
   - **Why first:** Pure move, high test coverage already, zero product risk, unblocks UI chips.

2. **S1 — File-split Windows `builds_library_page.dart` only (no behavior change)**  
   - Extract: soft guidance section, finish gaps section, variant compose section, create/edit strips, finish optimizer embed.  
   - **Why:** Makes later controller extraction reviewable; reduces merge pain.

3. **S3 / M2 — EquipController (+ DimExportController) shared core**  
   - Abstract session as `OAuthSessionPort` / inject membership+token accessors.  
   - **Why:** Highest-value orchestration twin; product-critical path.

4. **S6 — Promote `ItemRichnessPanel` to `ui_flutter`**  
   - Windows catalog becomes consumer; mobile can adopt later.

5. **S4 — Builds compose session in `packages/app`**  
   - After formatters + page split so diffs stay readable.

### Defer

| Item | Why defer |
|------|-----------|
| Merging inventory sync controllers fully | Web path thinner (DART-056); Windows has post-sync suggestions + richer diagnostics |
| Shared Flutter/Jaspr widget layer | Wrong abstraction; keep token + app DTO sharing |
| Splitting `domain` / `db` packages | Already modular; db size is mostly generated |
| Full mobile catalog/sets/synergies modularization | Mobile product surface intentionally reduced |
| Melos/workspace include web_host | Toolchain pin (Jaspr analyzer vs Flutter meta), separate goal |
| Loadouts controller deep merge | Only ~45% line overlap; verify product parity first |

### Explicit non-actions (this goal)

No refactors shipped; recommendations only. Structural baseline test: `flutter/tool/test/modularization_audit_baseline_test.dart`.

---

## Appendix A — Cross-host similarity snapshot

| Pair | Shared-line estimate |
|------|---------------------:|
| equip_controller win↔web | ~92% |
| dim_export_controller win↔web | ~94% |
| owned_catalog_bridge win↔web | ~82% |
| soft_guidance_format win↔web↔mobile | ~97% |
| equip_format win↔web | ~98% |
| token_codec win↔web | ~90% |
| inventory_sync_controller win↔web | ~57% |
| loadouts_controller win↔web | ~45% |

## Appendix B — Suggested package home for extractions

```
packages/app/          # formatters, compose session, owned-catalog bridge (no Flutter)
packages/bungie/       # token_codec, TokenStore interface
packages/ui_flutter/   # ItemRichnessPanel, SoftGuidancePanel (Flutter), ManifestStatusCard
apps/*_host/           # session adapters, shell nav, Jaspr DOM / Material pages only
```
