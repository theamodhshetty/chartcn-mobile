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
3. Set `@chartcn/spec` package version from tag.
4. Publish `@chartcn/spec` to npm if `NPM_TOKEN` secret is configured.
5. Pack `@chartcn/spec` tarball.
6. Upload artifact and create GitHub release.

## npm Publishing

- Required secret: `NPM_TOKEN` (Automation token with publish permission).
- Fallback secret supported: `NPM_TOKEN1` (used when `NPM_TOKEN` is empty).
- Package name: `@amodh/chartcn-spec` (set via repo variable).
- Optional repo variable: `NPM_PACKAGE_NAME` to override package name at release time (useful if publishing under a different scope).
- Publish command: `npm publish --provenance --access public`.
- If `NPM_TOKEN` is missing, workflow skips npm publish and still ships the GitHub release artifact.

## Security Gates

`Security` workflow enforces:

1. `pnpm audit --audit-level=high`
2. secret scanning via gitleaks

## Required Human Checks

Before tagging:

1. Migration notes updated for spec changes.
2. Compatibility validated via `pnpm spec:compat` where relevant.
3. Updated changelog/release notes include breaking changes and migration path.
4. Confirm npm scope ownership and token validity (for npm publish path).
