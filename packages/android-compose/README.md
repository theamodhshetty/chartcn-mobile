# Android Compose Package (Scaffold)

Current capabilities:

1. Parse typed `ChartSpec` JSON (`ChartSpecParser`).
2. Fetch query-driven rows from Room/SQLite (`RoomAdapter`).
3. Fetch query-driven rows from SQLDelight via a query executor bridge (`SqlDelightAdapter`).
4. Fetch paginated API rows via `ApiAdapter`.
5. Render `line`, `bar`, `area`, `scatter`, `pie`, `donut`, `combo`, and `kpi` charts (`ChartCNView`).
6. Apply basic color token resolution and accessibility content descriptions.

## Quick usage

```kotlin
val spec = ChartSpecParser.parse(rawJson)
ChartCNView(spec = spec, rows = rows)
```

SQLDelight bridge usage:

```kotlin
val sqlDelight = SqlDelightAdapter { queryName, args ->
  // Dispatch to generated SQLDelight queries, then map results to key/value rows.
  emptyList()
}

val rows = sqlDelight.fetchRows(
  queryName = "RevenueQueries.byAccount",
  args = mapOf("accountId" to JsonPrimitive("acct_123"))
)
```

API pagination bridge usage:

```kotlin
val api = ApiAdapter { request ->
  // Execute request.source.endpoint/request.method with request.query/request.body.
  ApiPageResponse(payload = JsonArray(emptyList()))
}

val rows = api.fetchRows(source = spec.data.source)
```

## Build

Run Android tests with the checked-in Gradle wrapper:

```bash
./gradlew test
```
