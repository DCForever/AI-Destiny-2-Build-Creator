export type AttachmentSnapshotConfig = {
  slot: string;
  itemHash: number;
  itemName: string;
  selectedPerks?: number[];
  masterworkHash?: number | null;
  modHashes?: number[] | null;
  instanceId?: string | null;
};

export type AttachmentInput = {
  setId: string;
  mode: "live" | "snapshot";
  /** Optional; preserved when merging/removing other rows. */
  snapshotConfigs?: AttachmentSnapshotConfig[];
};

export function mergeAttachment(
  current: AttachmentInput[],
  next: AttachmentInput,
): AttachmentInput[] {
  const exists = current.some((attachment) => attachment.setId === next.setId);

  if (!exists) {
    return [...current, next];
  }

  return current.map((attachment) =>
    attachment.setId === next.setId
      ? { ...attachment, ...next, setId: next.setId, mode: next.mode }
      : attachment,
  );
}

export function removeAttachment(
  current: AttachmentInput[],
  setId: string,
): AttachmentInput[] {
  return current.filter((attachment) => attachment.setId !== setId);
}
