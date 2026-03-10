# iOS SwiftData Dashboard Example

This example is a concrete SwiftUI dashboard scaffold, not a placeholder.

It demonstrates:

1. Seeding a local SwiftData store on first launch.
2. Loading `ChartSpec` files from the app bundle.
3. Mapping SwiftData models into `ChartRow` values with `ChartSwiftDataMappable`.
4. Rendering a KPI card, a revenue trend, and a channel comparison chart from the same dashboard.

## Files

- `Charts/revenue-kpi.chartspec.json`
- `Charts/revenue-trend.chartspec.json`
- `Charts/channel-comparison.chartspec.json`
- `Sources/DashboardApp.swift`
- `Sources/DashboardModels.swift`
- `Sources/DashboardSeed.swift`
- `Sources/DashboardView.swift`

## How To Run

1. Create a new iOS app target in Xcode with SwiftUI and SwiftData enabled.
2. Add `ChartCNMobile` as a local Swift package dependency from `packages/ios-swiftui`.
3. Copy the `Sources/*.swift` files into the app target.
4. Copy the `Charts/*.chartspec.json` files into a `Charts` group and ensure they are bundled in "Copy Bundle Resources".
5. Launch the app. The example seeds demo records once, then renders all three widgets.

## What To Look At

- `DashboardView.swift`: bundle spec loading plus spec-driven row loading.
- `DashboardModels.swift`: model-to-row mapping boundary.
- `DashboardSeed.swift`: one-time seed logic for previews, simulators, and local demos.

## Notes

- The example keeps fetch wiring explicit on purpose. `ChartSpec` declares the source shape, while the app decides the concrete SwiftData entity type to fetch.
- The KPI and trend charts share the same `DailyRevenue` rows to keep the example small and realistic.
