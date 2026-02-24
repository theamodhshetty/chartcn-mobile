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

  fun optimizeForViewport(
    points: List<ChartPoint>,
    chartType: ChartType,
    seriesOrder: List<String>
  ): List<ChartPoint> {
    if (points.isEmpty()) return emptyList()

    val (windowLimit, sampleLimit) = viewportLimits(chartType)
    var buckets = bucketize(points)

    if (buckets.size > windowLimit) {
      buckets = buckets.takeLast(windowLimit)
    }

    if (buckets.size > sampleLimit) {
      buckets = sampleBuckets(buckets, sampleLimit)
    }

    val orderMap = seriesOrder.withIndex().associate { (index, field) -> field to index }
    val optimized = ArrayList<ChartPoint>(points.size.coerceAtMost(sampleLimit * maxOf(1, seriesOrder.size)))

    buckets.forEachIndexed { index, bucket ->
      bucket.points
        .sortedWith(
          compareBy<ChartPoint>(
            { orderMap[it.seriesField] ?: Int.MAX_VALUE },
            { it.seriesField }
          )
        )
        .forEach { point ->
          optimized.add(
            ChartPoint(
              xIndex = index,
              xLabel = bucket.xLabel,
              yValue = point.yValue,
              seriesField = point.seriesField,
              seriesLabel = point.seriesLabel
            )
          )
        }
    }

    return optimized
  }

  private fun viewportLimits(chartType: ChartType): Pair<Int, Int> {
    return when (chartType) {
      ChartType.LINE, ChartType.AREA, ChartType.SCATTER, ChartType.COMBO -> 420 to 180
      ChartType.BAR -> 260 to 140
      ChartType.PIE, ChartType.DONUT, ChartType.KPI -> Int.MAX_VALUE to Int.MAX_VALUE
    }
  }

  private fun bucketize(points: List<ChartPoint>): List<PointBucket> {
    val grouped = HashMap<Int, MutableList<ChartPoint>>()

    points.forEach { point ->
      grouped.getOrPut(point.xIndex) { mutableListOf() }.add(point)
    }

    return grouped.keys
      .sorted()
      .map { index ->
        val entries = grouped[index].orEmpty()
        PointBucket(
          sourceIndex = index,
          xLabel = entries.firstOrNull()?.xLabel.orEmpty(),
          points = entries
        )
      }
  }

  private fun sampleBuckets(
    buckets: List<PointBucket>,
    targetCount: Int
  ): List<PointBucket> {
    if (targetCount <= 1 || buckets.size <= targetCount) return buckets

    val step = (buckets.size - 1).toDouble() / (targetCount - 1).toDouble()
    val sampled = ArrayList<PointBucket>(targetCount)

    repeat(targetCount) { index ->
      val raw = index * step
      val bucketIndex = raw.toInt().coerceAtMost(buckets.size - 1)
      sampled.add(buckets[bucketIndex])
    }

    return sampled
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

private data class PointBucket(
  val sourceIndex: Int,
  val xLabel: String,
  val points: List<ChartPoint>
)
