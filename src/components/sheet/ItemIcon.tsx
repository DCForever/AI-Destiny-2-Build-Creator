import Image from "next/image";

interface ItemIconProps {
  icon: string | null;
  name: string;
  size?: number;
  /** Optional element/class accent for border ring. */
  accentColor?: string | null;
}

const NOTCH_CLIP =
  "polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px)";

function PlaceholderIcon({
  name,
  size,
  accentColor,
}: {
  name: string;
  size: number;
  accentColor?: string | null;
}) {
  return (
    <div
      className="flex items-center justify-center border bg-surface text-muted text-xs font-mono flex-shrink-0"
      style={{
        width: size,
        height: size,
        clipPath: NOTCH_CLIP,
        borderColor: accentColor ?? undefined,
        boxShadow: accentColor ? `inset 0 0 0 1px ${accentColor}44` : undefined,
      }}
      aria-label={name}
    >
      {name.charAt(0).toUpperCase()}
    </div>
  );
}

export function ItemIcon({
  icon,
  name,
  size = 40,
  accentColor,
}: ItemIconProps) {
  if (!icon) {
    return (
      <PlaceholderIcon name={name} size={size} accentColor={accentColor} />
    );
  }

  return (
    <div
      className="border overflow-hidden flex-shrink-0"
      style={{
        width: size,
        height: size,
        clipPath: NOTCH_CLIP,
        borderColor: accentColor ?? undefined,
        boxShadow: accentColor ? `inset 0 0 0 1px ${accentColor}44` : undefined,
      }}
    >
      <Image
        src={`https://www.bungie.net${icon}`}
        alt={name}
        width={size}
        height={size}
        className="block"
        onError={undefined}
      />
    </div>
  );
}
