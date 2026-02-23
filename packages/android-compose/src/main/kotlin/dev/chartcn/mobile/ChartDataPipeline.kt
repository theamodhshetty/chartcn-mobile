package dev.chartcn.mobile

import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive

internal data class ChartPoint(
  val xLabel: String,
  val yValue: Double,
  val seriesField: String,
  val seriesLabel: String
)

internal object ChartDataPipeline {
  fun points(spec: ChartSpec, rows: List<ChartRow>): List<ChartPoint> {
    return rows.flatMap { row ->
      spec.visual.series.mapNotNull { series ->
        val y = row[series.field]?.toDoubleOrNull() ?: return@mapNotNull null
        val xLabel = spec.visual.xField?.let { key -> row[key].asLabel() } ?: ""

        ChartPoint(
          xLabel = xLabel,
          yValue = y,
          seriesField = series.field,
          seriesLabel = series.label
        )
      }
    }
  }

  private fun JsonElement?.toDoubleOrNull(): Double? {
    val primitive = this as? JsonPrimitive ?: return null
    return primitive.doubleOrNull ?: primitive.content.toDoubleOrNull()
  }

  private fun JsonElement?.asLabel(): String {
    val primitive = this as? JsonPrimitive ?: return ""
    return primitive.content
  }
}
