# iOS SwiftUI Package (Scaffold)

Current capabilities:

1. Decode typed `ChartSpec` from JSON (`ChartSpecLoader`).
2. Convert rows to renderable points (`ChartDataPipeline`).
3. Render `line`, `bar`, `area`, `scatter`, `pie`, `donut`, `combo`, and `kpi` views with Swift Charts (`ChartCNView`).
4. Resolve theming tokens and apply accessibility labels/hints.
5. Fetch chart rows from SwiftData via `SwiftDataAdapter` (iOS 17+).
6. Fetch paginated API rows via `APIAdapter`.

## Quick usage

```swift
let spec = try ChartSpecLoader.load(from: data)
let view = ChartCNView(spec: spec, rows: rows)
```

API pagination bridge usage:

```swift
let adapter = APIAdapter { request in
    // Execute request.source.endpoint/request.method with request.query/request.body.
    APIPageResponse(payload: .array([]))
}

let rows = try await adapter.fetchRows(from: spec.data.source)
```
