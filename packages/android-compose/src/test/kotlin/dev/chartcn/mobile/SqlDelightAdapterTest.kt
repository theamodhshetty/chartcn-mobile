package dev.chartcn.mobile

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

class SqlDelightAdapterTest {
  @Test
  fun fetchRowsConvertsPrimitiveAndNestedValues() {
    val adapter = SqlDelightAdapter { queryName, args ->
      assertEquals("RevenueQueries.byAccount", queryName)
      assertEquals(JsonPrimitive("acct_123"), args["accountId"])

      listOf(
        mapOf(
          "day" to "2026-02-01",
          "revenue" to 1200.5,
          "active" to true,
          "tags" to listOf("paid", "mobile"),
          "meta" to mapOf("region" to "us")
        )
      )
    }

    val rows = adapter.fetchRows(
      queryName = "RevenueQueries.byAccount",
      args = mapOf("accountId" to JsonPrimitive("acct_123"))
    )

    val row = rows.first()
    assertEquals(JsonPrimitive("2026-02-01"), row["day"])
    assertEquals(JsonPrimitive(1200.5), row["revenue"])
    assertEquals(JsonPrimitive(true), row["active"])
    assertEquals(
      JsonArray(listOf(JsonPrimitive("paid"), JsonPrimitive("mobile"))),
      row["tags"]
    )
    assertEquals(
      JsonObject(mapOf("region" to JsonPrimitive("us"))),
      row["meta"]
    )
  }

  @Test
  fun fetchRowsRejectsUnsafeQueryName() {
    val adapter = SqlDelightAdapter { _, _ -> emptyList() }

    assertFailsWith<IllegalArgumentException> {
      adapter.fetchRows("RevenueQueries.byAccount; DROP TABLE metrics")
    }
  }

  @Test
  fun fetchRowsFromSourceUsesSqldelightArgsObject() {
    val source = Source(
      adapter = Adapter.SQLDELIGHT,
      queryName = "RevenueQueries.byAccount",
      args = JsonObject(
        mapOf(
          "accountId" to JsonPrimitive("acct_321"),
          "windowDays" to JsonPrimitive(14)
        )
      )
    )

    val adapter = SqlDelightAdapter { queryName, args ->
      assertEquals("RevenueQueries.byAccount", queryName)
      assertEquals(JsonPrimitive("acct_321"), args["accountId"])
      assertEquals(JsonPrimitive(14), args["windowDays"])
      listOf(mapOf("day" to "2026-02-14", "revenue" to 820.0))
    }

    val rows = adapter.fetchRows(source)
    assertEquals(JsonPrimitive(820.0), rows.first()["revenue"])
  }
}
