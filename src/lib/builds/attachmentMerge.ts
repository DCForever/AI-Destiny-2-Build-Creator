export type AttachmentInput = { setId: string; mode: "live" | "snapshot" };

export function mergeAttachment(
  current: AttachmentInput[],
  next: AttachmentInput,
): AttachmentInput[] {
  const exists = current.some((attachment) => attachment.setId === next.setId);

  if (!exists) {
    return [...current, next];
  }

  return current.map((attachment) =>
    attachment.setId === next.setId ? { ...attachment, mode: next.mode } : attachment,
  );
}

export function removeAttachment(
  current: AttachmentInput[],
  setId: string,
): AttachmentInput[] {
  return current.filter((attachment) => attachment.setId !== setId);
}
