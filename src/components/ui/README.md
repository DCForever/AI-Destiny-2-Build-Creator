# Vault Terminal UI (`src/components/ui`)

Shared primitives for production screens. Feature pages should **compose** these
instead of sprinkling `panel-notch` / raw Tailwind.

**Polish backlog:** [docs/ui-polish-tracker.md](../../../docs/ui-polish-tracker.md) — living list of fidelity / nice-to-have UI work (not Spec Kit).

## Primitives

| Export | Role |
|--------|------|
| `InfoHotspot` | Hover/pin popover (portaled); optional icon + accent in header |
| `EntityHotspot` | Icon-first entity chip + description; prefers art over name when available |
| `Panel` | Notched surface (`default` / `raised` / `accent` / `muted` / …) |
| `Section` + `SectionLabel` | Labeled content block inside a panel |
| `Stack` / `Row` / `Cluster` | Spacing + alignment |
| `Text` / `Heading` | Typography tones |
| `Button` | `accent` / `outline` / `ghost` / `danger` |
| `Chip` / `FilterChip` | Tags + toggle filters |
| `TextField` / `SelectField` | Form controls |
| `PageHeader` | Title + description + actions |
| `EmptyState` / `Callout` | Empty / status messaging |
| `Workspace` / `WorkspaceMain` / `CardGrid` | Page layout slots |

## Rearranging a screen

`BuildPage` is the reference:

```tsx
<Stack>
  <PageHeader … />
  <Workspace
    rail={<BuildLibrary … />}
    main={
      <WorkspaceMain>
        <BuildIdentity … />
        <CardGrid>…</CardGrid>
        <BuildActions … />
      </WorkspaceMain>
    }
    // railPosition="end"  → library on the right
    // railWidth={320}     → wider rail
  />
</Stack>
```

Reorder `WorkspaceMain` children, swap `railPosition`, or replace a slot with
another panel — styling stays consistent because everything is a primitive.
