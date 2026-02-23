import fs from "node:fs";
import path from "node:path";
import { CURRENT_SPEC_VERSION } from "./constants";
import type { ChartSpec } from "./index";
import { migrateSpec } from "./migrations";
import { validateAgainstSchema } from "./schema-validator";
import { validateSemantics } from "./semantics";

function usage(): never {
  console.error("Usage: pnpm spec:migrate <input.json> [--output <output.json>] [--target <x.y.z>] [--in-place]");
  process.exit(1);
}

const argv = process.argv.slice(2);
if (argv.length === 0) usage();

const input = path.resolve(argv[0]);
if (!fs.existsSync(input)) {
  console.error(`Input file not found: ${input}`);
  process.exit(1);
}

let output: string | undefined;
let target: string = CURRENT_SPEC_VERSION;
let inPlace = false;

for (let i = 1; i < argv.length; i += 1) {
  const token = argv[i];
  if (token === "--output") {
    output = path.resolve(argv[i + 1] ?? "");
    i += 1;
    continue;
  }
  if (token === "--target") {
    target = argv[i + 1] ?? target;
    i += 1;
    continue;
  }
  if (token === "--in-place") {
    inPlace = true;
    continue;
  }
}

const spec = JSON.parse(fs.readFileSync(input, "utf-8")) as ChartSpec;
const migrated = migrateSpec(spec, target);

const schemaErrors = validateAgainstSchema(migrated);
const semanticErrors = validateSemantics(migrated);

if (schemaErrors.length > 0 || semanticErrors.length > 0) {
  console.error("Migration produced invalid spec.");
  for (const err of schemaErrors) console.error(`  - schema: ${err}`);
  for (const err of semanticErrors) console.error(`  - semantic: ${err}`);
  process.exit(1);
}

const destination = inPlace ? input : (output ?? path.resolve(process.cwd(), `${path.basename(input, ".json")}.migrated.json`));
fs.writeFileSync(destination, `${JSON.stringify(migrated, null, 2)}\n`, "utf-8");

console.log(`Migrated ${input}`);
console.log(`Output: ${destination}`);
console.log(`Version: ${spec.specVersion} -> ${migrated.specVersion}`);
