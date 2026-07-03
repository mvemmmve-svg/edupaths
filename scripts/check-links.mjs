// scripts/check-links.mjs — R3 automated link checking (missing from the
// previous update). Framework-agnostic: extracts every http(s) URL from the
// data layer (adjust GLOBS for where the Flutter app keeps seed data — Dart
// files, JSON assets, or export the Supabase catalogue table to
// data/catalogue.json in CI first), HEAD/GETs each with a timeout, fails the
// build on >=400 or schemeless URLs.
//
// Run:  node scripts/check-links.mjs
// CI:   wire into GitHub Actions per-PR AND on a weekly schedule — external
//       links rot independently of code changes (spec R3).

import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, extname } from "node:path";

const ROOTS = ["lib", "assets", "data"];
const EXTS = new Set([".dart", ".json", ".yaml", ".csv"]);
const IGNORE = new Set([
  // reviewed ignore-list for sites that block bots (spec R3)
]);
const TIMEOUT_MS = 10000;

function* walk(dir) {
  let entries = [];
  try { entries = readdirSync(dir); } catch { return; }
  for (const e of entries) {
    const p = join(dir, e);
    if (statSync(p).isDirectory()) yield* walk(p);
    else if (EXTS.has(extname(p))) yield p;
  }
}

const urls = new Set();
const schemeless = new Set();
for (const root of ROOTS) {
  for (const file of walk(root)) {
    const text = readFileSync(file, "utf8");
    for (const m of text.matchAll(/https?:\/\/[^\s"'`<>\\)]+/g)) urls.add(m[0]);
    // Flag url-ish field values missing a scheme (the www.ox.ac.uk bug)
    for (const m of text.matchAll(/["'](www\.[^\s"'`]+)["']/g)) schemeless.add(`${m[1]} (${file})`);
  }
}

async function check(url) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try {
    let res = await fetch(url, { method: "HEAD", redirect: "follow", signal: ctrl.signal });
    if (res.status === 405 || res.status === 403) {
      res = await fetch(url, { method: "GET", redirect: "follow", signal: ctrl.signal });
    }
    return { url, status: res.status, ok: res.status < 400 };
  } catch (e) {
    return { url, status: 0, ok: false, err: String(e) };
  } finally {
    clearTimeout(t);
  }
}

const targets = [...urls].filter((u) => ![...IGNORE].some((i) => u.startsWith(i)));
console.log(`Checking ${targets.length} URLs…`);
const results = await Promise.all(targets.map(check));
const failures = results.filter((r) => !r.ok);

for (const r of results) console.log(`${r.ok ? "OK " : "FAIL"} ${r.status || "ERR"} ${r.url}`);
if (schemeless.size) {
  console.error(`\nSchemeless URL values (will 404 as relative links):`);
  for (const s of schemeless) console.error(`  ${s}`);
}
if (failures.length || schemeless.size) {
  console.error(`\n${failures.length} broken, ${schemeless.size} schemeless — failing.`);
  process.exit(1);
}
console.log("\nAll links pass.");
