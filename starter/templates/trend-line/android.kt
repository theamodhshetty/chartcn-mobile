import dev.chartcn.mobile.ChartCNView
import dev.chartcn.mobile.ChartSpecParser
import kotlinx.serialization.json.JsonPrimitive

val rawSpec = java.io.File("trend-line/chartspec.json").readText()
val spec = ChartSpecParser.parse(rawSpec)

val rows = listOf(
  mapOf("day" to JsonPrimitive("2026-02-18"), "active_users" to JsonPrimitive(1120.0)),
  mapOf("day" to JsonPrimitive("2026-02-19"), "active_users" to JsonPrimitive(1195.0)),
  mapOf("day" to JsonPrimitive("2026-02-20"), "active_users" to JsonPrimitive(1230.0)),
  mapOf("day" to JsonPrimitive("2026-02-21"), "active_users" to JsonPrimitive(1278.0)),
  mapOf("day" to JsonPrimitive("2026-02-22"), "active_users" to JsonPrimitive(1326.0)),
  mapOf("day" to JsonPrimitive("2026-02-23"), "active_users" to JsonPrimitive(1368.0)),
  mapOf("day" to JsonPrimitive("2026-02-24"), "active_users" to JsonPrimitive(1412.0))
)

ChartCNView(spec = spec, rows = rows)
