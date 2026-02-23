# Contributing

## Setup

1. Install Node 20+ and pnpm.
2. Run `pnpm install`.
3. Validate specs with `pnpm spec:validate`.

## Contribution Flow

1. Open an issue (bug, feature, or RFC).
2. For changes to `ChartSpec`, include migration notes and backward compatibility impact.
3. Submit PR with tests or validation evidence.
4. Maintainer approval is required before merge.

## Commit Style

Use conventional commits:

- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation
- `chore:` tooling/maintenance

## Required for Spec Changes

- Update `packages/spec/schema/chart-spec.schema.json`.
- Update `packages/spec/src/index.ts`.
- Add or update examples under `packages/spec/examples`.
- Update `docs/chart-spec.md` if behavior changes.
