# Getting Started

## Exact User + Promise

- User: mobile teams using SwiftUI + Compose dashboards.
- Promise: Ship production charts from ChartSpec in under few minutes.

## One-Command Init

```bash
pnpm chartcn:init
```

Runs directly from repo source. No separate install step for first run.

No prompts. No flags. No first-run choices.

This generates:

- one example spec: `chartcn-starter/templates/kpi-card/chartspec.json`
- one screenshot output: `chartcn-starter/screenshots/chartcn-starter-preview.svg`
- only 3 templates, each with iOS + Android + sample data:
  - `kpi-card`
  - `trend-line`
  - `comparison-bar`

## Resolve A Template To A Concrete Spec

```bash
pnpm spec:resolve registry/dashboards/trend-line.chart.json --output ./my-chart.json
```

## iOS Integration

```swift
let spec = try ChartSpecLoader.load(from: data)
let rows: [ChartRow] = ...
let view = ChartCNView(spec: spec, rows: rows)
```

## Android Integration

```kotlin
val spec = ChartSpecParser.parse(rawSpec)
val rows: List<ChartRow> = ...
ChartCNView(spec = spec, rows = rows)
```

## Install Spec Package In Another Project

From npm:

```bash
npm install @chartcn/spec
```

From release artifact (if needed):

```bash
npm install https://github.com/theamodhshetty/chartcn-mobile/releases/latest/download/chartcn-spec-latest.tgz
```

## Spec Lifecycle Ops

- Validate: `pnpm spec:validate <file>`
- Migrate: `pnpm spec:migrate <file> --in-place`
- Compat: `pnpm spec:compat <baseline> <candidate>`
