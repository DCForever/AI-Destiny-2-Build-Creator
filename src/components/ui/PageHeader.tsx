import type { ReactNode } from "react";

import { Stack } from "./Stack";
import { Heading, Text } from "./Text";

export function PageHeader({
  title,
  description,
  actions,
}: {
  title: string;
  description?: ReactNode;
  actions?: ReactNode;
}) {
  return (
    <div className="flex flex-wrap items-start justify-between gap-4">
      <Stack gap={4}>
        <Heading level={1}>{title}</Heading>
        {description ? (
          <Text size="sm" tone="muted" className="leading-relaxed max-w-2xl">
            {description}
          </Text>
        ) : null}
      </Stack>
      {actions}
    </div>
  );
}
