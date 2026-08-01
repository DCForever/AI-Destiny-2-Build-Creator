/**
 * Capture UI screenshots into docs/atlas/screenshots and write observations.json.
 * Usage: npm run dev:https (or ATLAS_BASE_URL), then:
 *   $env:ATLAS_BASE_URL="https://127.0.0.1:3000"
 *   $env:ATLAS_STORAGE_STATE=".atlas/auth.json"
 *   npm run atlas:capture
 */
import { chromium } from "playwright";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../../.."); // monorepo root (web/NextJS/scripts -> repo)
const atlasDir = path.join(root, "docs", "atlas");
const shotDir = path.join(atlasDir, "screenshots");
const manifestPath = path.join(atlasDir, "manifest.json");
const obsPath = path.join(atlasDir, "observations.json");

const baseUrl = (process.env.ATLAS_BASE_URL || "http://127.0.0.1:3000").replace(/\/$/, "");
const storageState = process.env.ATLAS_STORAGE_STATE || "";
const skipSignedIn = process.env.ATLAS_SKIP_SIGNED_IN === "1";
const only = process.env.ATLAS_ONLY
  ? new Set(process.env.ATLAS_ONLY.split(",").map((s) => s.trim()).filter(Boolean))
  : null;

fs.mkdirSync(shotDir, { recursive: true });
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));

function settle(ms = 600) {
  return new Promise((r) => setTimeout(r, ms));
}

async function safeClick(page, selectors, timeout = 2500) {
  for (const sel of selectors) {
    try {
      const loc = page.locator(sel).first();
      if ((await loc.count()) === 0) continue;
      if (!(await loc.isVisible().catch(() => false))) continue;
      await loc.click({ timeout });
      return true;
    } catch {
      /* next */
    }
  }
  return false;
}

async function waitForApp(page) {
  await page.waitForLoadState("networkidle", { timeout: 20000 }).catch(() => {});
  await settle(500);
}

async function clickFirstLibraryRow(page) {
  const row = page.locator("aside .flap-row, .flap-board .flap-row").first();
  if ((await row.count()) === 0) return false;
  await row.click({ timeout: 4000 });
  await settle(900);
  await waitForApp(page);
  return true;
}

async function clickComposerTab(page, tabKey) {
  const labelMap = {
    general: "General",
    subclass: "Subclass",
    armor: "Armor & Mod Set",
    weapon: "Weapon Set",
    finish: "Finish",
  };
  const label = labelMap[tabKey] || tabKey;
  return safeClick(page, [
    `main button:text-is("${label}")`,
    `main button:has-text("${label}")`,
    `button:text-is("${label}")`,
  ], 4000);
}

async function openBuildEditComposer(page) {
  if (!(await clickFirstLibraryRow(page))) return false;
  const edited = await safeClick(page, [
    'main article button:has-text("Edit")',
    'main button:text-is("Edit")',
    'main button:has-text("Edit")',
  ], 4000);
  if (!edited) return false;
  await settle(800);
  await page.locator('main button:has-text("General")').first().waitFor({ state: "visible", timeout: 8000 }).catch(() => {});
  return true;
}

async function inventoryElements(page) {
  return page.evaluate(() => {
    const pick = (sel) => Array.from(document.querySelectorAll(sel));
    const visible = (el) => {
      const r = el.getBoundingClientRect();
      const st = getComputedStyle(el);
      return r.width > 0 && r.height > 0 && st.visibility !== "hidden" && st.display !== "none";
    };
    const buttons = pick("button, [role=button], a.button, input[type=button], input[type=submit]").filter(visible);
    const links = pick("a[href]").filter(visible);
    const inputs = pick("input, textarea, select, [contenteditable=true]").filter(visible);
    const tabs = pick("[role=tab], [aria-pressed], nav a, nav button").filter(visible);
    const listItems = pick("li, [role=listitem], [role=option]").filter(visible);
    const icons = pick("svg, img, [class*=icon]").filter(visible);
    const dialogs = pick("[role=dialog], dialog, [aria-modal=true]").filter(visible);
    const labels = [];
    for (const el of [...buttons, ...links].slice(0, 80)) {
      const t = (el.getAttribute("aria-label") || el.textContent || "").replace(/\s+/g, " ").trim();
      if (t && t.length < 80) labels.push(t);
    }
    const byRole = {
      button: buttons.length,
      link: links.length,
      input: inputs.length,
      tab: tabs.length,
      listItem: listItems.length,
      icon: icons.length,
      dialog: dialogs.length,
    };
    const total = Object.values(byRole).reduce((a, b) => a + b, 0);
    return {
      total,
      byRole,
      sampleLabels: [...new Set(labels)].slice(0, 40),
      title: document.title,
      h1: (document.querySelector("h1")?.textContent || "").trim().slice(0, 120),
    };
  });
}

