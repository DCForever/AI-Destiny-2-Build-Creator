import { describe, expect, it } from "vitest";

import {
  canonicalizeDiscoveredKeyword,
  discoverKeywordsFromObjects,
  extractKeywordTokens,
  findEliteCombatantsInText,
  findPhraseAliasesInText,
  isKeywordLikeSubType,
  KEYWORD_REFERENCE_LIMIT,
  resolveEliteCombatant,
  resolvePhraseAlias,
  snippetAroundKeyword,
} from "./keywordScan";

describe("extractKeywordTokens", () => {
  it("picks Sliding and multi-word Title Case terms", () => {
    const tokens = extractKeywordTokens(
      "While Sliding, final blows grant Radiant and Void Overshield.",
    );
    expect(tokens).toContain("Sliding");
    expect(tokens).toContain("Radiant");
    expect(tokens.some((t) => t.includes("Overshield") || t === "Void Overshield")).toBe(
      true,
    );
  });

  it("keeps Bolt Charge and Armor Charge distinct and drops bare Charge", () => {
    expect(extractKeywordTokens("grants Armor Charge when hit.")).toContain(
      "Armor Charge",
    );
    const tokens = extractKeywordTokens(
      "Gains Bolt Charge on hits. Collecting orbs grants Armor Charge. Charge alone is nothing.",
    );
    expect(tokens).toContain("Bolt Charge");
    expect(tokens).toContain("Armor Charge");
    expect(tokens).not.toContain("Charge");
    expect(tokens.filter((t) => t === "Bolt" || t === "Armor")).toEqual([]);
  });
});

describe("discoverKeywordsFromObjects", () => {
  it("finds curated verbs and novel object keywords by frequency", () => {
    const objects = [
      {
        store: "weapon-perks",
        hash: 1,
        name: "Slideways",
        description: "Sliding increases handling and reload.",
      },
      {
        store: "weapon-perks",
        hash: 2,
        name: "Slide Shot",
        description: "Sliding partially reloads this weapon.",
      },
      {
        store: "exotic-armor",
        hash: 3,
        name: "Boots",
        description: "While Sliding, you fire faster.",
      },
      {
        store: "weapon-perks",
        hash: 4,
        name: "Incandescent",
        description: "Defeating a target spreads Scorch.",
      },
    ];
    const found = discoverKeywordsFromObjects(objects, {
      minNovelMentions: 2,
      minCuratedMentions: 1,
    });
    expect(found.some((k) => k.keyword === "Sliding")).toBe(true);
    expect(found.some((k) => k.keyword === "Scorch" && k.origin === "curated")).toBe(
      true,
    );
  });

  it("does not propose Solar Firesprite as novel when Firesprite is curated", () => {
    const found = discoverKeywordsFromObjects(
      [
        {
          store: "set-bonuses",
          hash: 1,
          name: "Solar Siphon",
          description: "Orbs create Solar Firesprites near you.",
        },
        {
          store: "fragments",
          hash: 2,
          name: "Ember of something",
          description: "Collecting a Solar Firesprite grants energy.",
        },
      ],
      { minNovelMentions: 2, minCuratedMentions: 1 },
    );
    expect(found.some((k) => /solar firesprite/i.test(k.keyword))).toBe(false);
    const fire = found.find((k) => k.keyword === "Firesprite");
    expect(fire).toBeTruthy();
    expect(fire?.origin).toBe("curated");
  });

  it("merges Stasis Shard and Stasis Shards into one curated verb", () => {
    const found = discoverKeywordsFromObjects(
      [
        {
          store: "fragments",
          hash: 1,
          name: "Whisper of Rime",
          description: "Collecting a Stasis Shard grants stacks.",
        },
        {
          store: "aspects",
          hash: 2,
          name: "Frostpulse",
          description: "Stasis Shards grant grenade energy.",
        },
      ],
      { minCuratedMentions: 1 },
    );
    const shard = found.filter((k) => /stasis shard/i.test(k.keyword));
    expect(shard).toHaveLength(1);
    expect(shard[0]?.keyword).toBe("Stasis Shard");
    expect(shard[0]?.mentionCount).toBeGreaterThanOrEqual(2);
  });

  it("does not propose Glaive as a novel verb when it is a weapon archetype", () => {
    const found = discoverKeywordsFromObjects(
      [
        {
          store: "weapon-perks",
          hash: 1,
          name: "Impulse Amplifier",
          description: "Glaive projectiles travel faster.",
        },
        {
          store: "weapon-perks",
          hash: 2,
          name: "Close to Melee",
          description: "Glaive melee final blows grant energy.",
        },
      ],
      {
        minNovelMentions: 2,
        resolveExisting: (token) =>
          token.toLowerCase() === "glaive"
            ? {
                type: "weapon_archetype",
                subType: "Glaive",
                label: "Glaive",
              }
            : null,
      },
    );
    expect(found.some((k) => k.keyword === "Glaive")).toBe(false);
  });
});


