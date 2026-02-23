# Go-To-Market Playbook

## Objective

Drive adoption of `chartcn-mobile` and `@chartcn/spec` among mobile teams that repeatedly rebuild charts for iOS and Android.

## Audience

1. iOS engineers using SwiftUI + Swift Charts.
2. Android engineers using Compose.
3. Full-stack teams that maintain cross-platform mobile apps.
4. OSS maintainers building app templates/starter kits.

## Channels

1. GitHub release feed and watchers.
2. X (Twitter) launch post + follow-up threads.
3. LinkedIn engineering post.
4. Reddit (`r/androiddev`, `r/iOSProgramming`, `r/swift`, `r/Kotlin`).
5. Hacker News (`Show HN` with demo + rationale).
6. Dev.to / Hashnode engineering write-up.
7. Product Hunt (once examples and npm install are stable).

## Launch Checklist

1. Publish tagged release with changelog and downloadable artifact.
2. Ensure CI and security workflows are green on `main`.
3. Publish npm package (`@chartcn/spec`) using `NPM_TOKEN`.
4. Post release in all channels listed above.
5. Open "Launch feedback" GitHub Discussion.
6. Track 7-day metrics and collect onboarding blockers.

## Messaging Angles

1. "shadcn/ui-like DX for mobile chart reuse."
2. "Versioned ChartSpec shared between iOS and Android."
3. "Migration + compatibility tooling included from day one."
4. "Adapters for real app data sources (SwiftData, Room, API)."

## Post Templates

### X / Twitter

```text
Launched chartcn-mobile: reusable charts for iOS + Android with a versioned ChartSpec model.

- Shared chart definitions
- SwiftUI + Compose adapters
- Migration + compatibility tooling
- OSS + MIT

Repo: https://github.com/theamodhshetty/chartcn-mobile
Latest release: https://github.com/theamodhshetty/chartcn-mobile/releases/latest
```

### LinkedIn

```text
I just open-sourced chartcn-mobile, a reusable chart foundation for mobile apps.

It standardizes chart specs, data adapters, and accessibility defaults across SwiftUI and Jetpack Compose.

If your team keeps rebuilding KPI cards and trend charts per project, this is designed to reduce that repeated effort.

GitHub: https://github.com/theamodhshetty/chartcn-mobile
```

### Hacker News (Show HN)

```text
Show HN: chartcn-mobile – reusable chart specs for iOS and Android

I built an OSS project to avoid rewriting the same mobile charts in every app.
Core idea: keep chart definition declarative (JSON ChartSpec), then map to SwiftUI and Compose renderers.

Includes schema validation, migration tooling, and compatibility checks.

Repo: https://github.com/theamodhshetty/chartcn-mobile
```

### Reddit

```text
Open sourced: chartcn-mobile (SwiftUI + Compose chart reuse)

Built this to stop rewriting the same KPI/trend chart screens in every mobile app.
It uses a versioned ChartSpec model with validation/migration tooling and runtime adapters for iOS + Android.

Would love feedback on API shape and missing chart primitives.

Repo: https://github.com/theamodhshetty/chartcn-mobile
```

## 7-Day KPI Targets

1. 20+ GitHub stars.
2. 5+ external issues/feedback threads.
3. 3+ external PRs or implementation suggestions.
4. 100+ package downloads after npm publish.

## Feedback Capture

1. Label every onboarding issue as `first-run`.
2. Track top three setup blockers weekly.
3. Prioritize docs/examples if setup friction is high.
