"""Patch instance-strip mockups for power + tier + specialness labels."""
from __future__ import annotations

from pathlib import Path

DIR = Path(__file__).resolve().parent

CHIP_CSS = """
    .inst-chip .pw {
      color: var(--fg);
      font-weight: 500;
      font-variant-numeric: tabular-nums;
    }
    .inst-chip .tier {
      font-size: 10px;
      font-weight: 500;
      color: var(--muted);
      font-variant-numeric: tabular-nums;
    }
    .inst-chip[aria-pressed="true"] .tier { color: var(--fg); }
    .inst-chip .special {
      font-size: 9px;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      color: var(--muted-dim);
    }
    .inst-chip[aria-pressed="true"] .special { color: var(--accent); }
    .inst-chip .mark {
      font-size: 9px;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      color: var(--muted-dim);
    }
    .inst-chip[aria-pressed="true"] .mark { color: var(--accent); }
"""

OLD_CSS_DESKTOP = """    .inst-chip .pw {
      color: var(--fg);
      font-weight: 500;
    }
    .inst-chip .mark {
      font-size: 9px;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      color: var(--muted-dim);
    }
    .inst-chip[aria-pressed="true"] .mark { color: var(--accent); }"""

OLD_CSS_MOBILE = """    .inst-chip .pw { color: var(--fg); font-weight: 500; }
    .inst-chip .mark {
      font-size: 9px;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      color: var(--muted-dim);
    }
    .inst-chip[aria-pressed="true"] .mark { color: var(--accent); }"""

# Shared JS helpers to inject (string replacements)
TYPEDEF_OLD = (
    "/** @typedef {{ id: string, power: number, mw?: boolean, crafted?: boolean }} Inst */"
)
TYPEDEF_NEW = (
    "/** @typedef {{ id: string, power: number, tier?: number, special?: string, "
    "mw?: boolean, crafted?: boolean }} Inst */"
)

# Label builders + render chip body
HELPERS_OLD_START = "      function titleFor(inst) {"
# We'll replace from titleFor through end of renderStrip chip map carefully per file

DESKTOP = DIR / "002-weapon-instance-strip-desktop.html"
MOBILE = DIR / "002-weapon-instance-strip-mobile.html"


def patch_css(path: Path, old: str) -> None:
    t = path.read_text(encoding="utf-8")
    if old not in t:
        raise SystemExit(f"CSS block not found in {path.name}")
    path.write_text(t.replace(old, CHIP_CSS.strip() + "\n", 1), encoding="utf-8")
    print(f"  CSS: {path.name}")


