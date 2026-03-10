# Android Room Dashboard Example

This example is a concrete Compose + Room dashboard scaffold, not a placeholder.

It demonstrates:

1. Seeding a local Room database on first launch.
2. Loading `ChartSpec` files from `src/main/assets/charts`.
3. Querying rows with `RoomAdapter` from spec-declared tables.
4. Rendering a KPI card, a revenue trend, and a channel comparison chart in one screen.

## Files

- `src/main/assets/charts/revenue-kpi.chartspec.json`
- `src/main/assets/charts/revenue-trend.chartspec.json`
- `src/main/assets/charts/channel-comparison.chartspec.json`
- `src/main/java/dev/chartcn/example/dashboard/DashboardActivity.kt`
- `src/main/java/dev/chartcn/example/dashboard/DashboardDatabase.kt`
- `src/main/java/dev/chartcn/example/dashboard/DashboardSeed.kt`
- `src/main/java/dev/chartcn/example/dashboard/DashboardScreen.kt`

## How To Run

1. Create a new Android app module with Compose enabled.
2. Add the `chartcn-mobile/packages/android-compose` module or publish output as a dependency.
3. Add Room dependencies for runtime, compiler, and KSP/KAPT in the example app module.
4. Copy `src/main/java/...` and `src/main/assets/charts/...` into the app module.
5. Launch `DashboardActivity`. The example seeds demo rows once, then renders all three widgets.

## What To Look At

- `DashboardScreen.kt`: asset spec loading plus spec-driven `RoomAdapter` queries.
- `DashboardDatabase.kt`: Room entities, DAOs, and database setup.
- `DashboardSeed.kt`: one-time local seed logic for fresh installs and emulator demos.

## Notes

- The example uses `SupportSQLiteDatabase` from Room's open helper so it exercises the same `RoomAdapter` API that production callers use.
- The KPI and trend charts share the same `daily_revenue` rows to keep the example realistic and compact.
