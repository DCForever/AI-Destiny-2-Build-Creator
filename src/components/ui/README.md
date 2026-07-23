# Matte Flap Ledger UI (`src/components/ui`)

Shared primitives for production screens. Feature pages should **compose** these
instead of sprinkling raw board / badge classes.

**Polish backlog:** [docs/ui-polish-tracker.md](../../../docs/ui-polish-tracker.md)

## Primitives

| Export | Role |
|--------|------|
| `FlapRow` / `FlapBoard` / `FlapHeader` / `FlapCell` / `FlapSeal` | Dense split-flap library rows |
| `InfoHotspot` | Hover/pin popover (portaled) |
| `EntityHotspot` | Icon-first entity chip + description |
| `Panel` | Square matte surface |
| `Section` + `SectionLabel` | Labeled content block |
| `Stack` / `Row` / `Cluster` | Spacing + alignment |
| `Text` / `Heading` | Typography tones |
| `Button` | `accent` / `outline` / `ghost` / `danger` |
| `Badge` | Status wash chips |
| `Chip` / `FilterChip` | Tags + toggle filters |
| `TextField` / `SelectField` | Form controls |
| `PageHeader` | Title + description + actions |
| `EmptyState` / `Callout` | Empty / status messaging |
| `Workspace` / `WorkspaceMain` / `CardGrid` | Page layout slots |

## Library boards

Prefer `FlapBoard` + `FlapRow` for Sets / Synergy / Build libraries — not nested
`Panel` cards per row. Use `railWidth={320}` when columns need air.

```tsx
<FlapBoard>
  <FlapHeader columns={COLS} cells={["Name", "Type", "Tags"]} />
  {rows.map((row) => (
    <FlapRow key={row.id} columns={COLS} selected={…} onClick={…}>
      <FlapCell variant="name">{row.name}</FlapCell>
      …
    </FlapRow>
  ))}
</FlapBoard>
```
