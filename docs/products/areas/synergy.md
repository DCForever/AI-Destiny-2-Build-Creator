# Synergy — area product description

**Kind:** area  
**Status:** draft  
**Updated:** 2026-07-29  
**Domain line:** Destiny 2 Build Creator  
**Product-map area:** `synergy`  
**Nav / route:** `/synergy` (production library; debug tools separate)  
**Related domain product:** [Synergy](../domains/synergy.md)

---

## 1. Role in the product

| Field | Content |
|-------|---------|
| **Product role** | **P2 library** — primary vocabulary for intent |
| **One-liner** | Curate play-pattern Synergies (type + object evidence) so builds can designate intent and get coverage/suggestions. |
| **Primary journey** | Feeds P1: designated Synergy Types bridge to library Synergies for coverage; in-flow create remains allowed. |

---

## 2. Users & jobs

- **Primary job:** Build a personal library of Type+Object synergies with required vs evidence links.
- **Secondary jobs:** Custom personal types/keywords; immutable designation after create; optional LLM propose-for-confirm.
- **Not for:** Replacing build identity with free-text vibes only; auto-promoting LLM output without confirmation.

---

## 3. In scope

- Synergy library list, filters, search, create/edit/detail
- Designation (`type` + optional `subType`) immutable after create
- Description + linked Objects (weapon, perk, origin trait, set bonus, exotic, artifact, etc.)
- Required vs evidence flags; multi-required AND
- Personal custom types / keywords (promote later optional)
- Used-by / reverse discoverability where product already exposes it
- Manual LLM propose-for-confirm path (confirm before canonical)

---

## 4. Out of scope / non-goals

- Forcing a full library before first compose (`DBR-PUR-004`)
- Editing designation after create (must reject — `DBR-SYN-012`)
- Auto-running LLM on every edit
- Treating concept tags as synergy identity

---

## 5. Success (product-level)

| Signal | How we know |
|--------|-------------|
| Curated evidence | Synergies with links usable for bridging (`DAC-P2-001`) |
| Immutability | Type/subtype fixed after create (`DAC-P2-001a`) |
| Required links | Default-variant hard checks where domain says so (`DAC-P2-002`) |
| Personal types | Custom keywords/types work (`DAC-P2-003`) |
| LLM | Propose-for-confirm only (`DAC-P2-004`) |
| In-flow | Create still works during compose (`DAC-P2-005`) |
| Library bar | Supports ≥10 synergies for P1 domain done (`DAC-P1-009`) |

---

## 6. Domain & structure links

| Kind | Refs |
|------|------|
| **DBR** | `DBR-SYN-*`, `DBR-LLM-*`, `DBR-PUR-004`–`005` |
| **DAC** | `DAC-P2-*`, `DAC-P1-001` (intent side) |
| **BR** | `BR-SYN-*` |
| **Key surfaces** | `synergy.library*`, `synergy.create*`, `synergy.detail*`, `synergy.edit` |
| **Key flows** | P2 synergy library; in-flow create |

---

## 7. Presentation notes

Evidence and designation chips: icon-first when art/glyphs exist; tooltips for names. Board-first density preferred (see polish tracker) without abandoning domain labels.

---

## 8. Open product questions

- Promote gap-scan (`/debug/synergy-gaps`) into production nav?  
- How far global vs personal vocabulary promote goes in v1  

## 9. Related docs

- Domain synergies section · `PRODUCT.md` LLM constraints · debug propose tools in `DEBUG.md`
