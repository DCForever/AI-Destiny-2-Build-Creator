import fs from "node:fs";

const p = "src/lib/manifest/manifestService.test.ts";
let s = fs.readFileSync(p, "utf8");
const needle = `  it("loadRawTable throws when the table file is missing", async () => {`;
const insert = `  it("loadRawTable memoizes parsed tables within a service instance", async () => {
    const table = RAW_TABLES[0];
    await writeTableFile(TABLE_VERSION, table, TABLE_FIXTURE);
    const service = new BungieManifestService({ apiKey: "test-api-key" });

    const a = await service.loadRawTable(TABLE_VERSION, table);
    const b = await service.loadRawTable(TABLE_VERSION, table);
    expect(a).toBe(b);
  });

  it("loadRawTable can disable memoization", async () => {
    const table = RAW_TABLES[0];
    await writeTableFile(TABLE_VERSION, table, TABLE_FIXTURE);
    const service = new BungieManifestService({
      apiKey: "test-api-key",
      cacheRawTables: false,
    });

    const a = await service.loadRawTable(TABLE_VERSION, table);
    const b = await service.loadRawTable(TABLE_VERSION, table);
    expect(a).toEqual(b);
    expect(a).not.toBe(b);
  });

` + needle;

if (s.includes("memoizes parsed tables")) {
  console.log("already present");
  process.exit(0);
}
if (!s.includes(needle)) {
  console.error("needle missing");
  process.exit(1);
}
s = s.replace(needle, insert);
fs.writeFileSync(p, s);
console.log("patched");
