import type { CharacterSummary } from "@/lib/bungie/types";

import type { CharacterLabel } from "./types";

export function buildCharacterLabelMap(
  characters: CharacterSummary[],
  membershipDisplayName: string,
): Map<string, CharacterLabel> {
  const displayName = membershipDisplayName.trim() || "Guardian";
  return new Map(
    characters.map((character) => [
      character.characterId,
      { className: character.classType, characterDisplayName: displayName },
    ]),
  );
}
