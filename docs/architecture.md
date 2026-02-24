# Architecture

```text
ChartSpec JSON
    |
    +--> spec validator (schema + semantic checks)
    |
    +--> versioning + migration pipeline
    |      +--> compat gate
    |      +--> auto-migrate (1.0.x -> 1.1.0)
    |
    +--> data adapter
    |      +--> SwiftData (iOS)
    |      +--> Room / SQLDelight (Android)
    |      +--> API/static datasets
    |
    +--> normalized chart dataset
           |
           +--> iOS renderer (Swift Charts)
           +--> Android renderer (Compose chart engine)
```

Key rule: keep rendering engine-specific details in platform packages, not in `ChartSpec` core.

## Rendering First Principles

1. Work per frame must be O(n) over points, not O(n²).
2. Data points should have stable identity to reduce redraw churn and preserve animation continuity.
3. Series style resolution (color/line-width/opacity) should be precomputed once per render pass.
4. Defaults should bias for readability: visible legends, clear empty states, and basic axis context.
