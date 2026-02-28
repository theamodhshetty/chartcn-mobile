package dev.chartcn.mobile

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
data class ChartSpec(
  val specVersion: String,
  val id: String,
  val metadata: Metadata,
  val data: DataConfig,
  val visual: VisualConfig,
  val formatting: Formatting? = null,
  val interactions: Interactions? = null,
  val theming: Theming? = null,
  val accessibility: Accessibility,
  val platformOverrides: PlatformOverrides? = null
)

@Serializable
data class Metadata(
  val name: String,
  val description: String? = null,
  val tags: List<String> = emptyList(),
  val status: String,
  val owners: List<String>,
  val updatedAt: String? = null
)

@Serializable
data class DataConfig(
  val source: Source,
  val dimensions: List<Dimension>,
  val measures: List<Measure>,
  val filters: List<Filter> = emptyList(),
  val transforms: List<Transform> = emptyList()
)

@Serializable
data class Source(
  val adapter: Adapter,
  val entity: String? = null,
  val predicate: String? = null,
  val sort: List<OrderBy> = emptyList(),
  val limit: Int? = null,

  val table: String? = null,
  val where: String? = null,
  val args: JsonElement? = null,
  val orderBy: List<OrderBy> = emptyList(),

  val queryName: String? = null,

  val endpoint: String? = null,
  val method: String? = null,
  val headers: Map<String, String> = emptyMap(),
  val query: Map<String, JsonElement> = emptyMap(),
  val body: Map<String, JsonElement> = emptyMap(),
  val dataPath: String? = null,

  val rows: List<Map<String, JsonElement>> = emptyList()
)

@Serializable
enum class Adapter {
  @SerialName("swiftdata") SWIFTDATA,
  @SerialName("room") ROOM,
  @SerialName("sqldelight") SQLDELIGHT,
  @SerialName("api") API,
  @SerialName("static") STATIC
}

@Serializable
data class Dimension(
  val key: String,
  val type: String,
  val label: String
)

@Serializable
data class Measure(
  val key: String,
  val type: String,
  val label: String,
  val unit: String? = null,
  val currency: String? = null
)

@Serializable
data class Filter(
  val field: String,
  val op: String,
  val value: JsonElement
)

@Serializable
data class Transform(
  val type: String,
  val by: String? = null,
  val direction: String? = null,
  val input: String? = null,
  val window: Int? = null,
  val `as`: String? = null,
  val aggregations: List<Aggregation> = emptyList()
)

@Serializable
data class Aggregation(
  val field: String,
  val op: String,
  val `as`: String
)

@Serializable
data class OrderBy(
  val field: String,
  val direction: String
)

@Serializable
data class VisualConfig(
  val chartType: ChartType,
  val xField: String? = null,
  val groupField: String? = null,
  val stacked: Boolean = false,
  val series: List<Series>,
  val legend: Legend? = null,
  val axes: Axes? = null,
  val tooltip: Tooltip? = null,
  val emptyState: EmptyState? = null
)

@Serializable
enum class ChartType {
  @SerialName("line") LINE,
  @SerialName("bar") BAR,
  @SerialName("area") AREA,
  @SerialName("pie") PIE,
  @SerialName("donut") DONUT,
  @SerialName("scatter") SCATTER,
  @SerialName("combo") COMBO,
  @SerialName("kpi") KPI
}

@Serializable
data class Series(
  val field: String,
  val label: String,
  val renderer: String? = null,
  val style: SeriesStyle? = null
)

@Serializable
data class SeriesStyle(
  val color: String? = null,
  val lineWidth: Double? = null,
  val dash: List<Double> = emptyList(),
  val opacity: Double? = null
)

@Serializable
data class Legend(
  val visible: Boolean = true,
  val position: String? = null
)

@Serializable
data class Axes(
  val x: Axis? = null,
  val y: Axis? = null
)

@Serializable
data class Axis(
  val label: String? = null,
  val min: Double? = null,
  val max: Double? = null,
  val tickCount: Int? = null
)

@Serializable
data class Tooltip(
  val enabled: Boolean = true,
  val mode: String? = null
)

@Serializable
data class EmptyState(
  val title: String? = null,
  val description: String? = null
)

@Serializable
data class Formatting(
  val number: NumberFormatting? = null,
  val currency: CurrencyFormatting? = null,
  val date: DateFormatting? = null
)

@Serializable
data class NumberFormatting(
  val notation: String? = null,
  val maximumFractionDigits: Int? = null
)

@Serializable
data class CurrencyFormatting(
  val code: String? = null,
  val display: String? = null
)

@Serializable
data class DateFormatting(
  val granularity: String? = null
)

@Serializable
data class Interactions(
  val selection: String? = null,
  val drilldown: Drilldown? = null,
  val gestures: List<String> = emptyList()
)

@Serializable
data class Drilldown(
  val enabled: Boolean = false,
  val targetRoute: String? = null,
  val paramField: String? = null
)

@Serializable
data class Theming(
  val palette: String? = null,
  val tokens: Map<String, String> = emptyMap()
)

@Serializable
data class Accessibility(
  val chartTitle: String,
  val summaryTemplate: String,
  val announceOnLoad: Boolean = true
)

@Serializable
data class PlatformOverrides(
  val ios: IOSOverrides? = null,
  val android: AndroidOverrides? = null
)

@Serializable
data class IOSOverrides(
  val interpolation: String? = null,
  val symbolSize: Double? = null
)

@Serializable
data class AndroidOverrides(
  val curveStyle: String? = null,
  val pointRadius: Double? = null
)

typealias ChartRow = Map<String, JsonElement>
