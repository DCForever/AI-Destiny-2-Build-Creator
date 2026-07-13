/**
 * Vault Terminal UI primitives.
 *
 * Compose screens from these — avoid ad-hoc panel-notch / badge classes in
 * feature components so layout can be rearranged without restyling.
 */

export { Panel } from "./Panel";
export { Section, SectionLabel } from "./Section";
export { Stack, Row, Cluster } from "./Stack";
export { Text, Heading } from "./Text";
export { Button } from "./Button";
export { Chip, FilterChip } from "./Chip";
export { ConceptTagChip, ConceptTagFilterChip } from "./ConceptTagChip";
export { TextField, SelectField } from "./Field";
export { PageHeader } from "./PageHeader";
export { EmptyState } from "./EmptyState";
export { Callout } from "./Callout";
export { Workspace, WorkspaceMain, CardGrid } from "./Workspace";
export { ClassIcon, ElementIcon, SuperIcon, IconBadge } from "./DestinyIcons";
export { InfoHotspot } from "./InfoHotspot";
export { EntityHotspot } from "./EntityHotspot";
export type { EntityHotspotShowLabel } from "./EntityHotspot";
export { LoadoutColorBar, LoadoutIconPlate } from "./LoadoutColorBar";
export { DesignationIcon, iconFromMap } from "./DesignationIcon";
export {
  useCuratedDesignationIcons,
  useDesignationIcons,
} from "./useDesignationIcons";
