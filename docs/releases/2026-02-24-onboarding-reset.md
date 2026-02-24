# Release Notes: Onboarding Reset (2026-02-24)

## Summary

ChartCN onboarding is now intentionally minimal for mobile teams using SwiftUI + Compose dashboards.

Promise: Ship production charts from ChartSpec in under few minutes.

## What Changed

- Added one-command setup: `pnpm chartcn:init`.
- Removed optional first-run choices (no prompts, no flags).
- Standardized first output to:
  - one example spec: `chartcn-starter/templates/kpi-card/chartspec.json`
  - one screenshot output: `chartcn-starter/screenshots/chartcn-starter-preview.svg`
- Reduced starter templates to exactly three must-haves:
  - `kpi-card`
  - `trend-line`
  - `comparison-bar`
- Included iOS + Android + sample data for each starter template.
- Updated starter registry to only these three entries.

## Install

```bash
npm install @chartcn/spec
```

## Quick Start

```bash
pnpm chartcn:init
```
