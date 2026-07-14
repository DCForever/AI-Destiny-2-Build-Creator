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
    <div className="flex flex-wrap items-start justify-between gap-2 sm:gap-4">
      <Stack gap={2} className="min-w-0 flex-1">
        <Heading level={1}>{title}</Heading>
        {description ? (
          <Text
            size="sm"
            tone="muted"
            className="leading-snug sm:leading-relaxed max-w-2xl line-clamp-2 sm:line-clamp-none"
          >
            {description}
          </Text>
        ) : null}
      </Stack>
      {actions ? <div className="shrink-0">{actions}</div> : null}
    </div>
  );
}
