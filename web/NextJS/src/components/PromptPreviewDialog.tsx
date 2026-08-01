"use client";

import { useEffect, useRef } from "react";

import {
  formatPromptPreview,
  type PromptPreview,
} from "@/lib/llm/composePromptPreview";

interface PromptPreviewDialogProps {
  open: boolean;
  onClose: () => void;
  title: string;
  preview: PromptPreview;
}

export function PromptPreviewDialog({
  open,
  onClose,
  title,
  preview,
}: PromptPreviewDialogProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (open && !dialog.open) {
      dialog.showModal();
    } else if (!open && dialog.open) {
      dialog.close();
    }
  }, [open]);

  const handleCopyAll = async () => {
    await navigator.clipboard.writeText(formatPromptPreview(preview));
  };

  const buttonClass =
    "text-xs border border-line px-4 py-1.5 text-muted hover:text-foreground hover:border-foreground/40 transition-colors focus-visible:outline-accent";

  return (
    <dialog
      ref={dialogRef}
      onClose={onClose}
      onCancel={onClose}
      className="fixed inset-0 z-50 m-auto w-[min(900px,calc(100vw-2rem))] max-h-[90vh] bg-background border border-line p-0 backdrop:bg-background/80 open:flex open:flex-col"
    >
      <div className="panel-notch flex flex-col max-h-[90vh]">
        <div className="flex items-center justify-between gap-4 px-5 py-4 border-b border-line">
          <h2 className="text-sm font-semibold tracking-wide text-foreground">{title}</h2>
          <button
            type="button"
            onClick={onClose}
            className={buttonClass}
            aria-label="Close prompt preview"
          >
            Close
          </button>
        </div>

        <div className="flex-1 overflow-y-auto px-5 py-4 space-y-6 max-h-[calc(90vh-7rem)]">
          <p className="text-xs text-muted leading-relaxed">
            Phase B conversation replay is omitted; only the deterministic prompts and schema
            are shown.
          </p>
          {preview.sections.map((section) => (
            <div key={section.title}>
              <h3 className="text-[11px] tracking-widest uppercase text-muted mb-2">
                {section.title}
              </h3>
              <pre className="text-xs font-mono text-foreground bg-background border border-line p-3 overflow-x-auto whitespace-pre-wrap break-words">
                {section.content}
              </pre>
            </div>
          ))}
        </div>

        <div className="flex justify-end gap-3 px-5 py-4 border-t border-line">
          <button type="button" onClick={() => void handleCopyAll()} className={buttonClass}>
            Copy all
          </button>
          <button type="button" onClick={onClose} className={buttonClass}>
            Close
          </button>
        </div>
      </div>
    </dialog>
  );
}
