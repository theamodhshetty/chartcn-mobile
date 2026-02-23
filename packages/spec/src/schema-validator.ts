import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import type { ErrorObject } from "ajv";

const here = path.dirname(fileURLToPath(import.meta.url));
const schemaPath = path.resolve(here, "..", "schema", "chart-spec.schema.json");
const schema = JSON.parse(fs.readFileSync(schemaPath, "utf-8"));

const ajv = new Ajv2020({ allErrors: true, strict: false });
addFormats(ajv);
const validateFn = ajv.compile(schema);

export function validateAgainstSchema(value: unknown): string[] {
  const valid = validateFn(value);
  if (valid) return [];

  return ((validateFn.errors ?? []) as ErrorObject[]).map(err => {
    const pointer = err.instancePath || "/";
    return `${pointer} ${err.message}`;
  });
}

export function getChartSpecSchemaPath(): string {
  return schemaPath;
}
