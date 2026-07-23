import { describe, expect, it } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { createBuildRecord } from "@/lib/db/repositories/buildRepository";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { createVariantRecord, listAttachments } from "@/lib/db/repositories/variantRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import { prepareAttachments } from "./attachmentService";
import { replaceAttachmentByType } from "./replaceAttachmentByType";

describe("replaceAttachmentByType", () => {
  it("detaches prior same-type set and attaches the new one as live", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "r1", 3, "Player");
    seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createBuildRecord(db, user.id, {
      id: "b1",
      name: "Test",
      className: "Warlock",
      subclass: { name: "Dawnblade" },
      exoticArmorHash: null,
      exoticArmorName: null,
      exoticWeaponHash: null,
      exoticWeaponName: null,
      pinnedSuper: null,
      tagIds: [],
      synergyTypes: [{ type: "melee", subType: "Base" }],
      now,
    });
    createVariantRecord(db, {
      id: "v1",
      buildId: "b1",
      name: "Default",
      isDefault: true,
      now,
    });

    createSetRecord(db, user.id, { id: "armor-old", name: "Old", type: "armor", tagIds: [], now });
    createSetRecord(db, user.id, { id: "armor-new", name: "New", type: "armor", tagIds: [], now });
    createSetRecord(db, user.id, { id: "weapon-1", name: "Guns", type: "weapon", tagIds: [], now });

    await prepareAttachments(
      db,
      user.id,
      "v1",
      [
        { setId: "armor-old", mode: "live" },
        { setId: "weapon-1", mode: "live" },
      ],
      now,
    );

    await replaceAttachmentByType(db, user.id, "v1", "armor", "armor-new", now);
    const attachments = listAttachments(db, "v1");
    expect(attachments.map((a) => a.setId).sort()).toEqual(["armor-new", "weapon-1"]);
    expect(attachments.find((a) => a.setId === "armor-new")?.mode).toBe("live");
  });
});
