# Performance Benchmarking

`chartcn-mobile` includes a benchmark harness for core `ChartSpec` operations so maintainers can track runtime cost over time.

## Command

```bash
pnpm spec:bench -- --iterations 200 --warmup 20 --rows 1000 --json artifacts/spec-benchmark.json
```

Supported flags:

- `--iterations <n>`: measured loop count per benchmark case.
- `--warmup <n>`: warmup loop count before measurement starts.
- `--rows <n>`: row count for the synthetic static dataset benchmark.
- `--json <file>`: writes machine-readable benchmark report.

## Cases Covered

1. Validate an example spec (schema + semantics).
2. Validate a large static-row spec.
3. Migrate `1.0.0 -> 1.1.0`.
4. Run compatibility gate logic.
5. Run full pipeline (`migrate + validate`).

## CI Integration

The `CI` workflow runs a lightweight benchmark profile on every PR and push to `main`, then uploads `spec-benchmark.json` as an artifact.

Use artifact history to compare trends between commits. Keep comparisons directional, not absolute, because GitHub runner noise can shift raw timings.