def patch_common_js(t: str) -> str:
    t = t.replace(TYPEDEF_OLD, TYPEDEF_NEW, 1)

    # FIXED_FIXTURE
    old_fix = """      const FIXED_FIXTURE = /** @type {Inst[]} */ ([
        { id: "i-high", power: 1810, mw: true },
        { id: "i-mid", power: 1800 },
        { id: "i-low", power: 1790, crafted: true },
      ]);"""
    new_fix = """      const FIXED_FIXTURE = /** @type {Inst[]} */ ([
        { id: "i-high", power: 450, tier: 5, special: "Adept", mw: true },
        { id: "i-mid", power: 445, tier: 4 },
        { id: "i-low", power: 335, tier: 3, special: "Adept", crafted: true },
      ]);"""
    if old_fix not in t:
        raise SystemExit("FIXED_FIXTURE not found")
    t = t.replace(old_fix, new_fix, 1)

    # knobs high power default + tier/special knobs fields
    t = t.replace(
        """      const knobs = {
        empty: false,
        count: 3,
        highest: 1810,
        step: 10,
        highestMw: true,
        lowestCrafted: true,
      };""",
        """      const knobs = {
        empty: false,
        count: 3,
        highest: 450,
        step: 10,
        highestMw: true,
        lowestCrafted: true,
        baseTier: 5,
        highestSpecial: "Adept",
      };""",
        1,
    )

    # buildFromKnobs body
    old_build = """      function buildFromKnobs() {
        if (knobs.empty) return [];
        const out = [];
        for (let i = 0; i < knobs.count; i++) {
          const power = knobs.highest - i * knobs.step;
          out.push({
            id: "k-" + i,
            power,
            mw: knobs.highestMw && i === 0,
            crafted: knobs.lowestCrafted && i === knobs.count - 1 && knobs.count > 1,
          });
        }
        return out;
      }"""
    new_build = """      function buildFromKnobs() {
        if (knobs.empty) return [];
        const out = [];
        for (let i = 0; i < knobs.count; i++) {
          const power = knobs.highest - i * knobs.step;
          const tier = Math.max(1, Math.min(5, (knobs.baseTier || 5) - i));
          out.push({
            id: "k-" + i,
            power,
            tier,
            special: i === 0 ? knobs.highestSpecial || undefined : undefined,
            mw: knobs.highestMw && i === 0,
            crafted: knobs.lowestCrafted && i === knobs.count - 1 && knobs.count > 1,
          });
        }
        return out;
      }"""
    if old_build not in t:
        raise SystemExit("buildFromKnobs not found")
    t = t.replace(old_build, new_build, 1)

    # titleFor + ariaName + chipLabelHtml
    old_labels = """      function titleFor(inst) {
        let t = "Power " + inst.power;
        if (inst.mw) t += " · MW";
        if (inst.crafted) t += " · crafted";
        return t;
      }

      function ariaName(inst) {
        let n = "PL " + inst.power;
        if (inst.mw) n += ", masterwork";
        if (inst.crafted) n += ", crafted";
        return n;
      }"""
    new_labels = """      function chipLabel(inst) {
        // Canonical display: "{power} T{tier} {special?}" e.g. "335 T3 Adept"
        const parts = [String(inst.power)];
        if (inst.tier != null && inst.tier >= 1 && inst.tier <= 5) {
          parts.push("T" + inst.tier);
        }
        if (inst.special) parts.push(inst.special);
        return parts.join(" ");
      }

      function titleFor(inst) {
        let t = chipLabel(inst);
        if (inst.mw) t += " · masterwork";
        if (inst.crafted) t += " · crafted";
        return t;
      }

      function ariaName(inst) {
        let n = "Power " + inst.power;
        if (inst.tier != null) n += ", tier " + inst.tier;
        if (inst.special) n += ", " + inst.special;
        if (inst.mw) n += ", masterwork";
        if (inst.crafted) n += ", crafted";
        return n;
      }

      function chipInnerHtml(inst) {
        let html = `<span class="pw">${escapeHtml(String(inst.power))}</span>`;
        if (inst.tier != null && inst.tier >= 1 && inst.tier <= 5) {
          html += `<span class="tier">T${inst.tier}</span>`;
        }
        if (inst.special) {
          html += `<span class="special">${escapeHtml(inst.special)}</span>`;
        }
        // Secondary flags only when not already special-version chrome
        if (inst.mw) html += `<span class="mark">MW</span>`;
        if (inst.crafted) html += `<span class="mark">Craft</span>`;
        return html;
      }"""
    if old_labels not in t:
        raise SystemExit("titleFor/ariaName block not found")
    t = t.replace(old_labels, new_labels, 1)

    # renderStrip chip body — two variants for desktop (with marks map) vs mobile
    old_chip_map = """        const chips = ordered
          .map((inst) => {
            const pressed = selectedId === inst.id;
            const marks = [];
            if (inst.mw) marks.push("MW");
            if (inst.crafted) marks.push("Craft");
            const markHtml = marks.length
              ? marks.map((m) => `<span class="mark">${escapeHtml(m)}</span>`).join("")
              : "";
            return `<button type="button" class="inst-chip"
              data-key="instance_chip_${escapeHtml(inst.id)}"
              data-inst="${escapeHtml(inst.id)}"
              aria-pressed="${pressed ? "true" : "false"}"
              aria-label="${escapeHtml(ariaName(inst))}"
              title="${escapeHtml(titleFor(inst))}">
              <span class="pw">PL ${inst.power}</span>${markHtml}
            </button>`;
          })
          .join("");"""
    new_chip_map = """        const chips = ordered
          .map((inst) => {
            const pressed = selectedId === inst.id;
            return `<button type="button" class="inst-chip"
              data-key="instance_chip_${escapeHtml(inst.id)}"
              data-inst="${escapeHtml(inst.id)}"
              aria-pressed="${pressed ? "true" : "false"}"
              aria-label="${escapeHtml(ariaName(inst))}"
              title="${escapeHtml(titleFor(inst))}">
              ${chipInnerHtml(inst)}
            </button>`;
          })
          .join("");"""
    if old_chip_map not in t:
        raise SystemExit("chip map not found")
    t = t.replace(old_chip_map, new_chip_map, 1)

    return t


