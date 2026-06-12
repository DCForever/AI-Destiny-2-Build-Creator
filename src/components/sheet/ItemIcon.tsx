import Image from "next/image";

interface ItemIconProps {
  icon: string | null;
  name: string;
  size?: number;
}

const NOTCH_CLIP =
  "polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px)";

function PlaceholderIcon({ name, size }: { name: string; size: number }) {
  return (
    <div
      className="flex items-center justify-center border border-line bg-surface text-muted text-xs font-mono flex-shrink-0"
      style={{ width: size, height: size, clipPath: NOTCH_CLIP }}
      aria-label={name}
    >
      {name.charAt(0).toUpperCase()}
    </div>
  );
}

export function ItemIcon({ icon, name, size = 40 }: ItemIconProps) {
  if (!icon) {
    return <PlaceholderIcon name={name} size={size} />;
  }

  return (
    <div
      className="border border-line overflow-hidden flex-shrink-0"
      style={{ width: size, height: size, clipPath: NOTCH_CLIP }}
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
