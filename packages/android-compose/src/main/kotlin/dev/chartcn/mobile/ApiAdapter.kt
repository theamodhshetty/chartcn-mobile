package dev.chartcn.mobile

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull

enum class ApiCursorLocation {
  QUERY,
  BODY
}

data class ApiPaginationConfig(
  val cursorParamName: String = "cursor",
  val nextCursorPath: String = "pagination.nextCursor",
  val maxPages: Int = 20,
  val maxRows: Int = 5000,
  val cursorLocation: ApiCursorLocation = ApiCursorLocation.QUERY
)

data class ApiPageRequest(
  val source: Source,
  val pageIndex: Int,
  val cursor: String?,
  val query: Map<String, JsonElement>,
  val body: Map<String, JsonElement>
)

data class ApiPageResponse(
  val payload: JsonElement,
  val nextCursor: String? = null
)

fun interface ApiPageFetcher {
  fun fetch(request: ApiPageRequest): ApiPageResponse
}

class ApiAdapter(private val fetcher: ApiPageFetcher) {
  fun fetchRows(
    source: Source,
    pagination: ApiPaginationConfig = ApiPaginationConfig()
  ): List<ChartRow> {
    require(source.adapter == Adapter.API) {
      "Source adapter must be 'api'."
    }
    require(!source.endpoint.isNullOrBlank()) {
      "api source requires a non-empty endpoint."
    }
    require(!source.method.isNullOrBlank()) {
      "api source requires a non-empty method."
    }
    require(pagination.maxPages > 0) {
      "maxPages must be greater than 0."
    }
    require(pagination.maxRows > 0) {
      "maxRows must be greater than 0."
    }
    require(pagination.cursorParamName.matches(Regex("^[a-zA-Z0-9_.-]+$"))) {
      "cursorParamName contains unsupported characters."
    }

    val rows = mutableListOf<ChartRow>()
    val seenCursors = mutableSetOf<String>()
    var cursor: String? = null
    var pageIndex = 0

    while (pageIndex < pagination.maxPages && rows.size < pagination.maxRows) {
      val query = when (pagination.cursorLocation) {
        ApiCursorLocation.QUERY -> withCursor(source.query, cursor, pagination.cursorParamName)
        ApiCursorLocation.BODY -> source.query
      }
      val body = when (pagination.cursorLocation) {
        ApiCursorLocation.QUERY -> source.body
        ApiCursorLocation.BODY -> withCursor(source.body, cursor, pagination.cursorParamName)
      }

      val response = fetcher.fetch(
        ApiPageRequest(
          source = source,
          pageIndex = pageIndex,
          cursor = cursor,
          query = query,
          body = body
        )
      )

      val pageRows = extractRows(response.payload, source.dataPath)
      if (pageRows.isNotEmpty()) {
        val remaining = pagination.maxRows - rows.size
        rows.addAll(pageRows.take(remaining))
      }

      val nextCursor = response.nextCursor?.takeIf { it.isNotBlank() }
        ?: extractStringAtPath(response.payload, pagination.nextCursorPath)

      if (nextCursor == null || pageRows.isEmpty()) {
        break
      }

      if (!seenCursors.add(nextCursor)) {
        break
      }

      cursor = nextCursor
      pageIndex += 1
    }

    return rows
  }
}

private fun withCursor(
  base: Map<String, JsonElement>,
  cursor: String?,
  paramName: String
): Map<String, JsonElement> {
  if (cursor.isNullOrBlank()) return base
  return base + (paramName to JsonPrimitive(cursor))
}

private fun extractRows(
  payload: JsonElement,
  dataPath: String?
): List<ChartRow> {
  val target = payload.valueAtPath(dataPath)
  return when (target) {
    is JsonArray -> target.mapNotNull { entry ->
      (entry as? JsonObject)?.toMap()
    }
    is JsonObject -> listOf(target.toMap())
    else -> emptyList()
  }
}

private fun extractStringAtPath(
  payload: JsonElement,
  path: String
): String? {
  val value = payload.valueAtPath(path) as? JsonPrimitive ?: return null
  return value.contentOrNull?.takeIf { it.isNotBlank() }
}

private fun JsonElement?.valueAtPath(path: String?): JsonElement? {
  if (this == null) return null
  if (path.isNullOrBlank()) return this

  val parts = path.split(".").filter { it.isNotBlank() }
  if (parts.isEmpty()) return this

  var current: JsonElement = this
  for (part in parts) {
    current = when (current) {
      is JsonObject -> current[part] ?: return null
      is JsonArray -> {
        val index = part.toIntOrNull() ?: return null
        current.getOrNull(index) ?: return null
      }
      else -> return null
    }
  }
  return current
}
