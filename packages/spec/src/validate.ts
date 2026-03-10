import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import type { ChartSpec } from "./index";
import { validateAgainstSchema } from "./schema-validator";
import { validateSemantics } from "./semantics";
import { assertRuntimeCompatible } from "./versioning";

const here = path.dirname(fileURLToPath(import.meta.url));
const defaultExamplesPath = path.resolve(here, "..", "examples");

function gatherJsonFiles(dir: string): string[] {
  const out: string[] = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...gatherJsonFiles(full));
    if (entry.isFile() && entry.name.endsWith(".json")) out.push(full);
  }
  return out;
}

function expandInput(input: string): string[] {
  const resolved = path.resolve(input);
  if (!fs.existsSync(resolved)) {
    throw new Error(`Input does not exist: ${input}`);
  }

  const stats = fs.statSync(resolved);
  if (stats.isDirectory()) {
    return gatherJsonFiles(resolved);
  }

  return [resolved];
}

const inputs = process.argv.slice(2);
const files = inputs.length > 0
  ? inputs.flatMap(expandInput)
  : gatherJsonFiles(defaultExamplesPath);

if (files.length === 0) {
  console.error("No JSON files provided or found.");
  process.exit(1);
}

let hasErrors = false;

for (const file of files) {
  const value = JSON.parse(fs.readFileSync(file, "utf-8"));

  const schemaErrors = validateAgainstSchema(value);

  if (schemaErrors.length > 0) {
    hasErrors = true;
    console.error(`INVALID (schema): ${file}`);
    for (const err of schemaErrors) {
      console.error(`  - ${err}`);
    }
    continue;
  }

  const spec = value as ChartSpec;

  try {
    assertRuntimeCompatible(spec.specVersion);
  } catch (error) {
    hasErrors = true;
    console.error(`INVALID (version): ${file}`);
    console.error(`  - ${(error as Error).message}`);
    continue;
  }

  const semanticErrors = validateSemantics(spec);
  if (semanticErrors.length > 0) {
    hasErrors = true;
    console.error(`INVALID (semantics): ${file}`);
    for (const err of semanticErrors) {
      console.error(`  - ${err}`);
    }
    continue;
  }

  console.log(`VALID: ${file}`);
}

if (hasErrors) process.exit(1);
