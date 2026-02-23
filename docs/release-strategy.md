# Release Strategy

## Branch Model

- `main` is always releasable.
- Feature branches merge via PR.
- No direct pushes to `main` outside maintainers.

## Release Types

1. Patch: bug fixes and non-breaking improvements.
2. Minor: additive spec/runtime capabilities.
3. Major: breaking changes to `ChartSpec` or package APIs.

## Release Workflow

`Release` workflow runs on:

- `v*` git tags
- manual `workflow_dispatch`

Steps:

1. Install dependencies.
2. Run `pnpm spec:check`.
3. Pack `@chartcn/spec` tarball.
4. Upload artifact and create GitHub release.

## Security Gates

`Security` workflow enforces:

1. `pnpm audit --audit-level=high`
2. secret scanning via gitleaks

## Required Human Checks

Before tagging:

1. Migration notes updated for spec changes.
2. Compatibility validated via `pnpm spec:compat` where relevant.
3. Updated changelog/release notes include breaking changes and migration path.