describe("isKeywordLikeSubType", () => {
  it("accepts Sliding and multi-word keywords", () => {
    expect(isKeywordLikeSubType("Sliding")).toBe(true);
    expect(isKeywordLikeSubType("Bolt Charge")).toBe(true);
    expect(isKeywordLikeSubType("Being in Combat")).toBe(true);
    expect(isKeywordLikeSubType("x")).toBe(false);
  });
});

describe("description-only scanning", () => {
  it("does not treat item/perk names as keyword sources", () => {
    const found = discoverKeywordsFromObjects(
      [
        {
          store: "weapon-perks",
          hash: 1,
          name: "Empty Stagger Being",
          description: "Increases reload speed slightly.",
        },
        {
          store: "weapon-perks",
          hash: 2,
          name: "Empty Stagger Being",
          description: "Slightly increases handling.",
        },
      ],
      { minNovelMentions: 2 },
    );
    expect(found.some((k) => k.keyword === "Empty")).toBe(false);
    expect(found.some((k) => k.keyword === "Stagger")).toBe(false);
    expect(found.some((k) => k.keyword === "Being")).toBe(false);
    expect(found.some((k) => k.keyword === "Being in Combat")).toBe(false);
  });
});

describe("Being → Being in Combat", () => {
  it("canonicalizes aliases", () => {
    expect(resolvePhraseAlias("Being")).toBe("Being in Combat");
    expect(resolvePhraseAlias("being in combat")).toBe("Being in Combat");
    expect(canonicalizeDiscoveredKeyword("Being")).toBe("Being in Combat");
    expect(findPhraseAliasesInText("while being in combat, gain energy.")).toEqual(
      ["Being in Combat"],
    );
  });

  it("expands Title-Case Being and full phrase; never emits bare Being", () => {
    expect(extractKeywordTokens("While Being, final blows grant energy.")).toContain(
      "Being in Combat",
    );
    expect(extractKeywordTokens("While Being, final blows grant energy.")).not.toContain(
      "Being",
    );

    const found = discoverKeywordsFromObjects(
      [
        {
          store: "aspects",
          hash: 1,
          name: "Aspect A",
          description: "While Being, your melee hits harder.",
        },
        {
          store: "fragments",
          hash: 2,
          name: "Fragment B",
          description: "Grants grenade energy while being in combat.",
        },
      ],
      { minNovelMentions: 1, minCuratedMentions: 1 },
    );
    const combat = found.filter((k) => k.keyword === "Being in Combat");
    expect(combat).toHaveLength(1);
    expect(found.some((k) => k.keyword === "Being")).toBe(false);
  });
});

