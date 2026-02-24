package dev.chartcn.mobile

import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive

internal data class ChartPoint(
  val xIndex: Int,
  val xLabel: String,
  val yValue: Double,
  val seriesField: String,
  val seriesLabel: String
)

internal object ChartDataPipeline {
  fun points(spec: ChartSpec, rows: List<ChartRow>): List<ChartPoint> {
    val series = spec.visual.series
    if (series.isEmpty() || rows.isEmpty()) return emptyList()

    val xField = spec.visual.xField
    val points = ArrayList<ChartPoint>(rows.size * series.size)

    rows.forEachIndexed { index, row ->
      val xLabel = xField?.let { key -> row[key].asLabel() } ?: ""

      series.forEach { item ->
        val y = row[item.field]?.toDoubleOrNull() ?: return@forEach
        points.add(
          ChartPoint(
            xIndex = index,
            xLabel = xLabel,
            yValue = y,
            seriesField = item.field,
            seriesLabel = item.label
          )
        )
      }
    }

    return points
  }

  private fun JsonElement?.toDoubleOrNull(): Double? {
    val primitive = this as? JsonPrimitive ?: return null
    return primitive.content.toDoubleOrNull()
  }

  private fun JsonElement?.asLabel(): String {
    val primitive = this as? JsonPrimitive ?: return ""
    return primitive.content
  }
}
