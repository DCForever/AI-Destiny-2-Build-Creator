"use client";

import { useCallback, useEffect, useState } from "react";

type GuardianClass = "Titan" | "Hunter" | "Warlock";

interface AuthStatus {
  configured: boolean;
  signedIn: boolean;
  bungieMembershipId?: string;
}

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

async function loadAuthStatus(): Promise<{ auth: AuthStatus; error?: string }> {
  const res = await fetch("/api/auth/status");
  if (res.status === 503) {
    return { auth: { configured: false, signedIn: false } };
  }
  if (!res.ok) {
    const body = await res.json() as { error?: string };
    return { auth: { configured: false, signedIn: false }, error: body.error ?? "Could not check Bungie sign-in status" };
  }
  return { auth: await res.json() as AuthStatus };
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
  const [authError, setAuthError] = useState<string | null>(null);
  const [characters, setCharacters] = useState<CharactersResponse | null>(null);
  const [charError, setCharError] = useState<string | null>(null);
  const [bootstrapping, setBootstrapping] = useState(true);
  const [importPhase, setImportPhase] = useState<ImportPhase>("idle");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [importWarning, setImportWarning] = useState<string | null>(null);
  const [importError, setImportError] = useState<string | null>(null);
  const [signingOut, setSigningOut] = useState(false);

  const bootstrap = useCallback(async () => {
    setBootstrapping(true);
    setCharError(null);
    const { auth: nextAuth, error } = await loadAuthStatus();
    setAuth(nextAuth);
    setAuthError(error ?? null);

    if (nextAuth.configured && nextAuth.signedIn) {
      const result = await loadCharacters();
      setCharacters(result.data ?? null);
      setCharError(result.error ?? null);
    } else {
      setCharacters(null);
    }
    setBootstrapping(false);
  }, []);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const { auth: nextAuth, error } = await loadAuthStatus();
      if (cancelled) return;
      setAuth(nextAuth);
      setAuthError(error ?? null);

      if (nextAuth.configured && nextAuth.signedIn) {
        const result = await loadCharacters();
        if (cancelled) return;
        setCharacters(result.data ?? null);
        setCharError(result.error ?? null);
      }
      if (!cancelled) setBootstrapping(false);
    })();
    return () => { cancelled = true; };
  }, []);

  const handleSignIn = () => {
    window.location.href = "/api/auth/login";
  };

  const handleSignOut = async () => {
    setSigningOut(true);
    try {
      await fetch("/api/auth/logout", { method: "POST" });
      setCharacters(null);
      setSelectedId(null);
      setImportWarning(null);
      setImportError(null);
      await bootstrap();
    } catch {
      setAuthError("Sign-out failed");
    } finally {
      setSigningOut(false);
    }
  };

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
    <div className="panel-notch p-5 space-y-4">
      <div className="text-[11px] tracking-widest uppercase text-muted">
        Import from Bungie
      </div>

      {bootstrapping && (
        <div className="flex items-center gap-2 text-xs text-muted">
          <Spinner />
          <span>Checking sign-in…</span>
        </div>
      )}

      {authError && <p className="text-xs text-danger">{authError}</p>}

      {!bootstrapping && auth && !auth.configured && (
        <p className="text-xs text-muted leading-relaxed">
          Bungie sign-in not configured — set BUNGIE_* keys in .env.local
        </p>
      )}

      {!bootstrapping && auth?.configured && !auth.signedIn && (
        <button
          type="button"
          onClick={handleSignIn}
          className="w-full py-2 border border-accent text-accent text-xs tracking-widest uppercase hover:bg-accent/10 transition-colors focus-visible:outline-accent"
        >
          Sign in with Bungie
        </button>
      )}

      {!bootstrapping && auth?.configured && auth.signedIn && (
        <div className="space-y-3">
          <div className="flex items-center justify-between gap-2 text-xs">
            <span className="text-muted truncate">
              {characters?.membership.displayName ?? "Signed in"}
            </span>
            <button
              type="button"
              onClick={() => void handleSignOut()}
              disabled={signingOut}
              className="text-muted hover:text-danger transition-colors focus-visible:outline-accent shrink-0"
            >
              {signingOut ? "Signing out…" : "Sign out"}
            </button>
          </div>

          {charError && <p className="text-xs text-danger">{charError}</p>}

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

          {importWarning && <p className="text-xs text-warning">{importWarning}</p>}
          {importError && <p className="text-xs text-danger">{importError}</p>}
        </div>
      )}
    </div>
  );
}
