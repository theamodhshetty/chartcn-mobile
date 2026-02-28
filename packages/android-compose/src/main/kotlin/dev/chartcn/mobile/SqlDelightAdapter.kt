package dev.chartcn.mobile

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

fun interface SqlDelightQueryExecutor {
  fun execute(
    queryName: String,
    args: Map<String, JsonElement>
  ): List<Map<String, Any?>>
}

class SqlDelightAdapter(private val executor: SqlDelightQueryExecutor) {
  fun fetchRows(
    queryName: String,
    args: Map<String, JsonElement> = emptyMap()
  ): List<ChartRow> {
    require(queryName.matches(Regex("^[a-zA-Z0-9_.]+$"))) {
      "Unsafe query name."
    }

    return executor.execute(queryName, args).map { row ->
      row.mapValues { (_, value) -> value.toJsonElement() }
    }
  }

  fun fetchRows(source: Source): List<ChartRow> {
    require(source.adapter == Adapter.SQLDELIGHT) {
      "Source adapter must be 'sqldelight'."
    }
    val queryName = source.queryName?.takeIf { it.isNotBlank() }
      ?: error("sqldelight source is missing queryName.")
    val args = source.args.asJsonObject()
    return fetchRows(queryName, args)
  }
}

private fun JsonElement?.asJsonObject(): Map<String, JsonElement> {
  return (this as? JsonObject)?.toMap() ?: emptyMap()
}

private fun Any?.toJsonElement(): JsonElement {
  return when (this) {
    null -> JsonNull
    is JsonElement -> this
    is String -> JsonPrimitive(this)
    is Number -> JsonPrimitive(this)
    is Boolean -> JsonPrimitive(this)
    is Enum<*> -> JsonPrimitive(this.name)
    is Map<*, *> -> {
      val pairs = this.entries.mapNotNull { entry ->
        val key = entry.key as? String ?: return@mapNotNull null
        key to entry.value.toJsonElement()
      }
      JsonObject(pairs.toMap())
    }
    is Iterable<*> -> JsonArray(this.map { it.toJsonElement() })
    is Array<*> -> JsonArray(this.map { it.toJsonElement() })
    else -> JsonPrimitive(this.toString())
  }
}
