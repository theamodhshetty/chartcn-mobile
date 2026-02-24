package dev.chartcn.mobile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import java.util.Locale
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

@Composable
fun ChartCNView(
  spec: ChartSpec,
  rows: List<ChartRow>,
  modifier: Modifier = Modifier
) {
  val rawPoints = remember(spec, rows) { ChartDataPipeline.points(spec, rows) }
  val points = remember(rawPoints, spec) {
    ChartDataPipeline.optimizeForViewport(
      points = rawPoints,
      chartType = spec.visual.chartType,
      seriesOrder = spec.visual.series.map { it.field }
    )
  }
  val xLabels = remember(points) { buildXAxisLabels(points) }
  val seriesByField = remember(spec) { spec.visual.series.associateBy { it.field } }
  val seriesColors = remember(spec) { buildSeriesColorMap(spec) }
  val pieSlices = remember(spec, rows) { buildPieSlices(spec, rows) }
  val seriesOrderMap = remember(spec) {
    spec.visual.series.mapIndexed { index, series -> series.field to index }.toMap()
  }
  var selectedXIndex by remember(spec, rows) { mutableStateOf<Int?>(null) }

  val selectedPoints = remember(points, selectedXIndex, seriesOrderMap) {
    val index = selectedXIndex ?: return@remember emptyList()
    points
      .filter { it.xIndex == index }
      .sortedWith(
        compareBy<ChartPoint>(
          { seriesOrderMap[it.seriesField] ?: Int.MAX_VALUE },
          { it.seriesField }
        )
      )
  }

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
      spec.visual.emptyState?.description?.takeIf { it.isNotBlank() }?.let { description ->
        Text(
          text = description,
          style = MaterialTheme.typography.bodySmall,
          color = MaterialTheme.colorScheme.onSurfaceVariant,
          modifier = Modifier.padding(top = 4.dp)
        )
      }
      return@Column
    }

    val selectionEnabled = selectionEnabled(spec, xLabels.isNotEmpty())

    when (spec.visual.chartType) {
      ChartType.LINE -> CartesianCanvas(
        points = points,
        xLabels = xLabels,
        spec = spec,
        seriesByField = seriesByField,
        seriesColors = seriesColors,
        mode = CartesianMode.LINE,
        selectionEnabled = selectionEnabled,
        selectedXIndex = selectedXIndex,
        onSelectionChanged = { selectedXIndex = it }
      )

      ChartType.BAR -> CartesianCanvas(
        points = points,
        xLabels = xLabels,
        spec = spec,
        seriesByField = seriesByField,
        seriesColors = seriesColors,
        mode = CartesianMode.BAR,
        selectionEnabled = selectionEnabled,
        selectedXIndex = selectedXIndex,
        onSelectionChanged = { selectedXIndex = it }
      )

      ChartType.AREA -> CartesianCanvas(
        points = points,
        xLabels = xLabels,
        spec = spec,
        seriesByField = seriesByField,
        seriesColors = seriesColors,
        mode = CartesianMode.AREA,
        selectionEnabled = selectionEnabled,
        selectedXIndex = selectedXIndex,
        onSelectionChanged = { selectedXIndex = it }
      )

      ChartType.SCATTER -> CartesianCanvas(
        points = points,
        xLabels = xLabels,
        spec = spec,
        seriesByField = seriesByField,
        seriesColors = seriesColors,
        mode = CartesianMode.SCATTER,
        selectionEnabled = selectionEnabled,
        selectedXIndex = selectedXIndex,
        onSelectionChanged = { selectedXIndex = it }
      )

      ChartType.COMBO -> CartesianCanvas(
        points = points,
        xLabels = xLabels,
        spec = spec,
        seriesByField = seriesByField,
        seriesColors = seriesColors,
        mode = CartesianMode.COMBO,
        selectionEnabled = selectionEnabled,
        selectedXIndex = selectedXIndex,
        onSelectionChanged = { selectedXIndex = it }
      )

      ChartType.PIE -> PieCanvas(slices = pieSlices, donut = false)
      ChartType.DONUT -> PieCanvas(slices = pieSlices, donut = true)
      ChartType.KPI -> KpiView(spec, rows)
    }

    if (selectionEnabled && selectedXIndex != null && selectedPoints.isNotEmpty()) {
      SelectionSummary(
        xLabel = xLabels.getOrNull(selectedXIndex ?: -1).orEmpty(),
        points = selectedPoints,
        colorForSeries = { field ->
          seriesColors[field] ?: defaultPalette(seriesOrderMap[field] ?: 0)
        },
        valueFormatter = { value ->
          formatValue(spec, value)
        }
      )
    }

    if (shouldShowLegend(spec)) {
      when (spec.visual.chartType) {
        ChartType.PIE, ChartType.DONUT -> SliceLegend(slices = pieSlices)
        ChartType.KPI -> Unit
        else -> SeriesLegend(series = spec.visual.series, seriesColors = seriesColors)
      }
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
private fun CartesianCanvas(
  points: List<ChartPoint>,
  xLabels: List<String>,
  spec: ChartSpec,
  seriesByField: Map<String, Series>,
  seriesColors: Map<String, Color>,
  mode: CartesianMode,
  selectionEnabled: Boolean,
  selectedXIndex: Int?,
  onSelectionChanged: (Int?) -> Unit
) {
  val rawMin = points.minOfOrNull { it.yValue } ?: 0.0
  val rawMax = points.maxOfOrNull { it.yValue } ?: 1.0
  val yPadding = (rawMax - rawMin).takeIf { it > 0.0 }?.times(0.08) ?: 1.0
  val yMin = spec.visual.axes?.y?.min ?: (rawMin - yPadding)
  val yMax = spec.visual.axes?.y?.max ?: (rawMax + yPadding)
  val safeRange = max(0.000001, yMax - yMin)
  val seriesMap = remember(points) { points.groupBy { it.seriesField } }
  val seriesOrder = remember(spec) { spec.visual.series.map { it.field } }
  val xCount = max(1, xLabels.size)
  val gridColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
  val crosshairColor = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
  val pointRadius = (spec.platformOverrides?.android?.pointRadius?.toFloat() ?: 5f)
    .coerceAtLeast(2f)

  Canvas(
    modifier = Modifier
      .fillMaxWidth()
      .height(240.dp)
      .padding(top = 10.dp)
      .pointerInput(xLabels, selectionEnabled) {
        if (!selectionEnabled || xLabels.isEmpty()) return@pointerInput
        detectTapGestures { offset ->
          onSelectionChanged(nearestIndex(offset.x, size.width.toFloat(), xCount))
        }
      }
      .pointerInput(xLabels, selectionEnabled) {
        if (!selectionEnabled || xLabels.isEmpty()) return@pointerInput
        detectDragGestures(
          onDragStart = { offset ->
            onSelectionChanged(nearestIndex(offset.x, size.width.toFloat(), xCount))
          },
          onDragEnd = {
            onSelectionChanged(null)
          },
          onDragCancel = {
            onSelectionChanged(null)
          },
          onDrag = { change, _ ->
            onSelectionChanged(nearestIndex(change.position.x, size.width.toFloat(), xCount))
          }
        )
      }
  ) {
    val width = size.width
    val height = size.height
    val xStep = if (xCount <= 1) width else width / (xCount - 1)

    val gridTicks = 4
    for (tick in 0..gridTicks) {
      val ratio = tick / gridTicks.toFloat()
      val y = height - (ratio * height)
      drawLine(
        color = gridColor,
        start = Offset(0f, y),
        end = Offset(width, y),
        strokeWidth = 1f
      )
    }

    for ((seriesIndex, seriesField) in seriesOrder.withIndex()) {
      val seriesPoints = seriesMap[seriesField].orEmpty()
      if (seriesPoints.isEmpty()) continue

      val seriesStyle = seriesByField[seriesField]?.style
      val lineWidth = (seriesStyle?.lineWidth?.toFloat() ?: 3.5f).coerceIn(1f, 10f)
      val opacity = (seriesStyle?.opacity?.toFloat() ?: 1f).coerceIn(0.05f, 1f)
      val color = (seriesColors[seriesField] ?: defaultPalette(seriesIndex)).copy(alpha = opacity)

      val positions = seriesPoints.map { point ->
        val x = point.xIndex * xStep
        val normalizedY = ((point.yValue - yMin) / safeRange).toFloat()
        val y = height - (normalizedY * height)
        PlotPoint(
          offset = Offset(x.toFloat(), y),
          xIndex = point.xIndex
        )
      }

      when (mode) {
        CartesianMode.LINE -> drawLineSeries(positions, color, lineWidth, pointRadius, selectedXIndex)
        CartesianMode.BAR -> drawBarSeries(
          positions = positions,
          seriesIndex = seriesIndex,
          seriesCount = seriesOrder.size,
          xStep = xStep,
          canvasHeight = height,
          color = color,
          selectedXIndex = selectedXIndex
        )

        CartesianMode.AREA -> drawAreaSeries(
          positions = positions,
          color = color,
          lineWidth = lineWidth,
          canvasHeight = height,
          selectedXIndex = selectedXIndex
        )

        CartesianMode.SCATTER -> drawScatterSeries(positions, color, pointRadius + 1f, selectedXIndex)
        CartesianMode.COMBO -> {
          val renderer = seriesByField[seriesField]?.renderer
          if (renderer == "bar") {
            drawBarSeries(
              positions = positions,
              seriesIndex = seriesIndex,
              seriesCount = seriesOrder.size,
              xStep = xStep,
              canvasHeight = height,
              color = color,
              selectedXIndex = selectedXIndex
            )
          } else {
            drawLineSeries(positions, color, lineWidth, pointRadius, selectedXIndex)
          }
        }
      }
    }

    if (selectionEnabled && selectedXIndex != null) {
      val crosshairX = if (xCount <= 1) {
        width / 2f
      } else {
        selectedXIndex.coerceIn(0, xCount - 1) * xStep
      }

      drawLine(
        color = crosshairColor,
        start = Offset(crosshairX, 0f),
        end = Offset(crosshairX, height),
        strokeWidth = 1f
      )
    }
  }

  if (xLabels.isNotEmpty()) {
    AxisLabels(labels = xLabels)
  }
}

@Composable
private fun PieCanvas(slices: List<Slice>, donut: Boolean) {
  val filteredSlices = slices.filter { it.value > 0.0 }
  val total = filteredSlices.sumOf { it.value }.takeIf { it > 0.0 } ?: 1.0

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

      filteredSlices.forEach { slice ->
        val sweep = ((slice.value / total) * 360.0).toFloat()
        drawArc(
          color = slice.color,
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
  val formatted = if (latest == null) {
    "--"
  } else {
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

@Composable
private fun SelectionSummary(
  xLabel: String,
  points: List<ChartPoint>,
  colorForSeries: (String) -> Color,
  valueFormatter: (Double) -> String
) {
  Column(
    modifier = Modifier
      .fillMaxWidth()
      .padding(top = 10.dp)
      .background(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(10.dp)
      )
      .padding(10.dp),
    verticalArrangement = Arrangement.spacedBy(6.dp)
  ) {
    Text(
      text = xLabel,
      style = MaterialTheme.typography.labelMedium,
      color = MaterialTheme.colorScheme.onSurfaceVariant
    )

    points.forEach { point ->
      Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
      ) {
        Row(
          horizontalArrangement = Arrangement.spacedBy(8.dp),
          verticalAlignment = Alignment.CenterVertically
        ) {
          Box(
            modifier = Modifier
              .size(8.dp)
              .background(color = colorForSeries(point.seriesField), shape = CircleShape)
          )
          Text(text = point.seriesLabel, style = MaterialTheme.typography.labelMedium)
        }
        Text(
          text = valueFormatter(point.yValue),
          style = MaterialTheme.typography.labelMedium
        )
      }
    }
  }
}

@Composable
private fun AxisLabels(labels: List<String>) {
  val first = labels.firstOrNull().orEmpty()
  val middle = labels.getOrNull(labels.size / 2).orEmpty()
  val last = labels.lastOrNull().orEmpty()

  Row(
    modifier = Modifier
      .fillMaxWidth()
      .padding(top = 6.dp),
    horizontalArrangement = Arrangement.SpaceBetween,
    verticalAlignment = Alignment.CenterVertically
  ) {
    Text(text = first, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    if (labels.size > 2) {
      Text(text = middle, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
    if (labels.size > 1) {
      Text(text = last, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
  }
}

@Composable
private fun SeriesLegend(series: List<Series>, seriesColors: Map<String, Color>) {
  Column(modifier = Modifier.padding(top = 10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
    series.forEachIndexed { index, item ->
      val color = seriesColors[item.field] ?: defaultPalette(index)
      LegendItem(label = item.label, color = color)
    }
  }
}

@Composable
private fun SliceLegend(slices: List<Slice>) {
  if (slices.isEmpty()) return
  Column(modifier = Modifier.padding(top = 10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
    slices.forEach { slice ->
      LegendItem(label = slice.label, color = slice.color)
    }
  }
}

@Composable
private fun LegendItem(label: String, color: Color) {
  Row(
    horizontalArrangement = Arrangement.spacedBy(8.dp),
    verticalAlignment = Alignment.CenterVertically
  ) {
    Box(
      modifier = Modifier
        .size(10.dp)
        .background(color = color, shape = CircleShape)
    )
    Text(text = label, style = MaterialTheme.typography.labelMedium)
  }
}

private fun selectionEnabled(spec: ChartSpec, hasXAxisValues: Boolean): Boolean {
  if (!hasXAxisValues) return false
  if (spec.visual.chartType !in listOf(ChartType.LINE, ChartType.BAR, ChartType.AREA, ChartType.SCATTER, ChartType.COMBO)) {
    return false
  }
  if (spec.visual.tooltip?.enabled == false) return false
  return spec.interactions?.selection != "none"
}

private fun shouldShowLegend(spec: ChartSpec): Boolean {
  if (spec.visual.legend?.visible == false) return false
  return when (spec.visual.chartType) {
    ChartType.PIE, ChartType.DONUT -> true
    ChartType.KPI -> false
    else -> spec.visual.series.size > 1
  }
}

private fun buildXAxisLabels(points: List<ChartPoint>): List<String> {
  if (points.isEmpty()) return emptyList()
  val size = (points.maxOfOrNull { it.xIndex } ?: 0) + 1
  val labels = MutableList(size) { "" }
  for (point in points) {
    if (labels[point.xIndex].isEmpty()) {
      labels[point.xIndex] = point.xLabel
    }
  }
  return labels
}

private fun buildSeriesColorMap(spec: ChartSpec): Map<String, Color> {
  return spec.visual.series.mapIndexed { index, series ->
    series.field to resolveSeriesColor(spec, series.field, index)
  }.toMap()
}

private fun buildPieSlices(spec: ChartSpec, rows: List<ChartRow>): List<Slice> {
  val firstSeries = spec.visual.series.firstOrNull()
  val firstDimensionKey = spec.data.dimensions.firstOrNull()?.key

  return rows.mapIndexedNotNull { index, row ->
    val value = row[firstSeries?.field].toDoubleOrNull() ?: return@mapIndexedNotNull null
    if (value <= 0.0) return@mapIndexedNotNull null

    val label = row[firstDimensionKey].toLabel().ifBlank { "Slice ${index + 1}" }
    Slice(
      label = label,
      value = value,
      color = defaultPalette(index)
    )
  }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawLineSeries(
  positions: List<PlotPoint>,
  color: Color,
  lineWidth: Float,
  pointRadius: Float,
  selectedXIndex: Int?
) {
  if (positions.isEmpty()) return
  positions.zipWithNext { left, right ->
    drawLine(
      color = color.copy(alpha = pointAlpha(selectedXIndex, left.xIndex)),
      start = left.offset,
      end = right.offset,
      strokeWidth = lineWidth
    )
  }
  positions.forEach { point ->
    drawCircle(
      color = color.copy(alpha = pointAlpha(selectedXIndex, point.xIndex)),
      radius = pointRadius,
      center = point.offset
    )
  }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawScatterSeries(
  positions: List<PlotPoint>,
  color: Color,
  pointRadius: Float,
  selectedXIndex: Int?
) {
  positions.forEach { point ->
    drawCircle(
      color = color.copy(alpha = pointAlpha(selectedXIndex, point.xIndex)),
      radius = pointRadius,
      center = point.offset
    )
  }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawBarSeries(
  positions: List<PlotPoint>,
  seriesIndex: Int,
  seriesCount: Int,
  xStep: Float,
  canvasHeight: Float,
  color: Color,
  selectedXIndex: Int?
) {
  val slotWidth = if (xStep == 0f) 40f else xStep * 0.8f
  val barWidth = max(6f, slotWidth / max(1, seriesCount))

  positions.forEach { point ->
    val left = point.offset.x - (slotWidth / 2f) + (seriesIndex * barWidth)
    drawRect(
      color = color.copy(alpha = pointAlpha(selectedXIndex, point.xIndex)),
      topLeft = Offset(left, point.offset.y),
      size = Size(barWidth, canvasHeight - point.offset.y)
    )
  }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawAreaSeries(
  positions: List<PlotPoint>,
  color: Color,
  lineWidth: Float,
  canvasHeight: Float,
  selectedXIndex: Int?
) {
  if (positions.isEmpty()) return

  if (positions.size == 1) {
    val alpha = pointAlpha(selectedXIndex, positions.first().xIndex)
    drawCircle(color = color.copy(alpha = alpha), radius = 5f, center = positions.first().offset)
    return
  }

  val path = Path().apply {
    moveTo(positions.first().offset.x, canvasHeight)
    positions.forEach { point -> lineTo(point.offset.x, point.offset.y) }
    lineTo(positions.last().offset.x, canvasHeight)
    close()
  }

  val lineAlpha = if (selectedXIndex == null) 1f else 0.6f
  drawPath(path = path, color = color.copy(alpha = 0.20f * lineAlpha), style = Fill)
  positions.zipWithNext { left, right ->
    val alpha = min(pointAlpha(selectedXIndex, left.xIndex), pointAlpha(selectedXIndex, right.xIndex))
    drawLine(
      color = color.copy(alpha = alpha),
      start = left.offset,
      end = right.offset,
      strokeWidth = lineWidth
    )
  }
}

private fun nearestIndex(x: Float, width: Float, count: Int): Int {
  if (count <= 1 || width <= 0f) return 0
  val step = width / (count - 1)
  val raw = (x / step).roundToInt()
  return raw.coerceIn(0, count - 1)
}

private fun pointAlpha(selectedXIndex: Int?, pointXIndex: Int): Float {
  if (selectedXIndex == null) return 1f
  return if (selectedXIndex == pointXIndex) 1f else 0.32f
}

private fun formatValue(spec: ChartSpec, value: Double): String {
  val decimals = spec.formatting?.number?.maximumFractionDigits ?: 2
  val pattern = "%.${decimals}f"
  return if (spec.formatting?.currency?.code != null) {
    "${spec.formatting.currency.code} ${String.format(Locale.US, pattern, value)}"
  } else {
    String.format(Locale.US, pattern, value)
  }
}

private data class Slice(val label: String, val value: Double, val color: Color)

private data class PlotPoint(
  val offset: Offset,
  val xIndex: Int
)

private fun resolveSeriesColor(spec: ChartSpec, seriesField: String, defaultIndex: Int): Color {
  val styleColor = spec.visual.series
    .firstOrNull { it.field == seriesField }
    ?.style
    ?.color

  val resolved = if (styleColor != null && styleColor.startsWith("token.")) {
    spec.theming?.tokens?.get(styleColor)
  } else {
    styleColor
  }

  return parseColor(resolved) ?: defaultPalette(defaultIndex)
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
  return primitive.content.toDoubleOrNull()
}

private fun JsonElement?.toLabel(): String {
  val primitive = this as? JsonPrimitive ?: return ""
  return primitive.content
}
