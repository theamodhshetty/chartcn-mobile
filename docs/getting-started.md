# Getting Started

## Prerequisites

- Node 20+
- pnpm 9+
- Xcode 15+ (for iOS package tests)
- Android Studio + JDK 17 (for Android package development)

## 1. Install and validate

```bash
pnpm install
pnpm build
```

## 2. Pick a chart recipe

Example:

```bash
pnpm spec:resolve registry/dashboards/kpi-revenue-trend.chart.json --output ./revenue.chart.json
```

## 3. iOS integration

```swift
let spec = try ChartSpecLoader.load(from: data)
let rows: [ChartRow] = ...
let view = ChartCNView(spec: spec, rows: rows)
```

For SwiftData-backed rows, use `SwiftDataAdapter` with a `ChartSwiftDataMappable` model.

## 4. Android integration

```kotlin
val spec = ChartSpecParser.parse(rawSpec)
val rows: List<ChartRow> = ...
ChartCNView(spec = spec, rows = rows)
```

For Room-backed rows, use `RoomAdapter.fetchRows(...)`.

## 5. Install spec package in another project

From npm (after publish):

```bash
npm install @chartcn/spec
```

From release artifact:

```bash
npm install https://github.com/theamodhshetty/chartcn-mobile/releases/latest/download/chartcn-spec-latest.tgz
```

## 6. Spec lifecycle operations

- Validate: `pnpm spec:validate <file>`
- Migrate: `pnpm spec:migrate <file> --in-place`
- Compat: `pnpm spec:compat <baseline> <candidate>`

## 7. CI expectations

- Spec/type checks run on Ubuntu
- Swift tests run on macOS
- Android tests run on Ubuntu with Gradle
