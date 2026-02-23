# ChartSpec Guide

`ChartSpec` is a declarative, versioned format for cross-platform mobile charts.

Current canonical version: `1.1.0`

Core sections:

1. `metadata`: identity, lifecycle, owners.
2. `data`: source adapter, dimensions/measures, transforms.
3. `visual`: chart type, series, axes, legend, tooltip.
4. `accessibility`: chart title and spoken summary template.
5. `platformOverrides`: optional renderer-level tuning.

For exact fields, see:

- `packages/spec/schema/chart-spec.schema.json`
- `packages/spec/src/index.ts`
- `docs/versioning.md`