/**
 * Measure deepest nested scrollers BEFORE unlocking (overflow:hidden parents
 * still report scrollHeight of children).
 */
async function measureScrollLayout(page) {
  return page.evaluate(() => {
    const scrollers = [];
    for (const el of document.querySelectorAll("body *")) {
      if (!(el instanceof HTMLElement)) continue;
      const cs = getComputedStyle(el);
      const oy = cs.overflowY;
      if (oy !== "auto" && oy !== "scroll" && oy !== "hidden") continue;
      if (el.scrollHeight <= el.clientHeight + 4) continue;
      const r = el.getBoundingClientRect();
      if (r.width < 80 || r.height < 80) continue;
      scrollers.push({
        scrollHeight: el.scrollHeight,
        clientHeight: el.clientHeight,
        top: r.top + window.scrollY,
        left: r.left + window.scrollX,
        width: r.width,
        tag: el.tagName.toLowerCase(),
        cls: (el.className || "").toString().slice(0, 80),
      });
    }
    scrollers.sort((a, b) => b.scrollHeight - a.scrollHeight);
    return {
      vh: window.innerHeight,
      vw: window.innerWidth,
      docH: Math.max(document.documentElement.scrollHeight, document.body.scrollHeight),
      primary: scrollers[0] || null,
      scrollerCount: scrollers.length,
    };
  });
}

/**
 * Unlock viewport-locked AppShell layout so document height grows to content.
 * body is overflow-hidden + nested flex min-h-0 panes; plain fullPage stays 900px.
 */
async function unlockViewportLayout(page) {
  await page.evaluate(() => {
    const style = document.getElementById("atlas-capture-unlock") || document.createElement("style");
    style.id = "atlas-capture-unlock";
    style.textContent = `
      html, body, #__next, [data-atlas-unlock] {
        height: auto !important;
        max-height: none !important;
        min-height: 0 !important;
        overflow: visible !important;
      }
      body {
        display: block !important;
      }
      body * {
        max-height: none !important;
      }
    `;
    document.head.appendChild(style);

    // Mark ancestors of every tall scroller, then force content height.
    const mark = new Set();
    for (const el of document.querySelectorAll("body *")) {
      if (!(el instanceof HTMLElement)) continue;
      const cs = getComputedStyle(el);
      const oy = cs.overflowY;
      if ((oy === "auto" || oy === "scroll" || oy === "hidden") && el.scrollHeight > el.clientHeight + 4) {
        let n = el;
        while (n && n !== document.documentElement) {
          mark.add(n);
          n = n.parentElement;
        }
      }
    }
    for (const el of mark) {
      el.setAttribute("data-atlas-unlock", "1");
      const sh = el.scrollHeight;
      el.style.setProperty("overflow", "visible", "important");
      el.style.setProperty("overflow-y", "visible", "important");
      el.style.setProperty("height", "auto", "important");
      el.style.setProperty("max-height", "none", "important");
      el.style.setProperty("flex", "0 0 auto", "important");
      if (sh > 0) el.style.setProperty("min-height", `${sh}px`, "important");
    }
    document.documentElement.style.setProperty("height", "auto", "important");
    document.body.style.setProperty("height", "auto", "important");
    document.body.style.setProperty("overflow", "visible", "important");
  });
  await settle(300);
}

