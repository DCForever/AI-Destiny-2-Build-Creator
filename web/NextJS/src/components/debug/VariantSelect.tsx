"use client";

import { emptyLookupMessage, variantIdentityFields } from "@/lib/debug/lookupParity";

type Variant = { id: string; name: string; isDefault?: boolean };

type Props = {
  variants: Variant[];
  selectedId: string;
  onChange: (id: string) => void;
  allowClear?: boolean;
};

export function VariantSelect({ variants, selectedId, onChange, allowClear = false }: Props) {
  if (variants.length === 0) {
    return <p className="rounded border border-zinc-800 p-3 text-sm text-zinc-500">{emptyLookupMessage("variant")}</p>;
  }

  return (
    <select
      className="block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
      value={selectedId}
      onChange={(event) => onChange(event.target.value)}
    >
      {allowClear ? <option value="">Variant —</option> : null}
      {variants.map((variant) => {
        const identity = variantIdentityFields(variant);
        return (
          <option key={identity.id} value={identity.id}>
            {identity.name}
            {identity.isDefault ? " (default)" : ""}
          </option>
        );
      })}
    </select>
  );
}