def patch_desktop_scenarios(t: str) -> str:
    # multi default
    t = t.replace(
        """              instances: [
                { id: "a", power: 1795 },
                { id: "b", power: 1810 },
                { id: "c", power: 1800 },
              ],
              selectedId: null,
              mount: "frame",
              caption: "Multi-PL · defensive re-sort power-desc · highest first + selected",
            };""",
        """              instances: [
                { id: "a", power: 335, tier: 3, special: "Adept" },
                { id: "b", power: 450, tier: 5 },
                { id: "c", power: 445, tier: 4, special: "Holofoil" },
              ],
              selectedId: null,
              mount: "frame",
              caption: "Multi · power-desc · chip = power + T{n} + special · highest selected",
            };""",
        1,
    )
    t = t.replace(
        """              instances: [
                { id: "hi", power: 1810, mw: true },
                { id: "mid", power: 1800 },
                { id: "lo", power: 1790 },
              ],
              selectedId: null,
              mount: "frame",
              caption: "Highest is masterwork · compact .mark MW on first chip only",
            };""",
        """              instances: [
                { id: "hi", power: 450, tier: 5, special: "Adept", mw: true },
                { id: "mid", power: 445, tier: 4 },
                { id: "lo", power: 430, tier: 3 },
              ],
              selectedId: null,
              mount: "frame",
              caption: "Highest Adept + MW mark · label e.g. 450 T5 Adept",
            };""",
        1,
    )
    t = t.replace(
        """              instances: [
                { id: "hi", power: 1810 },
                { id: "mid", power: 1800 },
                { id: "lo", power: 1790, crafted: true },
              ],
              selectedId: null,
              mount: "frame",
              caption: "Lowest is crafted · Craft mark on last (lowest power) chip",
            };""",
        """              instances: [
                { id: "hi", power: 450, tier: 5 },
                { id: "mid", power: 440, tier: 4 },
                { id: "lo", power: 335, tier: 2, crafted: true },
              ],
              selectedId: null,
              mount: "frame",
              caption: "Lowest crafted · Craft secondary mark (not version specialness)",
            };""",
        1,
    )
    t = t.replace(
        """              instances: [
                { id: "both", power: 1815, mw: true, crafted: true },
                { id: "plain", power: 1800 },
              ],
              selectedId: null,
              mount: "frame",
              caption: "MW + Craft on one copy · two .mark spans · no second chip shell",
            };""",
        """              instances: [
                { id: "both", power: 450, tier: 5, special: "Holofoil", mw: true, crafted: true },
                { id: "plain", power: 420, tier: 3 },
              ],
              selectedId: null,
              mount: "frame",
              caption: "Holofoil + MW + Craft · special primary · flags secondary",
            };""",
        1,
    )
    t = t.replace(
        """              instances: [{ id: "only", power: 1805 }],
              selectedId: "only",
              mount: "frame",
              caption: "Single copy · Instances label present · default selected",
            };""",
        """              instances: [{ id: "only", power: 335, tier: 3, special: "Adept" }],
              selectedId: "only",
              mount: "frame",
              caption: "Single · 335 T3 Adept · Instances label · selected",
            };""",
        1,
    )
    # overflow list builder
    t = t.replace(
        """                power: 1820 - i * 10,
                mw: i === 0,
                crafted: i === 7,""",
        """                power: 450 - i * 5,
                tier: Math.max(1, 5 - Math.floor(i / 2)),
                special: i === 0 ? "Adept" : i === 3 ? "Holofoil" : undefined,
                mw: i === 0,
                crafted: i === 7,""",
        1,
    )

    # dual-truth fake choice labels
    t = t.replace(
        """                          `<span class="fake-choice ${state.selectedId === i.id ? "sel" : ""}">PL ${i.power}${
                            i.mw ? " · MW" : ""
                          }${i.crafted ? " · Craft" : ""}</span>`""",
        """                          `<span class="fake-choice ${state.selectedId === i.id ? "sel" : ""}">${escapeHtml(chipLabel(i))}${
                            i.mw ? " · MW" : ""
                          }${i.crafted ? " · Craft" : ""}</span>`""",
        1,
    )

    # ship compare text
    t = t.replace(
        """              single flat label <code>PL {n}[ · MW][ · Craft]</code> ·
              no “Instances” label · no inset accent bar.""",
        """              flat label <code>PL {n}[ · MW][ · Craft]</code> — missing tier &amp; version specialness ·
              no “Instances” label · no inset accent bar.""",
        1,
    )
    t = t.replace(
        """              <span class="fake-choice sel">PL 1810 · MW</span>
              <span class="fake-choice">PL 1800</span>
              <span class="fake-choice">PL 1790 · Craft</span>""",
        """              <span class="fake-choice sel">PL 450 · MW</span>
              <span class="fake-choice">PL 445</span>
              <span class="fake-choice">PL 335 · Craft</span>""",
        1,
    )
    t = t.replace(
        """              <code>.pw</code> + compact <code>.mark</code> · uppercase Instances label · H-scroll nowrap.""",
        """              label <code>{power} T{n} {special?}</code> e.g. <code>335 T3 Adept</code> ·
              optional MW/Craft marks · Instances label · H-scroll nowrap.""",
        1,
    )
    t = t.replace(
        """          <li>Marks: boolean MW / Craft only (no invented stat type)</li>""",
        """          <li>Chip text: <code>{power} T{1-5} {Adept|Holofoil|…?}</code> — specialness only when version is special</li>
          <li>Optional secondary marks: MW / Craft (not version names)</li>""",
        1,
    )
    t = t.replace(
        "Focused dual-truth close · Flap .inst-chip · power-desc · H-scroll · MW/Craft marks · desktop 26px",
        "Flap .inst-chip · power + tier + specialness · e.g. 335 T3 Adept · H-scroll · desktop 26px",
        1,
    )

    # knobs UI: power range + special + tier
    old_knobs_hi = """          <label for="k-hi">Highest power</label>
          <input type="range" id="k-hi" min="1600" max="2020" step="1" value="1810" />
          <span class="val" id="k-hi-v">1810</span>"""
    new_knobs_hi = """          <label for="k-hi">Highest power</label>
          <input type="range" id="k-hi" min="200" max="600" step="1" value="450" />
          <span class="val" id="k-hi-v">450</span>"""
    t = t.replace(old_knobs_hi, new_knobs_hi, 1)

    old_knobs_end = """        <div class="knob-row">
          <label for="k-craft">Lowest is crafted</label>
          <button type="button" class="toggle-btn" id="k-craft" aria-pressed="true">Craft on</button>
        </div>
      </section>"""
    new_knobs_end = """        <div class="knob-row">
          <label for="k-craft">Lowest is crafted</label>
          <button type="button" class="toggle-btn" id="k-craft" aria-pressed="true">Craft on</button>
        </div>
        <div class="knob-row">
          <label for="k-tier">Highest tier (T1–5)</label>
          <input type="range" id="k-tier" min="1" max="5" value="5" />
          <span class="val" id="k-tier-v">5</span>
        </div>
        <div class="knob-row">
          <label for="k-special">Highest specialness</label>
          <select id="k-special" class="scenario-select" style="min-width:140px;height:26px">
            <option value="">(none)</option>
            <option value="Adept" selected>Adept</option>
            <option value="Holofoil">Holofoil</option>
          </select>
        </div>
      </section>"""
    t = t.replace(old_knobs_end, new_knobs_end, 1)

    # wire knobs for tier/special after craft toggle — desktop uses wireToggle pattern
    if 'wireToggle($("#k-craft")' in t:
        t = t.replace(
            """      wireToggle($("#k-mw"), "highestMw", "MW on", "MW off");
      wireToggle($("#k-craft"), "lowestCrafted", "Craft on", "Craft off");""",
            """      wireToggle($("#k-mw"), "highestMw", "MW on", "MW off");
      wireToggle($("#k-craft"), "lowestCrafted", "Craft on", "Craft off");
      const kTier = $("#k-tier");
      const kTierV = $("#k-tier-v");
      if (kTier) {
        kTier.addEventListener("input", () => {
          knobs.baseTier = Number(kTier.value);
          kTierV.textContent = kTier.value;
          if (scenarioEl.value === "knobs") render();
        });
      }
      const kSpecial = $("#k-special");
      if (kSpecial) {
        kSpecial.addEventListener("change", () => {
          knobs.highestSpecial = kSpecial.value || "";
          if (scenarioEl.value === "knobs") render();
        });
      }""",
            1,
        )

    # live log marks
    t = t.replace(
        """          "marks: " +
            (sel
              ? [sel.mw ? "MW" : null, sel.crafted ? "Craft" : null].filter(Boolean).join(" · ") || "none"
              : "—"),""",
        """          "label: " + (sel ? chipLabel(sel) : "—"),
          "tier: " + (sel && sel.tier != null ? "T" + sel.tier : "—"),
          "special: " + (sel && sel.special ? sel.special : "none"),
          "flags: " +
            (sel
              ? [sel.mw ? "MW" : null, sel.crafted ? "Craft" : null].filter(Boolean).join(" · ") || "none"
              : "—"),""",
        1,
    )
    return t


