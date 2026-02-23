import fs from "node:fs";
import path from "node:path";
import type { ChartSpec } from "./index";
import { compareVersions, parseSpecVersion } from "./versioning";

function usage(): never {
  console.error("Usage: pnpm spec:compat <baseline.json> <candidate.json>");
  process.exit(1);
}

const [baselineArg, candidateArg] = process.argv.slice(2);
if (!baselineArg || !candidateArg) usage();

const baselinePath = path.resolve(baselineArg);
const candidatePath = path.resolve(candidateArg);

const baseline = JSON.parse(fs.readFileSync(baselinePath, "utf-8")) as ChartSpec;
const candidate = JSON.parse(fs.readFileSync(candidatePath, "utf-8")) as ChartSpec;

const baseVersion = parseSpecVersion(baseline.specVersion);
const candVersion = parseSpecVersion(candidate.specVersion);

if (baseVersion.major !== candVersion.major) {
  console.error(
    `INCOMPATIBLE: Major version changed ${baseline.specVersion} -> ${candidate.specVersion}`
  );
  process.exit(1);
}

if (compareVersions(candidate.specVersion, baseline.specVersion) < 0) {
  console.error(
    `INCOMPATIBLE: Candidate version is older than baseline (${candidate.specVersion} < ${baseline.specVersion})`
  );
  process.exit(1);
}

console.log(`COMPATIBLE: ${baseline.specVersion} -> ${candidate.specVersion}`);
