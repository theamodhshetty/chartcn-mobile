import dev.chartcn.mobile.ChartCNView
import dev.chartcn.mobile.ChartSpecParser
import kotlinx.serialization.json.JsonPrimitive

val rawSpec = java.io.File("comparison-bar/chartspec.json").readText()
val spec = ChartSpecParser.parse(rawSpec)

val rows = listOf(
  mapOf("segment" to JsonPrimitive("Organic"), "conversion_rate" to JsonPrimitive(41.2)),
  mapOf("segment" to JsonPrimitive("Paid"), "conversion_rate" to JsonPrimitive(33.9)),
  mapOf("segment" to JsonPrimitive("Referral"), "conversion_rate" to JsonPrimitive(48.7)),
  mapOf("segment" to JsonPrimitive("Email"), "conversion_rate" to JsonPrimitive(44.6))
)

ChartCNView(spec = spec, rows = rows)
