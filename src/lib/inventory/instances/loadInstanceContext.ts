import type { AuthenticatedUser } from "@/lib/auth/requireUser";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import { getServices } from "@/lib/services";

import { buildCharacterLabelMap } from "./resolveCharacterLabels";
import { buildPlugNameMap } from "./resolvePlugs";
import type { CharacterLabel } from "./types";

export interface InstanceListContext {
  plugMap: Map<number, string>;
  characterLabels?: Map<string, CharacterLabel>;
  membershipDisplayName: string;
}

export async function loadInstanceListContext(auth: AuthenticatedUser): Promise<InstanceListContext> {
  const { entityCache } = await getServices();
  const [weaponPerks, mods, originTraits] = await Promise.all([
    entityCache.getStore("weapon-perks"),
    entityCache.getStore("mods"),
    entityCache.getStore("origin-traits"),
  ]);

  const plugMap = buildPlugNameMap({
    "weapon-perks": weaponPerks,
    mods,
    "origin-traits": originTraits,
  });

  let membershipDisplayName = auth.user.displayName || "Guardian";
  let characterLabels: Map<string, CharacterLabel> | undefined;

  const profileClient = createBungieProfileClient();
  if (profileClient) {
    try {
      const memberships = await profileClient.getMemberships(auth.tokens.accessToken);
      const membership = memberships[0];
      if (membership) {
        membershipDisplayName = membership.displayName.trim() || membershipDisplayName;
        const characters = await profileClient.getCharacters(auth.tokens.accessToken, membership);
        characterLabels = buildCharacterLabelMap(characters, membershipDisplayName);
      }
    } catch {
      // Degrade to DB display name when roster lookup fails.
    }
  }

  return { plugMap, characterLabels, membershipDisplayName };
}
