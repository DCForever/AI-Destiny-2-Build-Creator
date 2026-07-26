/**
 * Interactive helper: open browser, sign in, save Playwright storage to .atlas/auth.json
 */
import { chromium } from "playwright";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const outDir = path.join(root, ".atlas");
const out = path.join(outDir, "auth.json");
const base = (process.env.ATLAS_BASE_URL || "https://127.0.0.1:3000").replace(/\/$/, "");

fs.mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch({ headless: false });
const context = await browser.newContext({ ignoreHTTPSErrors: true });
const page = await context.newPage();
await page.goto(base, { waitUntil: "domcontentloaded" });

console.log("Sign in with Bungie in the opened browser.");
console.log("When the app shows Signed in, return here and press Enter.");
await new Promise((resolve) => {
  process.stdin.resume();
  process.stdin.once("data", resolve);
});

await context.storageState({ path: out });
console.log("Wrote", out);
await browser.close();
process.exit(0);
