import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

function usage() {
  console.error("Usage: pnpm chartcn:init");
  process.exit(1);
}

function isDirectoryEmpty(dir) {
  return fs.readdirSync(dir).length === 0;
}

function copyRecursive(source, destination) {
  const stat = fs.statSync(source);
  if (stat.isDirectory()) {
    fs.mkdirSync(destination, { recursive: true });
    for (const entry of fs.readdirSync(source)) {
      const from = path.join(source, entry);
      const to = path.join(destination, entry);
      copyRecursive(from, to);
    }
    return;
  }

  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.copyFileSync(source, destination);
}

if (process.argv.length > 2) {
  usage();
}

const outputDir = path.resolve(process.cwd(), "chartcn-starter");
const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "..", "..", "..");
const starterSource = path.resolve(repoRoot, "starter");

if (!fs.existsSync(starterSource)) {
  console.error(`Starter source not found: ${starterSource}`);
  process.exit(1);
}

if (fs.existsSync(outputDir) && !isDirectoryEmpty(outputDir)) {
  console.error(`Output directory is not empty: ${outputDir}`);
  console.error("Delete ./chartcn-starter and rerun pnpm chartcn:init.");
  process.exit(1);
}

copyRecursive(starterSource, outputDir);

const screenshotPath = path.join(outputDir, "screenshots", "chartcn-starter-preview.svg");

console.log("chartcn starter created.");
console.log(`Output: ${outputDir}`);
console.log("");
console.log("User: mobile teams using SwiftUI + Compose dashboards.");
console.log("Promise: Ship production charts from ChartSpec in under few minutes.");
console.log("");
console.log("Templates:");
console.log("- kpi-card");
console.log("- trend-line");
console.log("- comparison-bar");
console.log("");
console.log(`Example spec: ${path.join(outputDir, "templates", "kpi-card", "chartspec.json")}`);
console.log(`Screenshot output: ${screenshotPath}`);
