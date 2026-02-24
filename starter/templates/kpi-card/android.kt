import dev.chartcn.mobile.ChartCNView
import dev.chartcn.mobile.ChartSpecParser
import kotlinx.serialization.json.JsonPrimitive

val rawSpec = java.io.File("kpi-card/chartspec.json").readText()
val spec = ChartSpecParser.parse(rawSpec)

val rows = listOf(
  mapOf("metric" to JsonPrimitive("MRR"), "value" to JsonPrimitive(128400.0)),
  mapOf("metric" to JsonPrimitive("MRR"), "value" to JsonPrimitive(132100.0)),
  mapOf("metric" to JsonPrimitive("MRR"), "value" to JsonPrimitive(138900.0))
)

ChartCNView(spec = spec, rows = rows)
