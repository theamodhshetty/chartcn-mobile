package dev.chartcn.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

@Composable
fun ChartCNView(
  spec: ChartSpec,
  rows: List<ChartRow>,
  modifier: Modifier = Modifier
) {
  val points = remember(spec, rows) { ChartDataPipeline.points(spec, rows) }

  Column(
    modifier = modifier
      .semantics { contentDescription = spec.accessibility.chartTitle }
      .padding(12.dp)
  ) {
    Text(
      text = spec.metadata.name,
      style = MaterialTheme.typography.titleMedium
    )

    if (rows.isEmpty()) {
      Text(
        text = spec.visual.emptyState?.title ?: "No Data",
        style = MaterialTheme.typography.bodyMedium,
        modifier = Modifier.padding(top = 8.dp)
      )
      return@Column
    }

    when (spec.visual.chartType) {
      ChartType.LINE -> CartesianCanvas(points, spec, mode = CartesianMode.LINE)
      ChartType.BAR -> CartesianCanvas(points, spec, mode = CartesianMode.BAR)
      ChartType.AREA -> CartesianCanvas(points, spec, mode = CartesianMode.AREA)
      ChartType.SCATTER -> CartesianCanvas(points, spec, mode = CartesianMode.SCATTER)
      ChartType.COMBO -> CartesianCanvas(points, spec, mode = CartesianMode.COMBO)
      ChartType.PIE -> PieCanvas(spec, rows, donut = false)
      ChartType.DONUT -> PieCanvas(spec, rows, donut = true)
      ChartType.KPI -> KpiView(spec, rows)
    }
  }
}

private enum class CartesianMode {
  LINE,
  BAR,
  AREA,
  SCATTER,
  COMBO
}

@Composable
private fun CartesianCanvas(points: List<ChartPoint>, spec: ChartSpec, mode: CartesianMode) {
  val xLabels = points.map { it.xLabel }.distinct()
  val yMin = spec.visual.axes?.y?.min ?: points.minOfOrNull { it.yValue } ?: 0.0
  val yMax = spec.visual.axes?.y?.max ?: points.maxOfOrNull { it.yValue } ?: 1.0
  val safeRange = max(0.000001, yMax - yMin)

  Canvas(
    modifier = Modifier
      .fillMaxWidth()
      .height(240.dp)
      .padding(top = 10.dp)
  ) {
    val width = size.width
    val height = size.height
    val xStep = if (xLabels.size <= 1) width else width / (xLabels.size - 1)

    val seriesMap = points.groupBy { it.seriesField }
    val seriesOrder = spec.visual.series.map { it.field }

    for ((seriesIndex, seriesField) in seriesOrder.withIndex()) {
      val seriesPoints = seriesMap[seriesField].orEmpty()
      if (seriesPoints.isEmpty()) continue

      val color = resolveColor(spec, seriesField)
      var previous: Offset? = null

      for (point in seriesPoints) {
        val xIndex = xLabels.indexOf(point.xLabel).coerceAtLeast(0)
        val x = xIndex * xStep
        val normalizedY = ((point.yValue - yMin) / safeRange).toFloat()
        val y = height - (normalizedY * height)
        val current = Offset(x.toFloat(), y)

        when (mode) {
          CartesianMode.LINE -> {
            if (previous != null) {
              drawLine(color, previous!!, current, strokeWidth = 4f)
            }
            drawCircle(color, radius = 5f, center = current)
          }

          CartesianMode.BAR -> {
            val barWidth = max(8f, xStep.toFloat() / max(1, seriesOrder.size) - 6f)
            val left = x - (xStep / 2f) + (seriesIndex * (barWidth + 2f))
            drawRect(
              color = color,
              topLeft = Offset(left.toFloat(), y),
              size = Size(barWidth, height - y)
            )
          }

          CartesianMode.AREA -> {
            if (previous != null) {
              drawLine(color, previous!!, current, strokeWidth = 3f)
            }
            drawLine(
              color = color.copy(alpha = 0.25f),
              start = Offset(current.x, height),
              end = current,
              strokeWidth = 6f
            )
          }

          CartesianMode.SCATTER -> {
            drawCircle(color, radius = 6f, center = current)
          }

          CartesianMode.COMBO -> {
            val renderer = spec.visual.series.firstOrNull { it.field == seriesField }?.renderer
            if (renderer == "bar") {
              val barWidth = max(8f, xStep.toFloat() / max(1, seriesOrder.size) - 6f)
              val left = x - (xStep / 2f) + (seriesIndex * (barWidth + 2f))
              drawRect(
                color = color,
                topLeft = Offset(left.toFloat(), y),
                size = Size(barWidth, height - y)
              )
            } else {
              if (previous != null) {
                drawLine(color, previous!!, current, strokeWidth = 4f)
              }
              drawCircle(color, radius = 5f, center = current)
            }
          }
        }

        previous = current
      }
    }
  }
}

