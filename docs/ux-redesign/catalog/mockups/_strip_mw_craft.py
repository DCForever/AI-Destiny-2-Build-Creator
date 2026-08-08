"""Remove MW/Craft from WeaponInstanceStrip mockups — chip = power + tier + special only."""
from __future__ import annotations

import re
from pathlib import Path

DIR = Path(__file__).resolve().parent


def strip_file(path: Path) -> None:
    t = path.read_text(encoding="utf-8")

    t = t.replace(
        """    .inst-chip .mark {
      font-size: 9px;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      color: var(--muted-dim);
    }
    .inst-chip[aria-pressed="true"] .mark { color: var(--accent); }
""",
        "",
    )

    t = t.replace(
        "/** @typedef {{ id: string, power: number, tier?: number, special?: string, mw?: boolean, crafted?: boolean }} Inst */",
        "/** @typedef {{ id: string, power: number, tier?: number, special?: string }} Inst */",
    )

    t = t.replace(
        '{ id: "i-high", power: 450, tier: 5, special: "Adept", mw: true },',
        '{ id: "i-high", power: 450, tier: 5, special: "Adept" },',
    )
    t = t.replace(
        '{ id: "i-low", power: 335, tier: 3, special: "Adept", crafted: true },',
        '{ id: "i-low", power: 335, tier: 3, special: "Adept" },',
    )

    t = t.replace(
        """        highestMw: true,
        lowestCrafted: true,
        baseTier: 5,""",
        """        baseTier: 5,""",
    )

    t = t.replace(
        """            special: i === 0 ? knobs.highestSpecial || undefined : undefined,
            mw: knobs.highestMw && i === 0,
            crafted: knobs.lowestCrafted && i === knobs.count - 1 && knobs.count > 1,
          });""",
        """            special: i === 0 ? knobs.highestSpecial || undefined : undefined,
          });""",
    )

    t = t.replace(
        """      function titleFor(inst) {
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
      }""",
        """      function titleFor(inst) {
        return chipLabel(inst);
      }

      function ariaName(inst) {
        let n = "Power " + inst.power;
        if (inst.tier != null) n += ", tier " + inst.tier;
        if (inst.special) n += ", " + inst.special;
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
        return html;
      }""",
    )

    # mobile variant without comment
    t = t.replace(
        """      function titleFor(inst) {
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
        if (inst.mw) html += `<span class="mark">MW</span>`;
        if (inst.crafted) html += `<span class="mark">Craft</span>`;
        return html;
      }""",
        """      function titleFor(inst) {
        return chipLabel(inst);
      }

      function ariaName(inst) {
        let n = "Power " + inst.power;
        if (inst.tier != null) n += ", tier " + inst.tier;
        if (inst.special) n += ", " + inst.special;
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
        return html;
      }""",
    )

    t = re.sub(
        r',\s*mw:\s*true',
        "",
        t,
    )
    t = re.sub(
        r',\s*crafted:\s*true',
        "",
        t,
    )
    t = re.sub(
        r"\n\s*mw:\s*i === 0,\s*\n\s*crafted:\s*i === 7,",
        "\n",
        t,
    )
    t = re.sub(
        r"\n\s*mw:\s*i === 0,\s*\n\s*crafted:\s*i === 7,\s*\n",
        "\n",
        t,
    )

    t = re.sub(
        r'\$\{escapeHtml\(chipLabel\(i\)\)\}\$\{[\s\S]*?i\.crafted \? " · Craft" : ""\}',
        r"${escapeHtml(chipLabel(i))}",
        t,
    )

    t = t.replace(
        """      <option value="multi-mw">Highest is masterwork ON</option>
      <option value="multi-craft">Lowest is crafted ON</option>
      <option value="both-marks">One copy MW + Craft</option>
      <option value="multi-pl-fixture">Fixed fixture · 1810 MW / 1800 / 1790 Craft</option>""",
        """      <option value="special-adept">Special · Adept copies</option>
      <option value="special-holofoil">Special · Holofoil + base</option>
      <option value="multi-pl-fixture">Fixed fixture · 450 T5 Adept / 445 T4 / 335 T3 Adept</option>""",
    )
    t = t.replace(
        """      <option value="multi-mw">Highest is masterwork ON</option>
      <option value="multi-craft">Lowest is crafted ON</option>
      <option value="both-marks">One copy MW + Craft</option>
      <option value="multi-pl-fixture">Fixed 1810 MW / 1800 / 1790 Craft</option>""",
        """      <option value="special-adept">Special · Adept copies</option>
      <option value="special-holofoil">Special · Holofoil + base</option>
      <option value="multi-pl-fixture">Fixed · 450 T5 Adept / 445 T4 / 335 T3 Adept</option>""",
    )

    t = t.replace('case "multi-mw":', 'case "special-adept":')
    t = t.replace('case "multi-craft":', 'case "special-holofoil":')
    t = t.replace('case "both-marks":', 'case "special-holofoil":  // alias')

    t = t.replace(
        'caption: "Highest Adept + MW mark · label e.g. 450 T5 Adept",',
        'caption: "Adept specialness · e.g. 450 T5 Adept",',
    )
    t = t.replace(
        'caption: "Highest MW · compact .mark",',
        'caption: "Adept specialness · e.g. 450 T5 Adept",',
    )
    t = t.replace(
        'caption: "Lowest crafted · Craft secondary mark (not version specialness)",',
        'caption: "Holofoil mixed with base · power-desc",',
    )
    t = t.replace(
        'caption: "Lowest crafted mark",',
        'caption: "Holofoil mixed with base · power-desc",',
    )
    t = t.replace(
        'caption: "Holofoil + MW + Craft · special primary · flags secondary",',
        'caption: "Holofoil only · no MW/Craft on chip",',
    )
    t = t.replace(
        'caption: "MW + Craft on one chip",',
        'caption: "Holofoil only · no MW/Craft on chip",',
    )
    t = t.replace(
        'caption: "All knobs · instance strip (Empty, count, highest, step, MW, Craft)",',
        'caption: "All knobs · empty, count, power, step, tier, special",',
    )

    t = t.replace(
        "flat label <code>PL {n}[ · MW][ · Craft]</code> — missing tier &amp; version specialness ·",
        "flat label <code>PL {n}</code> — missing tier &amp; version specialness ·",
    )
    t = t.replace(
        """              <span class="fake-choice sel">PL 450 · MW</span>
              <span class="fake-choice">PL 445</span>
              <span class="fake-choice">PL 335 · Craft</span>""",
        """              <span class="fake-choice sel">PL 450</span>
              <span class="fake-choice">PL 445</span>
              <span class="fake-choice">PL 335</span>""",
    )
    t = t.replace(
        "optional MW/Craft marks · Instances label · H-scroll nowrap.",
        "Instances label · H-scroll nowrap · no MW/Craft on chip.",
    )
    t = t.replace(
        """          <li>Optional secondary marks: MW / Craft (not version names)</li>
""",
        "",
    )
    t = t.replace(
        "Keyboard: Tab into chips · Space/Enter selects · aria-pressed · title = Power · MW · crafted.",
        "Keyboard: Tab into chips · Space/Enter selects · aria-pressed · title = power · tier · special.",
    )
    t = t.replace(
        "Material density / selected fill / flat PL · MW string. No inset accent bar.",
        "Material density / selected fill / flat PL. No tier/special. No inset accent bar.",
    )

    t = t.replace(
        """        <div class="knob-row">
          <label for="k-mw">Highest is masterwork</label>
          <button type="button" class="toggle-btn" id="k-mw" aria-pressed="true">MW on</button>
        </div>
        <div class="knob-row">
          <label for="k-craft">Lowest is crafted</label>
          <button type="button" class="toggle-btn" id="k-craft" aria-pressed="true">Craft on</button>
        </div>
""",
        "",
    )
    t = t.replace(
        """              <label>Highest is masterwork</label>
              <button type="button" class="toggle-btn" id="k-mw" aria-pressed="${knobs.highestMw}">${knobs.highestMw ? "MW on" : "MW off"}</button>
            </div>
            <div class="knob-row">
              <label>Lowest is crafted</label>
              <button type="button" class="toggle-btn" id="k-craft" aria-pressed="${knobs.lowestCrafted}">${knobs.lowestCrafted ? "Craft on" : "Craft off"}</button>
            </div>
""",
        "",
    )

    t = t.replace(
        """      wireToggle($("#k-mw"), "highestMw", "MW on", "MW off");
      wireToggle($("#k-craft"), "lowestCrafted", "Craft on", "Craft off");
""",
        "",
    )
    t = t.replace(
        """        const mwBtn = document.getElementById("k-mw");
        const craftBtn = document.getElementById("k-craft");
""",
        "",
    )
    t = t.replace(
        """        toggle(mwBtn, "highestMw", "MW on", "MW off");
        toggle(craftBtn, "lowestCrafted", "Craft on", "Craft off");
""",
        "",
    )

    # live log flags block (desktop)
    t = re.sub(
        r'\n\s*"flags: " \+\s*\n\s*\(sel\s*\n\s*\? \[sel\.mw \? "MW" : null, sel\.crafted \? "Craft" : null\]\.filter\(Boolean\)\.join\(" · "\) \|\| "none"\s*\n\s*: "—"\),',
        "",
        t,
    )

    # special-holofoil scenario: ensure holofoil data on mid when was craft scenario
    t = t.replace(
        """              instances: [
                { id: "hi", power: 450, tier: 5 },
                { id: "mid", power: 440, tier: 4 },
                { id: "lo", power: 335, tier: 2 },
              ],
              selectedId: null,
              mount: "frame",
              caption: "Holofoil mixed with base · power-desc",
            };""",
        """              instances: [
                { id: "hi", power: 450, tier: 5 },
                { id: "mid", power: 440, tier: 4, special: "Holofoil" },
                { id: "lo", power: 335, tier: 2 },
              ],
              selectedId: null,
              mount: "frame",
              caption: "Holofoil mixed with base · power-desc",
            };""",
    )

    path.write_text(t, encoding="utf-8")
    print("patched", path.name)
    # sanity
    for bad in [" · MW", " · Craft", "masterwork", "crafted: true", "mw: true", "highestMw"]:
        if bad in path.read_text(encoding="utf-8"):
            # allow "masterwork" only if any leftover - report
            if bad in ("masterwork",) and "masterwork" not in path.read_text(encoding="utf-8"):
                continue
            count = path.read_text(encoding="utf-8").count(bad)
            if count:
                print(f"  warn residual {bad!r} x{count}")


def main() -> None:
    for name in (
        "002-weapon-instance-strip-desktop.html",
        "002-weapon-instance-strip-mobile.html",
    ):
        strip_file(DIR / name)


if __name__ == "__main__":
    main()
