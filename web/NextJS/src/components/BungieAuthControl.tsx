"use client";

import { Suspense, useCallback, useEffect, useState } from "react";
import { usePathname, useSearchParams } from "next/navigation";

export interface AuthStatus {
  configured: boolean;
  signedIn: boolean;
  bungieMembershipId?: string;
}

export async function loadAuthStatus(): Promise<{ auth: AuthStatus; error?: string }> {
  const res = await fetch("/api/auth/status");
  if (res.status === 503) {
    return { auth: { configured: false, signedIn: false } };
  }
  if (!res.ok) {
    const body = await res.json() as { error?: string };
    return {
      auth: { configured: false, signedIn: false },
      error: body.error ?? "Could not check Bungie sign-in status",
    };
  }
  return { auth: await res.json() as AuthStatus };
}

function Spinner() {
  return (
    <span
      className="inline-block size-3 border border-line border-t-accent rounded-full animate-spin"
      aria-hidden="true"
    />
  );
}

interface BungieAuthControlProps {
  returnUrl?: string;
  onAuthChange?: (auth: AuthStatus) => void;
  compact?: boolean;
  className?: string;
}

export function BungieAuthControl(props: BungieAuthControlProps) {
  return (
    <Suspense
      fallback={
        <div className={`flex items-center gap-2 text-xs text-muted ${props.className ?? ""}`}>
          <Spinner />
          {!props.compact && <span>Checking sign-in…</span>}
        </div>
      }
    >
      <BungieAuthControlInner {...props} />
    </Suspense>
  );
}

function BungieAuthControlInner({
  returnUrl,
  onAuthChange,
  compact = false,
  className = "",
}: BungieAuthControlProps) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [auth, setAuth] = useState<AuthStatus | null>(null);
  const [authError, setAuthError] = useState<string | null>(null);
  const [bootstrapping, setBootstrapping] = useState(true);
  const [signingOut, setSigningOut] = useState(false);

  const resolvedReturnUrl =
    returnUrl ?? `${pathname}${searchParams.size > 0 ? `?${searchParams.toString()}` : ""}`;

  const refresh = useCallback(async () => {
    setBootstrapping(true);
    const { auth: nextAuth, error } = await loadAuthStatus();
    setAuth(nextAuth);
    setAuthError(error ?? null);
    onAuthChange?.(nextAuth);
    setBootstrapping(false);
  }, [onAuthChange]);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const { auth: nextAuth, error } = await loadAuthStatus();
      if (cancelled) return;
      setAuth(nextAuth);
      setAuthError(error ?? null);
      onAuthChange?.(nextAuth);
      setBootstrapping(false);
    })();
    return () => { cancelled = true; };
  }, [onAuthChange]);

  const handleSignIn = () => {
    const params = new URLSearchParams({ returnUrl: resolvedReturnUrl });
    window.location.href = `/api/auth/login?${params}`;
  };

  const handleSignOut = async () => {
    setSigningOut(true);
    try {
      await fetch("/api/auth/logout", { method: "POST" });
      await refresh();
    } catch {
      setAuthError("Sign-out failed");
    } finally {
      setSigningOut(false);
    }
  };

  if (bootstrapping) {
    return (
      <div className={`flex items-center gap-2 text-xs text-muted ${className}`}>
        <Spinner />
        {!compact && <span>Checking sign-in…</span>}
      </div>
    );
  }

  if (authError) {
    return <p className={`text-xs text-danger ${className}`}>{authError}</p>;
  }

  if (!auth?.configured) {
    if (compact) return null;
    return (
      <p className={`text-xs text-muted leading-relaxed ${className}`}>
        Bungie sign-in not configured — set BUNGIE_* keys in .env.local
      </p>
    );
  }

  if (!auth.signedIn) {
    return (
      <button
        type="button"
        onClick={handleSignIn}
        className={`${compact ? "text-[11px] tracking-widest uppercase border border-accent text-accent px-3 py-1 hover:bg-accent/10" : "w-full py-2 border border-accent text-accent text-xs tracking-widest uppercase hover:bg-accent/10"} transition-colors focus-visible:outline-accent ${className}`}
      >
        Sign in with Bungie
      </button>
    );
  }

  return (
    <div className={`flex items-center gap-2 text-xs ${className}`}>
      <span className="text-muted truncate max-w-[140px]" title="Signed in">
        Signed in
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
  );
}
