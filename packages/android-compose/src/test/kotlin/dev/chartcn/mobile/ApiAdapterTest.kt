package dev.chartcn.mobile

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonPrimitive

class ApiAdapterTest {
  @Test
  fun fetchRowsAggregatesPagesUsingQueryCursor() {
    val requests = mutableListOf<ApiPageRequest>()
    val adapter = ApiAdapter { request ->
      requests.add(request)
      when (request.pageIndex) {
        0 -> ApiPageResponse(
          payload = Json.parseToJsonElement(
            """
            {
              "data": [{ "day": "2026-02-01", "value": 10 }],
              "pagination": { "nextCursor": "token_2" }
            }
            """.trimIndent()
          )
        )

        1 -> ApiPageResponse(
          payload = Json.parseToJsonElement(
            """
            {
              "data": [{ "day": "2026-02-02", "value": 12 }],
              "pagination": { "nextCursor": null }
            }
            """.trimIndent()
          )
        )

        else -> error("Unexpected page index ${request.pageIndex}")
      }
    }

    val source = Source(
      adapter = Adapter.API,
      endpoint = "https://api.example.com/revenue",
      method = "GET",
      query = mapOf("accountId" to JsonPrimitive("acct_1")),
      dataPath = "data"
    )

    val rows = adapter.fetchRows(source)

    assertEquals(2, rows.size)
    assertEquals(JsonPrimitive("2026-02-01"), rows[0]["day"])
    assertEquals(JsonPrimitive(12), rows[1]["value"])

    assertEquals(2, requests.size)
    assertEquals(JsonPrimitive("acct_1"), requests[0].query["accountId"])
    assertNull(requests[0].query["cursor"])
    assertEquals(JsonPrimitive("token_2"), requests[1].query["cursor"])
  }

  @Test
  fun fetchRowsSupportsBodyCursorAndMaxPages() {
    val requests = mutableListOf<ApiPageRequest>()
    val adapter = ApiAdapter { request ->
      requests.add(request)
      ApiPageResponse(
        payload = Json.parseToJsonElement(
          """
          {
            "rows": [{ "idx": ${request.pageIndex + 1} }],
            "meta": { "next": "cursor_${request.pageIndex + 1}" }
          }
          """.trimIndent()
        )
      )
    }

    val source = Source(
      adapter = Adapter.API,
      endpoint = "https://api.example.com/summary",
      method = "POST",
      body = mapOf("scope" to JsonPrimitive("monthly")),
      dataPath = "rows"
    )

    val rows = adapter.fetchRows(
      source = source,
      pagination = ApiPaginationConfig(
        cursorLocation = ApiCursorLocation.BODY,
        nextCursorPath = "meta.next",
        maxPages = 2
      )
    )

    assertEquals(2, rows.size)
    assertEquals(JsonPrimitive(1), rows[0]["idx"])
    assertEquals(JsonPrimitive(2), rows[1]["idx"])

    assertEquals(2, requests.size)
    assertEquals(JsonPrimitive("monthly"), requests[0].body["scope"])
    assertNull(requests[0].body["cursor"])
    assertEquals(JsonPrimitive("cursor_1"), requests[1].body["cursor"])
  }
}
