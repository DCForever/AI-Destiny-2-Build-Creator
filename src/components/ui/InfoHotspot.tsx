"use client";

import {
  useCallback,
  useEffect,
  useId,
  useRef,
  useState,
  type ReactNode,
} from "react";

import { Stack } from "./Stack";
import { Text } from "./Text";

/**
 * Hover opens a detail popover; click pins it until dismissed.
 * Mirrors the canvas InfoHotspot pattern for type/subtype/link chips.
 */
export function InfoHotspot({
  title,
  lines,
  kind,
  children,
  className = "",
}: {
  title: string;
  lines: string[];
  kind?: string;
  children: ReactNode;
  className?: string;
}) {
  const reactId = useId();
  const rootRef = useRef<HTMLSpanElement>(null);
  const [hoverOpen, setHoverOpen] = useState(false);
  const [pinned, setPinned] = useState(false);
  const open = hoverOpen || pinned;

  const closePinned = useCallback(() => setPinned(false), []);

  useEffect(() => {
    if (!pinned) return;
    function onDoc(e: MouseEvent) {
      if (!rootRef.current?.contains(e.target as Node)) {
        closePinned();
      }
    }
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") closePinned();
    }
    document.addEventListener("mousedown", onDoc);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDoc);
      document.removeEventListener("keydown", onKey);
    };
  }, [pinned, closePinned]);

  return (
    <span
      ref={rootRef}
      className={`relative inline-flex max-w-full ${className}`.trim()}
      onMouseEnter={() => setHoverOpen(true)}
      onMouseLeave={() => setHoverOpen(false)}
    >
      <button
        type="button"
        id={`${reactId}-trigger`}
        aria-expanded={open}
        aria-controls={open ? `${reactId}-popup` : undefined}
        title={`${title} — hover or click for details`}
        className="inline-flex items-center gap-1 max-w-full p-0 m-0 bg-transparent border-0 cursor-pointer font-inherit text-inherit text-left"
        onClick={() => setPinned((p) => !p)}
      >
        {children}
      </button>
      {open ? (
        <div
          id={`${reactId}-popup`}
          role="dialog"
          aria-label={title}
          className={`absolute z-40 top-full left-0 mt-1.5 min-w-[220px] max-w-[300px] p-2.5 panel-notch panel-notch-raised shadow-lg ${
            pinned ? "border-accent" : ""
          }`}
          onMouseEnter={() => setHoverOpen(true)}
          onMouseLeave={() => setHoverOpen(false)}
        >
          <Stack gap={6}>
            <div className="flex items-start justify-between gap-2">
              <Stack gap={2} className="min-w-0">
                {kind ? (
                  <Text
                    size="xs"
                    tone="muted"
                    className="uppercase tracking-widest"
                  >
                    {kind}
                  </Text>
                ) : null}
                <Text size="sm" weight="medium">
                  {title}
                </Text>
              </Stack>
              {pinned ? (
                <button
                  type="button"
                  className="text-[10px] tracking-widest uppercase text-accent shrink-0"
                  onClick={closePinned}
                >
                  Close
                </button>
              ) : (
                <Text size="xs" tone="muted" className="shrink-0">
                  Click to pin
                </Text>
              )}
            </div>
            {lines.map((line) => (
              <Text key={line} size="sm" tone="muted">
                {line}
              </Text>
            ))}
          </Stack>
        </div>
      ) : null}
    </span>
  );
}
