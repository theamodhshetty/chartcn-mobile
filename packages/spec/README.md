# @chartcn/spec

Versioned `ChartSpec` model for cross-platform mobile chart definitions.

## Install

```bash
npm install @chartcn/spec
```

Fallback from GitHub release:

```bash
npm install https://github.com/theamodhshetty/chartcn-mobile/releases/latest/download/chartcn-spec-latest.tgz
```

## Contents

- `schema/chart-spec.schema.json`: canonical JSON Schema.
- `src/index.ts`: TypeScript model.
- `src/validate.ts`: schema validator for spec files.
- `src/migrate.ts`: migration CLI to upgrade specs to latest compatible version.
- `src/compat.ts`: compatibility check between two specs.
- `src/validate-registry.ts`: validates registry entries and resolved specs.
- `src/resolve-registry.ts`: resolves a registry item into a concrete spec JSON.
- `src/benchmark.ts`: benchmark harness for validation, migration, and compatibility flows.
- `dist/`: compiled package output used for npm releases.
- `examples/`: valid sample specs.

## Root Scripts

- `pnpm spec:validate`
- `pnpm spec:validate:registry`
- `pnpm spec:migrate -- <input.json> [--in-place] [--target 1.1.0]`
- `pnpm spec:compat -- <baseline.json> <candidate.json>`
- `pnpm spec:resolve -- <registry-item.json> [--output <resolved.json>]`
- `pnpm spec:bench -- --iterations 200 --rows 1000 [--json artifacts/spec-benchmark.json]`
- `pnpm spec:build`
