import type { ReactNode } from "react";

import { Panel } from "./Panel";
import { Stack } from "./Stack";
import { Text } from "./Text";

type Tone = "info" | "success" | "warning" | "danger";

const TONE: Record<Tone, "default" | "warning" | "danger"> = {
  info: "default",
  success: "default",
  warning: "warning",
  danger: "danger",
};

const TEXT: Record<Tone, "muted" | "success" | "warning" | "danger"> = {
  info: "muted",
  success: "success",
  warning: "warning",
  danger: "danger",
};

export function Callout({
  title,
  children,
  tone = "info",
}: {
  title?: string;
  children: ReactNode;
  tone?: Tone;
}) {
  return (
    <Panel tone={TONE[tone]} pad="md">
      <Stack gap={6}>
        {title ? (
          <Text size="sm" weight="medium" tone={TEXT[tone]}>
            {title}
          </Text>
        ) : null}
        <Text size="sm" tone={TEXT[tone]}>
          {children}
        </Text>
      </Stack>
    </Panel>
  );
}
