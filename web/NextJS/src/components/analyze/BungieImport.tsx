"use client";

import { useCallback, useState } from "react";
import { BungieAuthControl, type AuthStatus } from "@/components/BungieAuthControl";
import { Panel, SectionLabel, Stack, Text } from "@/components/ui";

type GuardianClass = "Titan" | "Hunter" | "Warlock";

interface BungieCharacter {
  characterId: string;
  classType: GuardianClass;
  light: number;
  emblemPath: string | null;
  dateLastPlayed: string;
}

interface CharactersResponse {
  membership: { membershipType: number; membershipId: string; displayName: string };
  characters: BungieCharacter[];
}

interface EquipmentResponse {
  equipment: unknown;
  loadoutText: string | null;
}

type ImportPhase = "idle" | "loading-equipment";

function formatLastPlayed(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return iso;
  const diffMs = Date.now() - date.getTime();
  const days = Math.floor(diffMs / 86_400_000);
  if (days === 0) return "Today";
  if (days === 1) return "Yesterday";
  if (days < 7) return `${days} days ago`;
  if (days < 30) return `${Math.floor(days / 7)} weeks ago`;
  return date.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
}

function Spinner() {
  return (
    <span
      className="inline-block size-3 border border-line border-t-accent rounded-full animate-spin"
      aria-hidden="true"
    />
  );
}

async function loadCharacters(): Promise<{ data?: CharactersResponse; error?: string }> {
  const res = await fetch("/api/bungie/characters");
  if (!res.ok) {
    const body = await res.json() as { error?: string };
    return { error: body.error ?? "Failed to load characters" };
  }
  return { data: await res.json() as CharactersResponse };
}

interface BungieImportProps {
  onImport: (loadoutText: string, classType: GuardianClass) => void;
}

export function BungieImport({ onImport }: BungieImportProps) {
  const [auth, setAuth] = useState<AuthStatus | null>(null);
  const [characters, setCharacters] = useState<CharactersResponse | null>(null);
  const [charError, setCharError] = useState<string | null>(null);
  const [importPhase, setImportPhase] = useState<ImportPhase>("idle");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [importWarning, setImportWarning] = useState<string | null>(null);
  const [importError, setImportError] = useState<string | null>(null);

  const loadCharacterList = useCallback(async () => {
    setCharError(null);
    const result = await loadCharacters();
    setCharacters(result.data ?? null);
    setCharError(result.error ?? null);
  }, []);

  const handleAuthChange = useCallback((nextAuth: AuthStatus) => {
    setAuth(nextAuth);
    if (nextAuth.configured && nextAuth.signedIn) {
      void loadCharacterList();
    } else {
      setCharacters(null);
      setSelectedId(null);
      setImportWarning(null);
      setImportError(null);
    }
  }, [loadCharacterList]);

  const handleSelectCharacter = async (character: BungieCharacter) => {
    if (!characters) return;
    setSelectedId(character.characterId);
    setImportWarning(null);
    setImportError(null);
    setImportPhase("loading-equipment");

    const params = new URLSearchParams({
      membershipType: String(characters.membership.membershipType),
      membershipId: characters.membership.membershipId,
      characterId: character.characterId,
    });

    try {
      const res = await fetch(`/api/bungie/equipment?${params}`);
      if (!res.ok) {
        const body = await res.json() as { error?: string };
        setImportError(body.error ?? "Failed to load equipment");
        return;
      }
      const data = await res.json() as EquipmentResponse;
      if (typeof data.loadoutText === "string") {
        onImport(data.loadoutText, character.classType);
      } else {
        setImportWarning("Manifest cache not built — refresh it in Settings to import as text");
      }
    } catch {
      setImportError("Failed to load equipment");
    } finally {
      setImportPhase("idle");
    }
  };

  const isLoading = importPhase !== "idle";

  return (
    <Panel pad="lg">
      <Stack gap={12}>
        <SectionLabel>Import from Bungie</SectionLabel>

        <BungieAuthControl onAuthChange={handleAuthChange} />

        {auth?.configured && auth.signedIn && (
          <Stack gap={10}>
            <Text size="xs" tone="muted" className="truncate">
              {characters?.membership.displayName ?? "Loading characters…"}
            </Text>

            {charError && (
              <Text size="xs" tone="danger">
                {charError}
              </Text>
            )}

            {characters && (
              <ul className="space-y-1" role="listbox" aria-label="Characters">
                {characters.characters.map((character) => {
                  const isSelected = selectedId === character.characterId;
                  const isBusy = isSelected && importPhase === "loading-equipment";
                  return (
                    <li key={character.characterId}>
                      <button
                        type="button"
                        role="option"
                        aria-selected={isSelected}
                        disabled={isLoading}
                        onClick={() => void handleSelectCharacter(character)}
                        className={`w-full flex items-center justify-between gap-3 px-3 py-2 text-left border transition-colors focus-visible:outline-accent disabled:opacity-50 ${
                          isSelected
                            ? "border-accent bg-accent/5"
                            : "border-line hover:border-foreground/30"
                        }`}
                      >
                        <span className="text-xs tracking-widest uppercase text-foreground">
                          {character.classType}
                        </span>
                        <span className="text-xs text-muted">
                          {character.light} · {formatLastPlayed(character.dateLastPlayed)}
                        </span>
                        {isBusy && <Spinner />}
                      </button>
                    </li>
                  );
                })}
              </ul>
            )}

            {importWarning && (
              <Text size="xs" tone="warning">
                {importWarning}
              </Text>
            )}
            {importError && (
              <Text size="xs" tone="danger">
                {importError}
              </Text>
            )}
          </Stack>
        )}
      </Stack>
    </Panel>
  );
}
