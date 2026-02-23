# ChartSpec Versioning and Migration Rules

## Versioning Contract

`ChartSpec` follows semantic versioning with a fixed major line per runtime.

- `MAJOR`: breaking changes in spec structure or behavior.
- `MINOR`: additive changes with backward compatibility.
- `PATCH`: non-structural fixes, defaults, and documentation-level clarifications.

Current runtime-supported major: `1`
Current canonical version for new specs: `1.1.0`

## Compatibility Rules

1. Specs are runtime-compatible only when major versions match.
2. Candidate specs must not downgrade compared to baseline.
3. Breaking changes require a major bump and migration guidance.

Use:

```bash
pnpm spec:compat -- baseline.json candidate.json
```

## Migration Rules

The migration CLI upgrades older compatible specs to a target version.

Current built-in migration path:

- `1.0.x` -> `1.1.0`

Migration behavior:

1. Adds `metadata.tags` if absent.
2. Adds `accessibility.announceOnLoad` default (`true`) if absent.
3. Adds default `visual.tooltip.enabled` (`true`) if absent.
4. Backfills `visual.xField` from first dimension for x-axis chart types.

Use:

```bash
pnpm spec:migrate -- input.chart.json --in-place
```

or

```bash
pnpm spec:migrate -- input.chart.json --output output.chart.json --target 1.1.0
```
