import { describe, expect, it } from "vitest";

import { mergeAttachment, removeAttachment } from "./attachmentMerge";

describe("attachmentMerge", () => {
  it("adds an attachment when the set is not present", () => {
    const result = mergeAttachment([], { setId: "set-a", mode: "live" });

    expect(result).toEqual([{ setId: "set-a", mode: "live" }]);
  });

  it("updates mode when the set already exists", () => {
    const current = [
      { setId: "set-a", mode: "live" as const },
      { setId: "set-b", mode: "snapshot" as const },
    ];

    const result = mergeAttachment(current, { setId: "set-a", mode: "snapshot" });

    expect(result).toEqual([
      { setId: "set-a", mode: "snapshot" },
      { setId: "set-b", mode: "snapshot" },
    ]);
  });

  it("removes a matching attachment", () => {
    const current = [
      { setId: "set-a", mode: "live" as const },
      { setId: "set-b", mode: "snapshot" as const },
    ];

    const result = removeAttachment(current, "set-a");

    expect(result).toEqual([{ setId: "set-b", mode: "snapshot" }]);
  });

  it("preserves other attachments when merging and removing", () => {
    const current = [
      { setId: "set-a", mode: "live" as const },
      { setId: "set-b", mode: "snapshot" as const },
    ];

    expect(mergeAttachment(current, { setId: "set-c", mode: "live" })).toEqual([
      { setId: "set-a", mode: "live" },
      { setId: "set-b", mode: "snapshot" },
      { setId: "set-c", mode: "live" },
    ]);
    expect(removeAttachment(current, "set-c")).toEqual(current);
  });

  it("returns new arrays without mutating the input", () => {
    const current = [{ setId: "set-a", mode: "live" as const }];

    expect(mergeAttachment(current, { setId: "set-a", mode: "snapshot" })).not.toBe(current);
    expect(removeAttachment(current, "set-a")).not.toBe(current);
    expect(current).toEqual([{ setId: "set-a", mode: "live" }]);
  });

  it("supports sequential add and remove for replace-all PATCH flows", () => {
    const afterWeapon = mergeAttachment([], { setId: "weapon-set", mode: "live" });
    const afterArmor = mergeAttachment(afterWeapon, { setId: "armor-set", mode: "snapshot" });
    const afterWeaponModeChange = mergeAttachment(afterArmor, { setId: "weapon-set", mode: "snapshot" });
    const afterRemoveArmor = removeAttachment(afterWeaponModeChange, "armor-set");

    expect(afterRemoveArmor).toEqual([{ setId: "weapon-set", mode: "snapshot" }]);
  });
});
