# Android Compose Package (Scaffold)

Current capabilities:

1. Parse typed `ChartSpec` JSON (`ChartSpecParser`).
2. Fetch query-driven rows from Room/SQLite (`RoomAdapter`).
3. Render `line`, `bar`, `area`, `scatter`, `pie`, `donut`, `combo`, and `kpi` charts (`ChartCNView`).
4. Apply basic color token resolution and accessibility content descriptions.

## Quick usage

```kotlin
val spec = ChartSpecParser.parse(rawJson)
ChartCNView(spec = spec, rows = rows)
```

## Build

This package includes a standalone `build.gradle.kts`.  
Generate wrapper locally if needed:

```bash
gradle wrapper
./gradlew test
```
