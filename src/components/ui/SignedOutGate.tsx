import type { ReactNode } from "react";

import { EmptyState } from "./EmptyState";
import { PageFrame, PageFrameBody, PageFrameChrome } from "./PageFrame";
import { PageHeader } from "./PageHeader";

/**
 * Full-width product chrome for Bungie-session screens when the user is signed out.
 * Viewport-stable: shell height is fixed; content does not grow the document.
 */
export function SignedOutGate({
  title,
  description,
  emptyTitle = "Sign in required",
  emptyDescription = "Sign in with Bungie using the control in the header to continue.",
  actions,
}: {
  title: string;
  description?: ReactNode;
  emptyTitle?: string;
  emptyDescription?: ReactNode;
  actions?: ReactNode;
}) {
  return (
    <PageFrame>
      <PageFrameChrome>
        <PageHeader title={title} description={description} actions={actions} />
      </PageFrameChrome>
      <PageFrameBody scroll>
        <EmptyState title={emptyTitle} description={emptyDescription} />
      </PageFrameBody>
    </PageFrame>
  );
}