describe("noise keywords Empty / Stagger", () => {
  it("ignores Empty and Stagger in descriptions", () => {
    expect(extractKeywordTokens("When Empty, reload faster. Stagger foes.")).not.toContain(
      "Empty",
    );
    expect(extractKeywordTokens("When Empty, reload faster. Stagger foes.")).not.toContain(
      "Stagger",
    );

    const found = discoverKeywordsFromObjects(
      [
        {
          store: "weapon-perks",
          hash: 1,
          name: "Perk One",
          description: "When Empty, this weapon reloads from reserves.",
        },
        {
          store: "weapon-perks",
          hash: 2,
          name: "Perk Two",
          description: "Final blows Stagger nearby combatants.",
        },
        {
          store: "weapon-perks",
          hash: 3,
          name: "Perk Three",
          description: "Empty magazines grant a brief Empty buff. Stagger again.",
        },
      ],
      { minNovelMentions: 2 },
    );
    expect(found.some((k) => /empty/i.test(k.keyword))).toBe(false);
    expect(found.some((k) => /stagger/i.test(k.keyword))).toBe(false);
  });
});

describe("snippetAroundKeyword", () => {
  it("returns a window around the match", () => {
    const snip = snippetAroundKeyword(
      "Defeating a target while Sliding reloads this weapon from reserves.",
      "Sliding",
      20,
    );
    expect(snip.toLowerCase()).toContain("sliding");
  });
});

describe("references cap", () => {
  it("keeps at least 10 unique object references with snippets", () => {
    const objects = Array.from({ length: 15 }, (_, i) => ({
      store: "weapon-perks",
      hash: i + 1,
      name: `Perk ${i + 1}`,
      description: `While Sliding, perk ${i + 1} does a thing.`,
    }));
    const found = discoverKeywordsFromObjects(objects, {
      minNovelMentions: 2,
      minCuratedMentions: 1,
    });
    const sliding = found.find((k) => k.keyword === "Sliding");
    expect(sliding).toBeTruthy();
    expect(sliding!.sampleObjects.length).toBe(KEYWORD_REFERENCE_LIMIT);
    expect(sliding!.sampleObjects[0]?.snippet.toLowerCase()).toContain("sliding");
  });
});

describe("Champion / Champions", () => {
  it("canonicalizes to singular Champion", () => {
    expect(canonicalizeDiscoveredKeyword("Champions")).toBe("Champion");
    expect(canonicalizeDiscoveredKeyword("Champion")).toBe("Champion");
  });

  it("merges Champion and Champions into one discovered keyword", () => {
    const found = discoverKeywordsFromObjects(
      [
        {
          store: "weapon-perks",
          hash: 1,
          name: "Anti-Barrier",
          description: "Damage against a Champion is increased.",
        },
        {
          store: "artifacts",
          hash: 2,
          name: "Unstoppable",
          description: "Stunning Champions grants ability energy.",
        },
        {
          store: "aspects",
          hash: 3,
          name: "Something",
          description: "Champions drop heavy ammo.",
        },
      ],
      { minNovelMentions: 2 },
    );
    const champ = found.filter((k) => /^champion$/i.test(k.keyword));
    expect(champ).toHaveLength(1);
    expect(champ[0]?.keyword).toBe("Champion");
    expect(champ[0]?.mentionCount).toBeGreaterThanOrEqual(2);
  });
});

