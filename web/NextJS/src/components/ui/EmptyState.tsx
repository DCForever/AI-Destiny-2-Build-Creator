import type { ReactNode } from "react";

import { Panel } from "./Panel";
import { Stack } from "./Stack";
import { Text } from "./Text";

export function EmptyState({
  title,
  description,
  action,
  pad = "lg",
}: {
  title?: string;
  description: ReactNode;
  action?: ReactNode;
  pad?: "md" | "lg";
}) {
  return (
    <Panel tone="muted" pad={pad}>
      <Stack gap={10}>
        {title ? (
          <Text weight="medium">{title}</Text>
        ) : null}
        <Text size="sm" tone="muted">
          {description}
        </Text>
        {action}
      </Stack>
    </Panel>
  );
}
