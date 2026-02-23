import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import type { ChartSpec } from "./index";
import { CURRENT_SPEC_VERSION } from "./constants";
import { migrateSpec } from "./migrations";
import { validateAgainstSchema } from "./schema-validator";
import { validateSemantics } from "./semantics";
import { compareVersions, parseSpecVersion } from "./versioning";

interface BenchmarkOptions {
  iterations: number;
  warmup: number;
  rows: number;
  jsonOutput?: string;
}

interface BenchmarkResult {
  name: string;
  samples: number;
  meanMs: number;
  p50Ms: number;
  p95Ms: number;
  minMs: number;
  maxMs: number;
  opsPerSecond: number;
}

interface BenchmarkReport {
  generatedAt: string;
  nodeVersion: string;
  options: BenchmarkOptions;
  results: BenchmarkResult[];
}

const here = path.dirname(fileURLToPath(import.meta.url));
const exampleSpecPath = path.resolve(here, "..", "examples", "revenue-trend.chart.json");

function usage(): never {
  console.error(
    "Usage: pnpm spec:bench [--iterations <number>] [--warmup <number>] [--rows <number>] [--json <file>]"
  );
  process.exit(1);
}

function parseArgs(argv: string[]): BenchmarkOptions {
  const options: BenchmarkOptions = {
    iterations: 200,
    warmup: 20,
    rows: 1000
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === "--") {
      continue;
    }

    if (token === "--iterations") {
      const value = Number(argv[i + 1]);
      if (!Number.isInteger(value) || value <= 0) usage();
      options.iterations = value;
      i += 1;
      continue;
    }

    if (token === "--warmup") {
      const value = Number(argv[i + 1]);
      if (!Number.isInteger(value) || value < 0) usage();
      options.warmup = value;
      i += 1;
      continue;
    }

    if (token === "--rows") {
      const value = Number(argv[i + 1]);
      if (!Number.isInteger(value) || value <= 0) usage();
      options.rows = value;
      i += 1;
      continue;
    }

    if (token === "--json") {
      const value = argv[i + 1];
      if (!value) usage();
      options.jsonOutput = path.resolve(value);
      i += 1;
      continue;
    }

    usage();
  }

  return options;
}

function loadExampleSpec(): ChartSpec {
  return JSON.parse(fs.readFileSync(exampleSpecPath, "utf-8")) as ChartSpec;
}

function createLargeStaticSpec(rows: number): ChartSpec {
  const staticRows = Array.from({ length: rows }, (_, index) => {
    return {
      bucket: `2026-01-${String((index % 28) + 1).padStart(2, "0")}`,
      value: (index % 500) + (index % 11)
    };
  });

  return {
    specVersion: CURRENT_SPEC_VERSION,
    id: "benchmark-large-static",
    metadata: {
      name: "Benchmark Large Static",
      status: "stable",
      owners: ["bench"],
      tags: ["bench"]
    },
    data: {
      source: {
        adapter: "static",
        rows: staticRows
      },
      dimensions: [
        {
          key: "bucket",
          type: "time",
          label: "Bucket"
        }
      ],
      measures: [
        {
          key: "value",
          type: "number",
          label: "Value"
        }
      ],
      transforms: [
        {
          type: "movingAverage",
          input: "value",
          window: 7,
          as: "value_ma7"
        }
      ]
    },
    visual: {
      chartType: "line",
      xField: "bucket",
      series: [
        {
          field: "value",
          label: "Value"
        },
        {
          field: "value_ma7",
          label: "MA7"
        }
      ]
    },
    accessibility: {
      chartTitle: "Benchmark chart",
      summaryTemplate: "A line chart with benchmark values",
      announceOnLoad: true
    }
  };
}

function createLegacySpec(base: ChartSpec): ChartSpec {
  return {
    ...base,
    specVersion: "1.0.0",
    metadata: {
      ...base.metadata
    },
    visual: {
      ...base.visual
    },
    accessibility: {
      ...base.accessibility
    }
  };
}

function strip1_1Fields(spec: ChartSpec): ChartSpec {
  const next = createLegacySpec(spec);
  delete next.metadata.tags;
  delete next.visual.xField;
  delete next.visual.tooltip;
  delete next.accessibility.announceOnLoad;
  return next;
}

function validateSpec(spec: ChartSpec): void {
  const schemaErrors = validateAgainstSchema(spec);
  if (schemaErrors.length > 0) {
    throw new Error(`Schema validation failed: ${schemaErrors[0]}`);
  }

  const semanticErrors = validateSemantics(spec);
  if (semanticErrors.length > 0) {
    throw new Error(`Semantic validation failed: ${semanticErrors[0]}`);
  }
}

