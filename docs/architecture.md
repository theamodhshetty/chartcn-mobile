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
