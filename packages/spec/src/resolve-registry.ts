import fs from "node:fs";
import path from "node:path";
import { validateAgainstSchema } from "./schema-validator";
import { validateSemantics } from "./semantics";
import type { ChartSpec } from "./index";

interface RegistryEntry {
  extends: string;
  registryMetadata?: Record<string, unknown>;
}

function usage(): never {
  console.error("Usage: pnpm spec:resolve <registry-item.json> [--output <resolved.json>]");
  process.exit(1);
}

const args = process.argv.slice(2);
if (args.length === 0) usage();

const registryFile = path.resolve(args[0]);
if (!fs.existsSync(registryFile)) {
  console.error(`Registry file not found: ${registryFile}`);
  process.exit(1);
}

let output: string | undefined;
for (let i = 1; i < args.length; i += 1) {
  if (args[i] === "--output") {
    output = path.resolve(args[i + 1] ?? "");
    i += 1;
  }
}

const registry = JSON.parse(fs.readFileSync(registryFile, "utf-8")) as RegistryEntry;
if (typeof registry.extends !== "string") {
  console.error("Registry entry must include 'extends' string.");
  process.exit(1);
}

const specPath = path.resolve(path.dirname(registryFile), registry.extends);
if (!fs.existsSync(specPath)) {
  console.error(`Referenced spec does not exist: ${registry.extends}`);
  process.exit(1);
}

const spec = JSON.parse(fs.readFileSync(specPath, "utf-8")) as ChartSpec;
const schemaErrors = validateAgainstSchema(spec);
const semanticErrors = validateSemantics(spec);

if (schemaErrors.length > 0 || semanticErrors.length > 0) {
  console.error("Resolved spec is invalid.");
  for (const err of schemaErrors) console.error(`  - schema: ${err}`);
  for (const err of semanticErrors) console.error(`  - semantic: ${err}`);
  process.exit(1);
}

const resolved = {
  ...spec,
  registry: {
    source: path.relative(process.cwd(), registryFile),
    metadata: registry.registryMetadata ?? {}
  }
};

const destination = output ?? path.resolve(process.cwd(), `${path.basename(registryFile, ".json")}.resolved.json`);
fs.writeFileSync(destination, `${JSON.stringify(resolved, null, 2)}\n`, "utf-8");

console.log(`Resolved registry entry: ${registryFile}`);
console.log(`Resolved spec: ${specPath}`);
console.log(`Output: ${destination}`);