function assertCompatible(baseline: ChartSpec, candidate: ChartSpec): void {
  const baselineVersion = parseSpecVersion(baseline.specVersion);
  const candidateVersion = parseSpecVersion(candidate.specVersion);

  if (baselineVersion.major !== candidateVersion.major) {
    throw new Error("Compatibility failed: major version mismatch.");
  }

  if (compareVersions(candidate.specVersion, baseline.specVersion) < 0) {
    throw new Error("Compatibility failed: candidate version is older than baseline.");
  }
}

function percentile(values: number[], p: number): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.floor((sorted.length - 1) * p));
  return sorted[index];
}

function round(value: number): number {
  return Math.round(value * 1000) / 1000;
}

function benchmarkCase(
  name: string,
  run: () => void,
  options: BenchmarkOptions
): BenchmarkResult {
  for (let i = 0; i < options.warmup; i += 1) {
    run();
  }

  const samplesMs: number[] = [];
  for (let i = 0; i < options.iterations; i += 1) {
    const start = process.hrtime.bigint();
    run();
    const elapsedNs = Number(process.hrtime.bigint() - start);
    samplesMs.push(elapsedNs / 1_000_000);
  }

  const totalMs = samplesMs.reduce((acc, value) => acc + value, 0);
  const meanMs = totalMs / samplesMs.length;
  const minMs = Math.min(...samplesMs);
  const maxMs = Math.max(...samplesMs);
  const p50Ms = percentile(samplesMs, 0.5);
  const p95Ms = percentile(samplesMs, 0.95);
  const opsPerSecond = meanMs === 0 ? 0 : 1000 / meanMs;

  return {
    name,
    samples: samplesMs.length,
    meanMs: round(meanMs),
    p50Ms: round(p50Ms),
    p95Ms: round(p95Ms),
    minMs: round(minMs),
    maxMs: round(maxMs),
    opsPerSecond: round(opsPerSecond)
  };
}

function printSummary(options: BenchmarkOptions, results: BenchmarkResult[]): void {
  console.log("ChartCN spec benchmark");
  console.log(
    `config: iterations=${options.iterations}, warmup=${options.warmup}, rows=${options.rows}`
  );
  console.log("");

  const columns = ["Case", "mean(ms)", "p50(ms)", "p95(ms)", "ops/s"];
  const rows = results.map(result => [
    result.name,
    result.meanMs.toFixed(3),
    result.p50Ms.toFixed(3),
    result.p95Ms.toFixed(3),
    result.opsPerSecond.toFixed(3)
  ]);

  const widths = columns.map((header, index) => {
    return Math.max(header.length, ...rows.map(row => row[index].length));
  });

  const line = (parts: string[]): string => {
    return parts.map((part, index) => part.padEnd(widths[index], " ")).join("  ");
  };

  console.log(line(columns));
  console.log(line(widths.map(width => "-".repeat(width))));
  for (const row of rows) {
    console.log(line(row));
  }
}

function writeJsonReport(options: BenchmarkOptions, results: BenchmarkResult[]): void {
  if (!options.jsonOutput) return;

  const report: BenchmarkReport = {
    generatedAt: new Date().toISOString(),
    nodeVersion: process.version,
    options,
    results
  };

  fs.mkdirSync(path.dirname(options.jsonOutput), { recursive: true });
  fs.writeFileSync(options.jsonOutput, `${JSON.stringify(report, null, 2)}\n`, "utf-8");
  console.log("");
  console.log(`JSON report: ${options.jsonOutput}`);
}

function main(): void {
  const options = parseArgs(process.argv.slice(2));
  const exampleSpec = loadExampleSpec();
  const largeStaticSpec = createLargeStaticSpec(options.rows);
  const legacySpec = strip1_1Fields(exampleSpec);
  const migratedSpec = migrateSpec(legacySpec, CURRENT_SPEC_VERSION);

  const results: BenchmarkResult[] = [
    benchmarkCase("validate: example", () => validateSpec(exampleSpec), options),
    benchmarkCase("validate: static-rows", () => validateSpec(largeStaticSpec), options),
    benchmarkCase("migrate: 1.0->1.1", () => {
      migrateSpec(legacySpec, CURRENT_SPEC_VERSION);
    }, options),
    benchmarkCase("compat: gate", () => assertCompatible(legacySpec, migratedSpec), options),
    benchmarkCase("pipeline: migrate+validate", () => {
      const migrated = migrateSpec(legacySpec, CURRENT_SPEC_VERSION);
      validateSpec(migrated);
    }, options)
  ];

  printSummary(options, results);
  writeJsonReport(options, results);
}

main();
