import type { InputHTMLAttributes, ReactNode, SelectHTMLAttributes } from "react";

import { Stack } from "./Stack";
import { Text } from "./Text";

const controlClass =
  "w-full bg-surface-raised border border-line px-2 py-1.5 text-sm text-foreground";

export function TextField({
  label,
  hint,
  className = "",
  ...rest
}: {
  label: string;
  hint?: ReactNode;
} & InputHTMLAttributes<HTMLInputElement>) {
  return (
    <Stack gap={4} className={className}>
      <label className="block space-y-1">
        <Text size="xs" tone="muted" as="span">
          {label}
        </Text>
        <input className={controlClass} {...rest} />
      </label>
      {hint}
    </Stack>
  );
}

export function SelectField({
  label,
  children,
  className = "",
  ...rest
}: {
  label: string;
  children: ReactNode;
} & SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <label className={`flex flex-col gap-1 min-w-[180px] ${className}`.trim()}>
      <Text size="xs" tone="muted" as="span">
        {label}
      </Text>
      <select className={controlClass} {...rest}>
        {children}
      </select>
    </label>
  );
}
