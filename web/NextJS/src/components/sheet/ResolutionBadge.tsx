import type { ResolutionStatus } from "@/lib/build/types";
import { Badge, type BadgeTone } from "@/components/ui";

interface StatusConfig {
  label: string;
  tone: BadgeTone;
}

const STATUS_CONFIG: Record<ResolutionStatus, StatusConfig> = {
  verified: { label: "VERIFIED", tone: "verified" },
  fuzzy: { label: "FUZZY MATCH", tone: "fuzzy" },
  unresolved: { label: "NOT FOUND", tone: "unresolved" },
};

interface ResolutionBadgeProps {
  status: ResolutionStatus;
}

export function ResolutionBadge({ status }: ResolutionBadgeProps) {
  const { label, tone } = STATUS_CONFIG[status];
  return <Badge tone={tone}>{label}</Badge>;
}

interface IllegalBadgeProps {
  reason?: string;
}

export function IllegalBadge({ reason }: IllegalBadgeProps) {
  return (
    <Badge tone="illegal" title={reason}>
      ILLEGAL PERK
    </Badge>
  );
}