def patch_mobile(t: str) -> str:
    t = patch_common_js(t)
    # mobile scenarios are more compact
    t = t.replace(
        'return { instances: [{ id: "only", power: 1805 }], selectedId: "only", mount: "frame", caption: "Single copy + Instances label" };',
        'return { instances: [{ id: "only", power: 335, tier: 3, special: "Adept" }], selectedId: "only", mount: "frame", caption: "Single · 335 T3 Adept" };',
        1,
    )
    t = t.replace(
        """              instances: [
                { id: "a", power: 1795 },
                { id: "b", power: 1810 },
                { id: "c", power: 1800 },
              ],""",
        """              instances: [
                { id: "a", power: 335, tier: 3, special: "Adept" },
                { id: "b", power: 450, tier: 5 },
                { id: "c", power: 445, tier: 4, special: "Holofoil" },
              ],""",
        1,
    )
    t = t.replace(
        """              instances: [
                { id: "hi", power: 1810, mw: true },
                { id: "mid", power: 1800 },
                { id: "lo", power: 1790 },
              ],""",
        """              instances: [
                { id: "hi", power: 450, tier: 5, special: "Adept", mw: true },
                { id: "mid", power: 445, tier: 4 },
                { id: "lo", power: 430, tier: 3 },
              ],""",
        1,
    )
    t = t.replace(
        """              instances: [
                { id: "hi", power: 1810 },
                { id: "mid", power: 1800 },
                { id: "lo", power: 1790, crafted: true },
              ],""",
        """              instances: [
                { id: "hi", power: 450, tier: 5 },
                { id: "mid", power: 440, tier: 4 },
                { id: "lo", power: 335, tier: 2, crafted: true },
              ],""",
        1,
    )
    t = t.replace(
        """              instances: [
                { id: "both", power: 1815, mw: true, crafted: true },
                { id: "plain", power: 1800 },
              ],""",
        """              instances: [
                { id: "both", power: 450, tier: 5, special: "Holofoil", mw: true, crafted: true },
                { id: "plain", power: 420, tier: 3 },
              ],""",
        1,
    )
    t = t.replace(
        'list.push({ id: "o" + i, power: 1820 - i * 10, mw: i === 0, crafted: i === 7 });',
        'list.push({ id: "o" + i, power: 450 - i * 5, tier: Math.max(1, 5 - Math.floor(i / 2)), special: i === 0 ? "Adept" : i === 3 ? "Holofoil" : undefined, mw: i === 0, crafted: i === 7 });',
        1,
    )
    t = t.replace(
        """                      `<span class="fake-choice ${state.selectedId === i.id ? "sel" : ""}">PL ${i.power}${
                        i.mw ? " · MW" : ""
                      }${i.crafted ? " · Craft" : ""}</span>`""",
        """                      `<span class="fake-choice ${state.selectedId === i.id ? "sel" : ""}">${escapeHtml(chipLabel(i))}${
                        i.mw ? " · MW" : ""
                      }${i.crafted ? " · Craft" : ""}</span>`""",
        1,
    )
    t = t.replace(
        "Flap .inst-chip · H-scroll · power-desc · chip h=28 (mobile residual density)",
        "power + T{n} + special · e.g. 335 T3 Adept · H-scroll · chip h=28",
        1,
    )
    # mobile knobs highest default
    t = t.replace(
        'min="1600" max="2020"',
        'min="200" max="600"',
        1,
    )
    t = t.replace(
        'id="k-hi" min="200" max="600" step="1" value="1810"',
        'id="k-hi" min="200" max="600" step="1" value="450"',
        1,
    )
    t = t.replace(
        'knobs.highest = 1810',
        'knobs.highest = 450',
    )
    # mobile knobs object
    t = t.replace(
        """      const knobs = {
        empty: false,
        count: 3,
        highest: 1810,
        step: 10,
        highestMw: true,
        lowestCrafted: true,
      };""",
        """      const knobs = {
        empty: false,
        count: 3,
        highest: 450,
        step: 10,
        highestMw: true,
        lowestCrafted: true,
        baseTier: 5,
        highestSpecial: "Adept",
      };""",
        1,
    )
    return t


def main() -> None:
    print("Patching desktop…")
    patch_css(DESKTOP, OLD_CSS_DESKTOP)
    d = DESKTOP.read_text(encoding="utf-8")
    d = patch_common_js(d)
    d = patch_desktop_scenarios(d)
    DESKTOP.write_text(d, encoding="utf-8")
    print("  desktop scenarios ok")

    print("Patching mobile…")
    patch_css(MOBILE, OLD_CSS_MOBILE)
    m = MOBILE.read_text(encoding="utf-8")
    m = patch_mobile(m)
    MOBILE.write_text(m, encoding="utf-8")
    print("  mobile ok")
    print("Done.")


if __name__ == "__main__":
    main()
