"use client";

import { useEffect, useState } from "react";

import {
  designationIconKey,
  type DesignationRef,
} from "@/lib/synergies/designationIconShared";

type IconMap = Record<string, string | null>;

let cachedCurated: IconMap | null = null;
let curatedPromise: Promise<IconMap> | null = null;

async function fetchIconMap(body: unknown): Promise<IconMap> {
  const res = await fetch("/api/catalog/designation-icons", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) return {};
  const data = (await res.json()) as { icons?: IconMap };
  return data.icons ?? {};
}

/** Load curated verb + element icons (cached across mounts). */
export function useCuratedDesignationIcons(): {
  icons: IconMap;
  loading: boolean;
} {
  const [icons, setIcons] = useState<IconMap>(cachedCurated ?? {});
  const [loading, setLoading] = useState(!cachedCurated);

  useEffect(() => {
    if (cachedCurated) {
      setIcons(cachedCurated);
      setLoading(false);
      return;
    }
    let cancelled = false;
    if (!curatedPromise) {
      curatedPromise = fetchIconMap({ curated: true }).then((map) => {
        cachedCurated = map;
        return map;
      });
    }
    void curatedPromise.then((map) => {
      if (!cancelled) {
        setIcons(map);
        setLoading(false);
      }
    });
    return () => {
      cancelled = true;
    };
  }, []);

  return { icons, loading };
}

/** Resolve icons for a specific list of designations (merged with curated cache). */
export function useDesignationIcons(refs: DesignationRef[]): {
  icons: IconMap;
  loading: boolean;
  getIcon: (type: string, subType?: string | null) => string | null;
} {
  const { icons: curated } = useCuratedDesignationIcons();
  const [extra, setExtra] = useState<IconMap>({});
  const [loading, setLoading] = useState(false);

  const key = refs
    .map((r) => designationIconKey(r.type, r.subType))
    .sort()
    .join("|");

  useEffect(() => {
    if (refs.length === 0) {
      setExtra({});
      return;
    }
    const missing = refs.filter((r) => {
      const k = designationIconKey(r.type, r.subType);
      return curated[k] === undefined;
    });
    if (missing.length === 0) {
      setExtra({});
      return;
    }
    let cancelled = false;
    setLoading(true);
    void fetchIconMap({ designations: missing }).then((map) => {
      if (!cancelled) {
        setExtra(map);
        setLoading(false);
      }
    });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- key encodes refs
  }, [key, curated]);

  const icons = { ...curated, ...extra };
  return {
    icons,
    loading,
    getIcon: (type, subType) =>
      icons[designationIconKey(type, subType)] ?? null,
  };
}