describe("elite combatant targets (boss / Champion / miniboss / Tormentor / vehicle)", () => {
  it("resolves aliases to singular canonical labels", () => {
    expect(resolveEliteCombatant("Champions")).toBe("Champion");
    expect(resolveEliteCombatant("mini-bosses")).toBe("Miniboss");
    expect(resolveEliteCombatant("minibosses")).toBe("Miniboss");
    expect(resolveEliteCombatant("mini boss")).toBe("Miniboss");
    expect(resolveEliteCombatant("Tormentors")).toBe("Tormentor");
    expect(resolveEliteCombatant("bosses")).toBe("Boss");
    expect(resolveEliteCombatant("vehicle")).toBe("Vehicle");
    expect(canonicalizeDiscoveredKeyword("mini-bosses")).toBe("Miniboss");
    expect(canonicalizeDiscoveredKeyword("bosses")).toBe("Boss");
  });

  it("extracts each list target, not one multi-target phrase", () => {
    const phrases = [
      "Damaging mini-bosses, Tormentors, or Champions",
      "Sustained damage on minibosses, Champions, and bosses",
      "sustained damage to Champion, miniboss, or boss combatants",
      "Damaging a vehicle, boss, or Champion",
    ];
    for (const text of phrases) {
      const elites = findEliteCombatantsInText(text);
      // Never a joined list keyword
      expect(elites.some((e) => e.includes(",") || /\bor\b/i.test(e))).toBe(
        false,
      );
    }
    expect(findEliteCombatantsInText(phrases[0]!).sort()).toEqual(
      ["Champion", "Miniboss", "Tormentor"].sort(),
    );
    expect(findEliteCombatantsInText(phrases[1]!).sort()).toEqual(
      ["Boss", "Champion", "Miniboss"].sort(),
    );
    expect(findEliteCombatantsInText(phrases[2]!).sort()).toEqual(
      ["Boss", "Champion", "Miniboss"].sort(),
    );
    expect(findEliteCombatantsInText(phrases[3]!).sort()).toEqual(
      ["Boss", "Champion", "Vehicle"].sort(),
    );
  });

  it("does not double-count boss inside mini-boss", () => {
    expect(findEliteCombatantsInText("Damaging mini-bosses grants energy.")).toEqual(
      ["Miniboss"],
    );
  });

  it("discovers each elite target as its own keyword across list-style perk text", () => {
    const found = discoverKeywordsFromObjects(
      [
        {
          store: "weapon-perks",
          hash: 1,
          name: "Sustained Fire",
          description: "Damaging mini-bosses, Tormentors, or Champions",
        },
        {
          store: "weapon-perks",
          hash: 2,
          name: "Honing",
          description:
            "Sustained damage on minibosses, Champions, and bosses",
        },
        {
          store: "artifacts",
          hash: 3,
          name: "Focus Fire",
          description:
            "sustained damage to Champion, miniboss, or boss combatants",
        },
        {
          store: "exotic-weapons",
          hash: 4,
          name: "Heavy Payload",
          description: "Damaging a vehicle, boss, or Champion",
        },
      ],
      { minNovelMentions: 2, minCuratedMentions: 1 },
    );
    const labels = found.map((k) => k.keyword);
    expect(labels).toContain("Champion");
    expect(labels).toContain("Miniboss");
    expect(labels).toContain("Boss");
    expect(labels).toContain("Tormentor");
    expect(labels).toContain("Vehicle");
    // No garbage multi-list designation
    expect(
      labels.some(
        (k) =>
          /,/i.test(k) ||
          /\bor\b/i.test(k) ||
          /mini-bosses.*champion/i.test(k) ||
          /vehicle.*boss/i.test(k),
      ),
    ).toBe(false);
    // Champion appears in all four → one merged row
    const champ = found.find((k) => k.keyword === "Champion");
    expect(champ?.mentionCount).toBe(4);
    expect(champ?.sampleObjects.length).toBeGreaterThanOrEqual(2);
  });
});


describe("Bolt Charge vs Armor Charge", () => {
  it("discovers both as separate curated/object keywords without bare Charge", () => {
    const found = discoverKeywordsFromObjects(
      [
        {
          store: "aspects",
          hash: 1,
          name: "Spark of Beacons",
          description: "While amplified, final blows grant Bolt Charge.",
        },
        {
          store: "fragments",
          hash: 2,
          name: "Spark of Frequency",
          description: "Increases the rate of Bolt Charge generation.",
        },
        {
          store: "mods",
          hash: 3,
          name: "Powerful Attraction",
          description: "Picking up an Orb of Power grants Armor Charge.",
        },
        {
          store: "mods",
          hash: 4,
          name: "Time Dilation",
          description: "Your Armor Charge timer lasts longer.",
        },
      ],
      { minCuratedMentions: 1, minNovelMentions: 2 },
    );
    expect(found.some((k) => k.keyword === "Bolt Charge")).toBe(true);
    expect(found.some((k) => k.keyword === "Armor Charge")).toBe(true);
    expect(found.some((k) => k.keyword === "Charge")).toBe(false);
  });
});