async function captureScreen(page, screen, suffix = "") {
  const file = `${screen.id}${suffix ? `__${suffix}` : ""}.png`;
  const out = path.join(shotDir, file);
  let elements = null;
  try {
    elements = await inventoryElements(page);
  } catch {
    elements = null;
  }

  const before = await measureScrollLayout(page);
  await unlockViewportLayout(page);

  // After unlock, grow viewport to content height (capped) then fullPage shot.
  const after = await page.evaluate(() => ({
    dh: Math.max(
      document.documentElement.scrollHeight,
      document.body.scrollHeight,
      document.documentElement.offsetHeight,
      document.body.offsetHeight,
    ),
    dw: Math.max(document.documentElement.scrollWidth, document.body.scrollWidth, 1440),
    vh: window.innerHeight,
    vw: window.innerWidth,
  }));

  const targetH = Math.min(
    Math.max(after.dh, before.primary?.scrollHeight || 0, before.vh),
    16000,
  );
  const targetW = Math.min(Math.max(after.dw, before.vw), 2400);

  // Resize viewport so clipped nested content is in-frame even if doc still clamps.
  if (targetH > before.vh + 20) {
    await page.setViewportSize({ width: Math.round(targetW), height: Math.round(targetH) });
    await settle(200);
    // Re-apply unlock after resize (some flex recalcs clamp again).
    await unlockViewportLayout(page);
  }

  await page.screenshot({ path: out, fullPage: true });

  // Restore default viewport for next screen in this context.
  await page.setViewportSize({ width: 1440, height: 900 });

  const finalDim = await page.evaluate(() => ({
    // read file size is external; store intended target
  }));
  void finalDim;

  return {
    screenId: screen.id,
    title: screen.title,
    path: screen.path,
    auth: screen.auth,
    variant: suffix || null,
    file: `screenshots/${file}`,
    capturedAt: new Date().toISOString(),
    url: page.url(),
    elements,
    captureMetrics: {
      before,
      after,
      targetH,
      targetW,
    },
  };
}

