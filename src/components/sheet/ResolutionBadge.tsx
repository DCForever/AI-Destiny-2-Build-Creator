import type { ResolutionStatus } from "@/lib/build/types";

interface StatusConfig {
  label: string;
  modifier: string;
}

const STATUS_CONFIG: Record<ResolutionStatus, StatusConfig> = {
  verified: { label: "VERIFIED", modifier: "badge-verified" },
  fuzzy: { label: "FUZZY MATCH", modifier: "badge-fuzzy" },
  unresolved: { label: "NOT FOUND", modifier: "badge-unresolved" },
};

interface ResolutionBadgeProps {
  status: ResolutionStatus;
}

export function ResolutionBadge({ status }: ResolutionBadgeProps) {
  const { label, modifier } = STATUS_CONFIG[status];
  return <span className={`badge ${modifier}`}>{label}</span>;
}

interface IllegalBadgeProps {
  reason?: string;
}

export function IllegalBadge({ reason }: IllegalBadgeProps) {
  return (
    <span className="badge badge-illegal" title={reason}>
      ILLEGAL PERK
    </span>
  );
}
