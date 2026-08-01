import type { ReactNode } from "react";

import { Stack } from "./Stack";
import { Text } from "./Text";

export function SectionLabel({ children }: { children: ReactNode }) {
  return (
    <div className="text-[10px] tracking-[0.14em] uppercase text-muted">
      {children}
    </div>
  );
}

/** Labeled content block — rearrange freely inside Panel / Workspace. */
export function Section({
  label,
  children,
  action,
  gap = 6,
}: {
  label?: string;
  children: ReactNode;
  action?: ReactNode;
  gap?: 4 | 6 | 8 | 10 | 12;
}) {
  return (
    <Stack gap={gap}>
      {label || action ? (
        <div className="flex items-center justify-between gap-2">
          {label ? <SectionLabel>{label}</SectionLabel> : <span />}
          {action}
        </div>
      ) : null}
      {typeof children === "string" ? (
        <Text size="sm">{children}</Text>
      ) : (
        children
      )}
    </Stack>
  );
}