async function prepareForScreen(page, screen, hasAuth) {
  if (screen.auth === "signed-in" && !hasAuth) return { skip: true, reason: "no-auth-state" };

  await page.goto(`${baseUrl}${screen.path}`, { waitUntil: "domcontentloaded", timeout: 60000 });
  await settle(900);
  await waitForApp(page);

  if (screen.action === "click-new-build") {
    await safeClick(page, ['aside button:text-is("New")', 'aside button:has-text("New")', 'button:has-text("Create build")'], 4000);
    await settle(800);
  }
  if (screen.requires === "selected-build") {
    await clickFirstLibraryRow(page);
    await page.locator('main button:has-text("Edit")').first().waitFor({ state: "visible", timeout: 10000 }).catch(() => {});
  }
  if (screen.requires === "selected-build-edit") {
    const ok = await openBuildEditComposer(page);
    if (!ok) console.warn("[atlas] could not open build edit composer for", screen.id);
  }
  if (screen.tab) {
    await clickComposerTab(page, screen.tab);
    await settle(600);
  }
  if (screen.subPath === "create") {
    await safeClick(page, ['main button:text-is("Create")', 'main button:has-text("Create")'], 3000);
    await settle(500);
  }
  if (screen.subPath === "reuse") {
    await safeClick(page, ['main button:text-is("Reuse")', 'main button:has-text("Reuse")'], 3000);
    await settle(500);
  }
  if (screen.requires === "selected-set" || screen.requires === "selected-synergy") {
    await clickFirstLibraryRow(page);
    await page.locator('main button:has-text("Edit")').first().waitFor({ state: "visible", timeout: 10000 }).catch(() => {});
  }
  if (screen.action === "click-new-set" || screen.action === "click-new-synergy") {
    await safeClick(page, ['aside button:text-is("New")', 'main button:has-text("New set")', 'aside button:has-text("New")'], 4000);
    await settle(700);
  }
if (screen.actionExtra === "open-improve-kit") {
    let opened = await safeClick(page, ['main button:has-text("Improve kit")', 'main button:has-text("Improve")'], 2500);
    if (!opened) {
      await safeClick(page, ['main button:has-text("Attach")'], 2500);
      await settle(800);
      opened = await safeClick(page, ['main button:has-text("Improve kit")', 'main button:has-text("Improve")'], 2500);
    }
    if (!opened) console.warn("[atlas] Improve kit not available for", screen.id);
    await settle(900);
  }

  // Catalog kind / scope toggles (FilterChips)
if (screen.catalogKind || screen.catalogScope || String(screen.actionExtra || "").startsWith("catalog")) {
    // Catalog fetches can take a few seconds after navigation / kind change.
    await page.locator('text=Loading catalog').first().waitFor({ state: "hidden", timeout: 20000 }).catch(() => {});
  }
  if (screen.catalogKind) {
    const kindLabel =
      screen.catalogKind === "weapons"
        ? "Weapons"
        : screen.catalogKind === "armor"
          ? "Armor"
          : screen.catalogKind === "universal"
            ? "Universal"
            : screen.catalogKind;
    await safeClick(page, [
      `main button:text-is("${kindLabel}")`,
      `main button:has-text("${kindLabel}")`,
    ], 4000);
    await settle(700);
    await page.locator('text=Loading catalog').first().waitFor({ state: "hidden", timeout: 20000 }).catch(() => {});
    await waitForApp(page);
  }
  if (screen.catalogScope === "owned") {
    await safeClick(page, ['main button:text-is("Owned")', 'main button:has-text("Owned")'], 3000);
    await settle(600);
    await page.locator('text=Loading catalog').first().waitFor({ state: "hidden", timeout: 20000 }).catch(() => {});
    await waitForApp(page);
  }
  if (screen.catalogScope === "all") {
    await safeClick(page, ['main button:text-is("Manifest")', 'main button:has-text("Manifest")'], 3000);
    await settle(600);
    await page.locator('text=Loading catalog').first().waitFor({ state: "hidden", timeout: 20000 }).catch(() => {});
    await waitForApp(page);
  }
  if (screen.actionExtra === "catalog-open-filters") {
    await safeClick(page, [
      'main button:has-text("Filters")',
      'main button:has-text("▸ Filters")',
      'main button:has-text("▾ Filters")',
    ], 3000);
    await settle(500);
  }
  if (screen.actionExtra === "catalog-select-first") {
    await page.locator('text=Results').first().waitFor({ state: "visible", timeout: 15000 }).catch(() => {});
    await page.locator('text=Loading catalog').first().waitFor({ state: "hidden", timeout: 20000 }).catch(() => {});
    await settle(1000);
    // Result cards are full-width buttons with title=item name inside the Results aside.
    const card = page.locator('aside button[title], aside button.w-full, main aside button').first();
    try {
      if ((await card.count()) > 0) {
        await card.click({ timeout: 5000 });
      } else {
        await safeClick(page, ['main button:has(img)'], 4000);
      }
    } catch {
      console.warn("[atlas] catalog select first failed for", screen.id);
    }
    await settle(1000);
    await page.locator('text=← Results').first().waitFor({ state: "visible", timeout: 10000 }).catch(() => {});
  }

  if (screen.actionExtra === "sets-edit") {
    await safeClick(page, ['main button:text-is("Edit")', 'main button:has-text("Edit")'], 4000);
    await settle(700);
  }
  if (screen.actionExtra === "sets-fill-slot") {
    const filled = await safeClick(page, [
      'main button:has-text("Fill next")',
      'main button:text-is("Fill")',
      'main button:has-text("Fill")',
      'main button:has-text("Add mod")',
    ], 4000);
    if (!filled) console.warn("[atlas] sets fill slot control not found for", screen.id);
    await settle(1000);
    await page
      .locator('main button:has-text("Weapons"), main button:has-text("Armor"), main :text("Catalog")')
      .first()
      .waitFor({ state: "visible", timeout: 10000 })
      .catch(() => {});
  }

  if (screen.actionExtra === "loadouts-expand-first") {
    // Expand first bungie loadout row if collapsed
    await safeClick(page, [
      'main button:has-text("Expand")',
      'main button:has-text("Show")',
      'main button[aria-expanded="false"]',
    ], 3000);
    // Many rows toggle via the whole header button
    if (!(await page.locator('main :text("Kinetic"), main :text("Helmet")').count())) {
      await safeClick(page, ['main .overflow-hidden button', 'main article button', 'main button'], 3000);
    }
    await settle(800);
  }

  return { skip: false };
}

