# DIM reference screenshots

Visual **North Star** captures from [Destiny Item Manager (DIM)](https://destinyitemmanager.com/) for how this product should **present Destiny data** (items, perks, mods, loadout chrome).

## Product rule

| Rule | Summary |
|------|---------|
| [`DBR-UI-001`](../../specs/domain-business-rules.md) | DIM is the North Star for Destiny data presentation in general |
| [`DBR-UI-002`](../../specs/domain-business-rules.md) | Main intentional divergence: **build creation / composition** workflow |
| [`DBR-UI-003`](../../specs/domain-business-rules.md) | Full DIM **product** parity is not required |
| [`DBR-UI-004`](../../specs/domain-business-rules.md) | This folder is the visual reference set |

Product framing: [`PRODUCT.md`](../../PRODUCT.md) (Positioning + Brand).

## Inventory

| File | Use when reviewing |
|------|--------------------|
| `Loadout Overview.png` | Loadout / kit summary readout |
| `Loadout Overview Editor.png` | Loadout edit chrome |
| `Loadout - Mod Placement.png` | Armor mod energy / slot placement |
| `Loadout Optimizer.png` | Optimizer main (readout density; not our compose path) |
| `Loadout Optimizer - Part 2.png` | Optimizer continuation |
| `Loadout Optimizer - Subclass Picker Part 1.png` | Subclass kit picker density |
| `Loadout Optimizer - Subclass Picker Part 2.png` | Subclass kit picker continuation |
| `Weapon Overview.png` | Weapon item detail |
| `Weapon Perk Info Popup.png` | Perk hotspot / popup copy |
| `Exotic Armor Overview.png` | Exotic armor detail |
| `Exotic Weapon Overview.png` | Exotic weapon detail |

## How to use

- **Do** match DIM-familiar density, labeling, perk columns, stat bars, and mod placement when showing Destiny entities on Catalog, Sets, Loadouts, and build **readouts**.
- **Do not** treat DIM create-loadout / LO as the required **compose** UX — intent → sets/synergies/variants remains product-owned (`DBR-UI-002`).
- Prefer adding new captures here (clear names) when a Destiny-data surface has no reference yet.
