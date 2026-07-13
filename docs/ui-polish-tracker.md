# UI polish tracker

Living list of **perceived polish, fidelity, and nice-to-have** UI work.  
Not a product roadmap and not Spec Kit acceptance criteria — those stay under `specs/`.

**Source seeds:** prod-ui-refactor canvas, residual-gaps notes from overhaul work, ongoing UX feedback.

---

## How to use this file

| Status | Meaning |
|--------|---------|
| `open` | Not started or only sketched |
| `partial` | Some work landed; still short of intent |
| `done` | Good enough to close; move to **Recently closed** with a short note |
| `wontfix` | Explicitly declined; keep one line of why |

**When adding an item:** one concrete outcome, surface (Build / Sets / …), optional owner note.  
**When closing:** set status to `done`, add date + commit or PR if handy, move under **Recently closed**.  
**Do not** track domain bugs or missing APIs here — use specs/issues for those.  
**Agents:** after polish feedback or a polish PR, update this file in the same change set when practical.

Last reviewed: 2026-07-13

---

## Open / partial

### Catalog
| Status | Item | Notes |
|--------|------|--------|

### Sets
| Status | Item | Notes |
|--------|------|--------|
| `open` | **Synergized items for set tags** (future) | On Set detail: show library synergies / catalog items that align with the set’s concept tags (and optionally linked build designations). Not just “used by builds” — reverse discoverability of *what this set is good with*. Likely needs tag↔synergy/item matching rules; keep FR/BR for tags vs identity in mind (tags are filter metadata, not build identity). |


### Build
| Status | Item | Notes |
|--------|------|--------|
| `open` | Mods tab **slot-level** editing | Still largely “edit on Sets” |
| `open` | Soft-stat targets editor (not raw JSON) | JSON textarea is functional only |

### Synergy
| Status | Item | Notes |
|--------|------|--------|
| `open` | **Duplicate** library row | Merge exists; no clone |
| `open` | Promote **gap-scan** into product nav (optional) | Lives at `/debug/synergy-gaps` |
| `partial` | Designation icons for all curated names | Mapping + API landed; some names still miss art until alias/hunt improves |

### Loadouts
| Status | Item | Notes |
|--------|------|--------|
| `partial` | Full equip / sheet from Bungie slot instances | List + real icon/color landed; equip/sheet import still thin |

### Shell / global
| Status | Item | Notes |
|--------|------|--------|
| `partial` | Further mobile density / touch targets | Responsive padding + nav improved |
| `partial` | **Entity InfoHotspots** across all entity chips | `EntityHotspot` + presentation enrich; icon-first when art exists; remaining gaps where APIs still omit description |
| `open` | Pixel-perfect canvas hi-fi parity | Icons/hotspots/loadout chrome largely done |

---

## Recently closed

Move items here when done (newest first). Keep ~20 entries; archive older ones if the list grows.

| Closed | Item | Note |
|--------|------|------|
| 2026-07-13 | Richer variant card **gear rows** | Loadout icon strip; dense slot rows with element/source/perk icons; conflicts |
| 2026-07-13 | Variant **Details vs Edit** dual mode | Variant chips + Details/Edit toggle; focused read-only card vs edit panel |
| 2026-07-13 | Build **in-game loadout badges** + Bungie exotic link | Inventory-resolved exotics on Bungie slots; library badges; Loadouts linked builds |
| 2026-07-13 | Build library **exotic armor filters** | Multi-select chips (OR); AND with class; scoped options; “No exotic” |
| 2026-07-13 | Sets **concept tags** icon+color (Arc, Grenade, …) | `ConceptTagChip` / filter chips; element glyphs + ability-kind icons; text for activity/role |
| 2026-07-13 | Sets fill-slot **element / ammo / archetype** multi-filters | CatalogItemPicker chips; armor frame multi via API |
| 2026-07-13 | Sets **Used by builds** deep-link → Build detail | `/build?build=&variant=`; BuildPage reads query + selects variant |
| 2026-07-13 | Catalog **ammo / element / archetype multi-filters** | Multi-select chips; API `element`/`ammo`/`itemType` lists; OR within dimension |
| 2026-07-13 | Catalog instance detail closer to DIM | Weapon stat bars (304), frame strip, denser multi-perk columns, resync CTA |
| 2026-07-13 | Catalog perk-grid denser icons + full plug descriptions | Manifest fill for icon/desc; icon-only cells; all column options |
| 2026-07-13 | Catalog **instance perk-grid** UX (011) | DIM-style columns in Catalog; icons; auto re-sync pending |
| 2026-07-13 | Catalog multi **Group by** (ammo / element / archetype / …) | Multi-select dims; composite keys; `ammo` on catalog weapons |
| 2026-07-13 | Entity hotspot primitive + presentation resolver | `EntityHotspot`, `entityPresentation`, build/set/plug enrich |
| 2026-07-13 | Class / element / super icons on Build library + identity | Vault Terminal glyphs + subclass element |
| 2026-07-13 | Info hotspots on identity / synergy chips | Portal + single-open (clip-path fix) |
| 2026-07-13 | Responsive page padding + mobile shell nav | AppShell short labels, scroll nav |
| 2026-07-13 | Official **item** icons (Catalog, Sets, pickers, synergy links) | `ItemIcon` + entity `icon` paths |
| 2026-07-13 | **Designation → Bungie icon** mapping | `designationIcons` + API; client via fetch only |
| 2026-07-13 | Bungie **in-game loadouts** list with real icon/color | Component 206 + loadout presentation tables |
| 2026-07-13 | Sets **Used by builds** section | Attachment join + empty state |
| 2026-07-13 | Loadouts **linked build** labels | Match by class + exotic hashes (app snapshots) |
| 2026-07-13 | Build create/edit off debug pickers | Production ManifestSearch + SynergyTypeMultiSelect |
| 2026-07-13 | Production Sets / Catalog workspaces | Promoted from debug stubs |
| 2026-07-13 | Settings inventory sync progress + last updated | InventorySyncCard |
| 2026-07-13 | Synergy merge + link descriptions | Multi-select merge; catalog text on links |

---

## Explicit non-goals (unless product direction changes)

- Restoring **Generator** / multi-pass LLM as a primary nav tab  
- Deleting `/debug/*` power-user tools  
- Full DIM parity (notes, tags, ornaments, full transfer UI)  
- Spec Kit feature work (use `specs/` + Spec Kit commands)

---

## Related

- Canvas: Cursor `prod-ui-refactor` (wireframes / IA)  
- Operator APIs: `DEBUG.md`  
- Domain slices: `specs/domain-slice-roadmap.md`  
- Design system notes: `src/components/ui/README.md` (if present)
