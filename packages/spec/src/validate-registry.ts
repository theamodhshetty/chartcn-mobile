import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { validateAgainstSchema } from "./schema-validator";
import { validateSemantics } from "./semantics";
import type { ChartSpec } from "./index";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..", "..", "..");
const registryDir = path.join(root, "registry");

function walkJson(dir: string): string[] {
  if (!fs.existsSync(dir)) return [];
  const out: string[] = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...walkJson(full));
    if (entry.isFile() && entry.name.endsWith(".json")) out.push(full);
  }
  return out;
}

const files = walkJson(registryDir);
if (files.length === 0) {
  console.log("No registry JSON files found. Skipping.");
  process.exit(0);
}

let hasErrors = false;

for (const file of files) {
  const raw = JSON.parse(fs.readFileSync(file, "utf-8"));

  if (typeof raw.extends !== "string") {
    hasErrors = true;
    console.error(`INVALID registry item: ${file}`);
    console.error("  - Missing 'extends' string path.");
    continue;
  }

  const target = path.resolve(path.dirname(file), raw.extends);
  if (!fs.existsSync(target)) {
    hasErrors = true;
    console.error(`INVALID registry item: ${file}`);
    console.error(`  - extends target does not exist: ${raw.extends}`);
    continue;
  }

  const targetSpec = JSON.parse(fs.readFileSync(target, "utf-8"));
  const schemaErrors = validateAgainstSchema(targetSpec);
  const semanticErrors = validateSemantics(targetSpec as ChartSpec);

  if (schemaErrors.length > 0 || semanticErrors.length > 0) {
    hasErrors = true;
    console.error(`INVALID registry target: ${target}`);
    for (const err of schemaErrors) console.error(`  - schema: ${err}`);
    for (const err of semanticErrors) console.error(`  - semantic: ${err}`);
    continue;
  }

  console.log(`VALID registry entry: ${file}`);
}

if (hasErrors) process.exit(1);
