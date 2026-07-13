"use client";

import {
  useCallback,
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { createPortal } from "react-dom";

import { ItemIcon } from "@/components/sheet/ItemIcon";

import { Stack } from "./Stack";
import { Text } from "./Text";

/**
 * Only one hotspot popover open at a time (hover or pin).
 * Popover is portaled to document.body so panel clip-path does not crop it.
 */
let activeHotspotId: string | null = null;
const listeners = new Set<() => void>();

function setActiveHotspot(id: string | null) {
  activeHotspotId = id;
  for (const l of listeners) l();
}

/**
 * Hover opens a detail popover; click pins it until dismissed.
 * Optional icon + accentColor appear in the popover header.
 */
export function InfoHotspot({
  title,
  lines,
  kind,
  icon,
  accentColor,
  children,
  className = "",
}: {
  title: string;
  lines: string[];
  kind?: string;
  /** Bungie relative icon path for popover header. */
  icon?: string | null;
  /** Element/class CSS color for icon ring. */
  accentColor?: string | null;
  children: ReactNode;
  className?: string;
}) {
  const reactId = useId();
  const rootRef = useRef<HTMLSpanElement>(null);
  const popupRef = useRef<HTMLDivElement>(null);
  const [hoverOpen, setHoverOpen] = useState(false);
  const [pinned, setPinned] = useState(false);
  const [coords, setCoords] = useState<{ top: number; left: number } | null>(
    null,
  );
  const [, bump] = useState(0);

  useEffect(() => {
    const onChange = () => bump((n) => n + 1);
    listeners.add(onChange);
    return () => {
      listeners.delete(onChange);
      if (activeHotspotId === reactId) setActiveHotspot(null);
    };
  }, [reactId]);

  const isActive = activeHotspotId === reactId;
  const open = isActive && (hoverOpen || pinned);

  const updatePosition = useCallback(() => {
    const el = rootRef.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const pad = 8;
    const width = 280;
    let left = rect.left;
    if (left + width > window.innerWidth - pad) {
      left = Math.max(pad, window.innerWidth - width - pad);
    }
    let top = rect.bottom + 6;
    if (top + 160 > window.innerHeight && rect.top > 180) {
      top = Math.max(pad, rect.top - 6);
      setCoords({ top, left });
      return;
    }
    setCoords({ top, left });
  }, []);

  useLayoutEffect(() => {
    if (!open) {
      setCoords(null);
      return;
    }
    updatePosition();
    const onScroll = () => updatePosition();
    window.addEventListener("scroll", onScroll, true);
    window.addEventListener("resize", onScroll);
    return () => {
      window.removeEventListener("scroll", onScroll, true);
      window.removeEventListener("resize", onScroll);
    };
  }, [open, updatePosition]);

  useLayoutEffect(() => {
    if (!open || !coords || !rootRef.current || !popupRef.current) return;
    const trigger = rootRef.current.getBoundingClientRect();
    const popup = popupRef.current.getBoundingClientRect();
    if (coords.top + popup.height > window.innerHeight - 8) {
      const above = trigger.top - popup.height - 6;
      if (above >= 8) {
        setCoords((c) => (c ? { ...c, top: above } : c));
      }
    }
  }, [open, coords?.top, coords?.left, lines, title, icon]);

  const closePinned = useCallback(() => {
    setPinned(false);
    setHoverOpen(false);
    if (activeHotspotId === reactId) setActiveHotspot(null);
  }, [reactId]);

  useEffect(() => {
    if (!pinned) return;
    function onDoc(e: MouseEvent) {
      const t = e.target as Node;
      if (rootRef.current?.contains(t) || popupRef.current?.contains(t)) return;
      closePinned();
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

  function openThis(nextHover: boolean, nextPinned: boolean) {
    setActiveHotspot(reactId);
    if (nextHover) setHoverOpen(true);
    if (nextPinned) setPinned(true);
  }

  const popup =
    open && coords && typeof document !== "undefined"
      ? createPortal(
          <div
            ref={popupRef}
            id={`${reactId}-popup`}
            role="dialog"
            aria-label={title}
            className={`fixed z-[100] min-w-[240px] max-w-[300px] p-2.5 panel-notch panel-notch-raised shadow-xl border border-line ${
              pinned ? "border-accent" : ""
            }`}
            style={{ top: coords.top, left: coords.left }}
            onMouseEnter={() => {
              setHoverOpen(true);
              setActiveHotspot(reactId);
            }}
            onMouseLeave={() => {
              if (!pinned) {
                setHoverOpen(false);
                if (activeHotspotId === reactId) setActiveHotspot(null);
              }
            }}
          >
            <Stack gap={8}>
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-start gap-2.5 min-w-0">
                  {icon !== undefined ? (
                    <ItemIcon
                      icon={icon}
                      name={title}
                      size={36}
                      accentColor={accentColor}
                    />
                  ) : null}
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
                </div>
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
                <Text
                  key={line}
                  size="sm"
                  tone="muted"
                  className="leading-relaxed whitespace-pre-wrap"
                >
                  {line}
                </Text>
              ))}
            </Stack>
          </div>,
          document.body,
        )
      : null;

  return (
    <span
      ref={rootRef}
      className={`inline-flex max-w-full ${className}`.trim()}
      onMouseEnter={() => openThis(true, false)}
      onMouseLeave={() => {
        if (!pinned) {
          setHoverOpen(false);
          if (activeHotspotId === reactId) setActiveHotspot(null);
        }
      }}
    >
      <button
        type="button"
        id={`${reactId}-trigger`}
        aria-expanded={open}
        aria-controls={open ? `${reactId}-popup` : undefined}
        aria-label={title}
        title={`${title} — hover or click for details`}
        className="inline-flex items-center gap-1.5 max-w-full p-0 m-0 bg-transparent border-0 cursor-pointer font-inherit text-inherit text-left"
        onClick={() => {
          if (pinned) {
            closePinned();
          } else {
            openThis(true, true);
          }
        }}
      >
        {children}
      </button>
      {popup}
    </span>
  );
}
