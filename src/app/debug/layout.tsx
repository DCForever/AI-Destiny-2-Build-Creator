import { notFound, redirect } from "next/navigation";

import { getValidTokens, getSession } from "@/lib/bungie/session";
import { createBungieAuthClient } from "@/lib/bungie/oauth";

export default async function DebugLayout({ children }: { children: React.ReactNode }) {
  if (process.env.NODE_ENV === "production") {
    notFound();
  }

  const session = await getSession();
  const authClient = createBungieAuthClient(
    process.env.NEXT_PUBLIC_APP_URL
      ? `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/callback`
      : "http://127.0.0.1:3000/api/auth/callback",
  );
  const tokens = authClient ? await getValidTokens(session, authClient) : null;
  if (!tokens) {
    redirect("/api/auth/login");
  }

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <header className="border-b border-zinc-800 px-4 py-3">
        <p className="text-sm font-medium text-amber-400">Debug / Service UI (FR-033)</p>
        <nav className="mt-2 flex flex-wrap gap-3 text-sm">
          <a href="/debug/builds" className="underline">
            Builds
          </a>
          <a href="/debug/catalog" className="underline">
            Catalog
          </a>
          <a href="/debug/loadouts" className="underline">
            Loadouts
          </a>
          <a href="/debug/sets" className="underline">
            Sets
          </a>
          <a href="/debug/suggestions" className="underline">
            Suggestions
          </a>
          <a href="/debug/synergies" className="underline">
            Synergies
          </a>
          <a href="/debug/llm-propose" className="underline">
            LLM Propose
          </a>
          <a href="/debug/synergy-gaps" className="underline">
            Synergy Gaps
          </a>
        </nav>
      </header>
      <main className="min-w-0 overflow-x-hidden p-4 [&_input]:max-w-full [&_pre]:max-w-full [&_pre]:min-w-0 [&_pre]:whitespace-pre-wrap [&_pre]:break-words [&_select]:max-w-full">
        {children}
      </main>
    </div>
  );
}
