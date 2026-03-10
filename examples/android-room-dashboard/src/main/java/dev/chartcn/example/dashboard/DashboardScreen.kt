package dev.chartcn.example.dashboard

import android.content.Context
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import dev.chartcn.mobile.ChartCNView
import dev.chartcn.mobile.ChartRow
import dev.chartcn.mobile.ChartSpec
import dev.chartcn.mobile.ChartSpecParser
import dev.chartcn.mobile.RoomAdapter
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull

@Composable
fun DashboardScreen(
  database: DashboardDatabase,
  modifier: Modifier = Modifier
) {
  val context = LocalContext.current
  var chartSpecs by remember { mutableStateOf<List<ChartSpec>>(emptyList()) }
  var rowsBySpecId by remember { mutableStateOf<Map<String, List<ChartRow>>>(emptyMap()) }
  var errorMessage by remember { mutableStateOf<String?>(null) }

  LaunchedEffect(database) {
    try {
      DashboardSeed.install(database)

      val specs = listOf(
        loadSpec(context, "revenue-kpi"),
        loadSpec(context, "revenue-trend"),
        loadSpec(context, "channel-comparison")
      )
      val adapter = RoomAdapter(database.openHelper.readableDatabase)

      chartSpecs = specs
      rowsBySpecId = specs.associate { spec ->
        spec.id to loadRowsForSpec(adapter, spec)
      }
      errorMessage = null
    } catch (error: Throwable) {
      errorMessage = error.message ?: "Unable to load dashboard."
    }
  }

  LazyColumn(
    modifier = modifier.fillMaxSize(),
    contentPadding = PaddingValues(20.dp),
    verticalArrangement = Arrangement.spacedBy(16.dp)
  ) {
    item {
      Text(
        text = "Executive Dashboard",
        style = MaterialTheme.typography.headlineMedium
      )
    }

    item {
      Text(
        text = "Room-backed charts loaded from asset ChartSpec files.",
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant
      )
    }

    if (errorMessage != null) {
      item {
        Text(
          text = errorMessage.orEmpty(),
          style = MaterialTheme.typography.bodyMedium,
          color = MaterialTheme.colorScheme.error
        )
      }
    }

    items(chartSpecs, key = { it.id }) { spec ->
      Card {
        ChartCNView(
          spec = spec,
          rows = rowsBySpecId[spec.id].orEmpty(),
          modifier = Modifier.padding(8.dp)
        )
      }
    }
  }
}

private fun loadSpec(context: Context, name: String): ChartSpec {
  val raw = context.assets.open("charts/$name.chartspec.json").bufferedReader().use { it.readText() }
  return ChartSpecParser.parse(raw)
}

private fun loadRowsForSpec(
  adapter: RoomAdapter,
  spec: ChartSpec
): List<ChartRow> {
  val source = spec.data.source
  val table = requireNotNull(source.table) {
    "Example dashboard requires room sources with a concrete table."
  }

  return adapter.fetchRows(
    table = table,
    whereClause = source.where,
    args = source.args.asSqlArgs(),
    orderBy = source.orderBy,
    limit = source.limit
  )
}

private fun JsonElement?.asSqlArgs(): List<Any?> {
  val array = this as? JsonArray ?: return emptyList()
  return array.map { value ->
    val primitive = value as? JsonPrimitive ?: return@map null
    when {
      primitive.isString -> primitive.content
      primitive.booleanOrNull != null -> primitive.booleanOrNull
      primitive.longOrNull != null -> primitive.longOrNull
      primitive.doubleOrNull != null -> primitive.doubleOrNull
      else -> primitive.content
    }
  }
}