async function main() {
  let browser;
  try {
    browser = await chromium.launch({ headless: true });
  } catch (e) {
    console.error("Playwright chromium missing. Run: npm i -D playwright && npx playwright install chromium\n", e.message);
    process.exit(1);
  }

  const observations = [];
  const hasAuth = Boolean(storageState && fs.existsSync(path.resolve(root, storageState)));
  const contexts = [];

  const clean = await browser.newContext({
    viewport: { width: 1440, height: 900 },
    ignoreHTTPSErrors: true,
  });
  contexts.push({ name: "clean", ctx: clean, auth: false });

  if (hasAuth && !skipSignedIn) {
    const authed = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      storageState: path.resolve(root, storageState),
      ignoreHTTPSErrors: true,
    });
    contexts.push({ name: "authed", ctx: authed, auth: true });
  } else if (!hasAuth) {
    console.warn("[atlas] No ATLAS_STORAGE_STATE — signed-in screens skipped. Use npm run atlas:auth");
  }

  for (const screen of manifest.screens) {
    if (only && !only.has(screen.id)) continue;
    for (const c of contexts) {
      if (screen.auth === "signed-in" && !c.auth) continue;
      if (screen.auth === "signed-out" && c.auth) continue;
      if (screen.auth === "any" && c.auth && contexts.some((x) => !x.auth)) continue;

      const page = await c.ctx.newPage();
      try {
        const prep = await prepareForScreen(page, screen, c.auth);
        if (prep.skip) {
          observations.push({ screenId: screen.id, skipped: true, reason: prep.reason });
          continue;
        }
        const obs = await captureScreen(
          page,
          screen,
          c.auth ? "signed-in" : screen.auth === "signed-out" ? "signed-out" : "anon",
        );
        observations.push(obs);
        console.log("✓", obs.file);
      } catch (err) {
        observations.push({ screenId: screen.id, error: String(err?.message || err), context: c.name });
        console.warn("✗", screen.id, err?.message || err);
      } finally {
        await page.close();
      }
    }
  }

  let merged = observations;
  if (only && fs.existsSync(obsPath)) {
    try {
      const prev = JSON.parse(fs.readFileSync(obsPath, "utf8"));
      const prevList = Array.isArray(prev.observations) ? prev.observations : [];
      const keyOf = (o) => `${o.screenId}::${o.variant || o.context || ""}`;
      const map = new Map();
      for (const o of prevList) if (o.screenId) map.set(keyOf(o), o);
      for (const o of observations) if (o.screenId) map.set(keyOf(o), o);
      merged = [...map.values()];
      console.log(`[atlas] merged ATLAS_ONLY into prior observations (${merged.length} rows)`);
    } catch {
      merged = observations;
    }
  }

  const totals = { button: 0, link: 0, input: 0, tab: 0, listItem: 0, icon: 0, dialog: 0 };
  for (const o of merged) {
    const br = o.elements?.byRole;
    if (!br) continue;
    for (const k of Object.keys(totals)) totals[k] += br[k] || 0;
  }

  const report = {
    baseUrl,
    capturedAt: new Date().toISOString(),
    hasAuth,
    observationCount: merged.filter((o) => o.file).length,
    elementTotals: totals,
    skipped: merged.filter((o) => o.skipped).length,
    errors: merged.filter((o) => o.error).length,
    observations: merged,
  };
  fs.writeFileSync(obsPath, JSON.stringify(report, null, 2));
  console.log("\nWrote docs/atlas/observations.json");
  console.log(`Captured ${report.observationCount} screenshots (${report.skipped} skipped, ${report.errors} errors)`);
  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
