/**
 * Matte Flap Ledger UI primitives.
 *
 * Compose screens from these — avoid ad-hoc flap / badge classes in
 * feature components so layout can be rearranged without restyling.
 */

export { Panel } from "./Panel";
export { FlapRow, FlapBoard, FlapHeader, FlapCell, FlapSeal, FlapTypeStamp } from "./FlapRow";
export { ThemeProvider, useTheme } from "./ThemeProvider";
export { ThemeToggle } from "./ThemeToggle";
export { Section, SectionLabel } from "./Section";
export { CollapsibleFilterSection } from "./CollapsibleFilterSection";
export { Stack, Row, Cluster } from "./Stack";
export { Text, Heading } from "./Text";
export { Button } from "./Button";
export { Badge, badgeToneClass } from "./Badge";
export type { BadgeTone } from "./Badge";
export { Chip, FilterChip, MetaChip } from "./Chip";
export { ClassFilterChip } from "./ClassFilterChip";
export { ConceptTagChip, ConceptTagFilterChip } from "./ConceptTagChip";
export { DesignationLabel } from "./DesignationLabel";
export { TextField, SelectField } from "./Field";
export { PageHeader } from "./PageHeader";
export { EmptyState } from "./EmptyState";
export { SignedOutGate } from "./SignedOutGate";
export { Callout } from "./Callout";
export { Workspace, WorkspaceMain, CardGrid } from "./Workspace";
export { PageFrame, PageFrameChrome, PageFrameBody } from "./PageFrame";
// Viewport layout contract lives in @/lib/ui/viewportLayout (imported by shell/workspace).
export {
  AmmoIcon,
  ClassIcon,
  ElementIcon,
  SuperIcon,
  IconBadge,
} from "./DestinyIcons";
export type { AmmoTypeName } from "./DestinyIcons";
export { OfficialFilterIcon } from "./OfficialFilterIcon";
export { WeaponTypeIcon } from "./WeaponTypeIcon";
export { AmmoTypeIcon } from "./AmmoTypeIcon";
export { SlotIcon } from "./SlotIcon";
export { InfoHotspot } from "./InfoHotspot";
export { EntityHotspot } from "./EntityHotspot";
export type { EntityHotspotShowLabel } from "./EntityHotspot";
export { LoadoutColorBar, LoadoutIconPlate } from "./LoadoutColorBar";
export { DesignationIcon, iconFromMap } from "./DesignationIcon";
export {
  useCuratedDesignationIcons,
  useDesignationIcons,
} from "./useDesignationIcons";


