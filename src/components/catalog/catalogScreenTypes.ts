import type { CatalogItem } from "@/lib/catalog/types";

export type CatalogKind = "weapons" | "armor";
export type CatalogScope = "all" | "owned";

/** Locks / initial filters when Catalog is embedded (e.g. Set slot fill). */
export type CatalogConstraints = {
  kind?: CatalogKind;
  /** Catalog bucket label: Kinetic, Gauntlets, … */
  slot?: string | null;
  scope?: CatalogScope;
  onlyExotic?: boolean;
  lockKind?: boolean;
  lockSlot?: boolean;
};

export type CatalogPickResult = {
  hash: number;
  name: string;
  slot?: string;
  ownedCount: number;
  instanceId?: string | null;
  item: CatalogItem;
};

export type CatalogSelectionConfig = {
  enabled: boolean;
  onConfirm: (pick: CatalogPickResult) => void;
  onCancel?: () => void;
  /** Disable confirm while parent is saving. */
  busy?: boolean;
  confirmLabel?: string;
};

export type CatalogChromeConfig = {
  title?: string;
  description?: string;
  /**
   * When true, fill parent height without PageFrame max-width shell
   * (for WorkspaceMain embeds).
   */
  embedded?: boolean;
};