@Composable
private fun PieCanvas(spec: ChartSpec, rows: List<ChartRow>, donut: Boolean) {
  val firstSeries = spec.visual.series.firstOrNull()
  val firstDimensionKey = spec.data.dimensions.firstOrNull()?.key
  val slices = rows.mapNotNull { row ->
    val value = row[firstSeries?.field].toDoubleOrNull() ?: return@mapNotNull null
    val label = row[firstDimensionKey].toLabel()
    Slice(label = label, value = max(0.0, value))
  }

  val total = slices.sumOf { it.value }.takeIf { it > 0.0 } ?: 1.0

  Box(modifier = Modifier.fillMaxWidth()) {
    Canvas(
      modifier = Modifier
        .fillMaxWidth()
        .height(240.dp)
        .padding(top = 10.dp)
    ) {
      val chartSize = min(size.width, size.height)
      val topLeft = Offset((size.width - chartSize) / 2f, (size.height - chartSize) / 2f)
      val pieSize = Size(chartSize, chartSize)
      var start = -90f

      slices.forEachIndexed { index, slice ->
        val sweep = ((slice.value / total) * 360.0).toFloat()
        val color = defaultPalette(index)

        drawArc(
          color = color,
          startAngle = start,
          sweepAngle = sweep,
          useCenter = !donut,
          topLeft = topLeft,
          size = pieSize,
          style = if (donut) Stroke(width = chartSize * 0.24f) else Fill
        )

        start += sweep
      }
    }
  }
}

@Composable
private fun KpiView(spec: ChartSpec, rows: List<ChartRow>) {
  val firstSeries = spec.visual.series.firstOrNull()
  val latest = rows.lastOrNull()?.get(firstSeries?.field).toDoubleOrNull()
  val formatted = if (latest == null) "--" else {
    val decimals = spec.formatting?.number?.maximumFractionDigits ?: 2
    String.format(Locale.US, "%.${decimals}f", latest)
  }

  Column(modifier = Modifier.padding(top = 10.dp)) {
    Text(
      text = firstSeries?.label ?: "KPI",
      style = MaterialTheme.typography.bodyMedium,
      color = MaterialTheme.colorScheme.onSurfaceVariant
    )
    Text(
      text = formatted,
      style = MaterialTheme.typography.displaySmall
    )
  }
}

private data class Slice(val label: String, val value: Double)

private fun resolveColor(spec: ChartSpec, seriesField: String): Color {
  val styleColor = spec.visual.series
    .firstOrNull { it.field == seriesField }
    ?.style
    ?.color

  val resolved = if (styleColor != null && styleColor.startsWith("token.")) {
    spec.theming?.tokens?.get(styleColor)
  } else {
    styleColor
  }

  return parseColor(resolved) ?: defaultPalette(spec.visual.series.indexOfFirst { it.field == seriesField })
}

private fun parseColor(value: String?): Color? {
  if (value == null) return null
  val cleaned = value.removePrefix("#")
  val raw = cleaned.toLongOrNull(16) ?: return null

  return when (cleaned.length) {
    6 -> {
      val r = ((raw shr 16) and 0xFF) / 255f
      val g = ((raw shr 8) and 0xFF) / 255f
      val b = (raw and 0xFF) / 255f
      Color(r, g, b, 1f)
    }

    8 -> {
      val a = ((raw shr 24) and 0xFF) / 255f
      val r = ((raw shr 16) and 0xFF) / 255f
      val g = ((raw shr 8) and 0xFF) / 255f
      val b = (raw and 0xFF) / 255f
      Color(r, g, b, a)
    }

    else -> null
  }
}

private fun defaultPalette(index: Int): Color {
  val palette = listOf(
    Color(0xFF1D4ED8),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
    Color(0xFF059669),
    Color(0xFF8B5CF6)
  )
  return palette[(index.coerceAtLeast(0)) % palette.size]
}

private fun JsonElement?.toDoubleOrNull(): Double? {
  val primitive = this as? JsonPrimitive ?: return null
  return primitive.doubleOrNull ?: primitive.content.toDoubleOrNull()
}

private fun JsonElement?.toLabel(): String {
  val primitive = this as? JsonPrimitive ?: return ""
  return primitive.content
}
