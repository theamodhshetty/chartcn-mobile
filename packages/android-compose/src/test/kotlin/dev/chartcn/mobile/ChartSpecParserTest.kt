package dev.chartcn.mobile

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

class ChartSpecParserTest {
  @Test
  fun parseSimpleSpec() {
    val raw = """
      {
        "specVersion": "1.1.0",
        "id": "demo.kpi",
        "metadata": {
          "name": "Demo",
          "status": "stable",
          "owners": ["team"]
        },
        "data": {
          "source": { "adapter": "static", "rows": [] },
          "dimensions": [{ "key": "day", "type": "time", "label": "Day" }],
          "measures": [{ "key": "value", "type": "number", "label": "Value" }]
        },
        "visual": {
          "chartType": "line",
          "xField": "day",
          "series": [{ "field": "value", "label": "Value" }]
        },
        "accessibility": {
          "chartTitle": "Demo chart",
          "summaryTemplate": "Summary"
        }
      }
    """.trimIndent()

    val spec = ChartSpecParser.parse(raw)

    assertEquals("demo.kpi", spec.id)
    assertEquals(ChartType.LINE, spec.visual.chartType)
    assertEquals("value", spec.visual.series.first().field)
  }

  @Test
  fun parseSqldelightSourceWithObjectArgs() {
    val raw = """
      {
        "specVersion": "1.1.0",
        "id": "demo.sqldelight",
        "metadata": {
          "name": "Demo SQLDelight",
          "status": "stable",
          "owners": ["team"]
        },
        "data": {
          "source": {
            "adapter": "sqldelight",
            "queryName": "RevenueQueries.byAccount",
            "args": {
              "accountId": "acct_123",
              "windowDays": 30
            }
          },
          "dimensions": [{ "key": "day", "type": "time", "label": "Day" }],
          "measures": [{ "key": "value", "type": "number", "label": "Value" }]
        },
        "visual": {
          "chartType": "line",
          "xField": "day",
          "series": [{ "field": "value", "label": "Value" }]
        },
        "accessibility": {
          "chartTitle": "Demo chart",
          "summaryTemplate": "Summary"
        }
      }
    """.trimIndent()

    val spec = ChartSpecParser.parse(raw)
    val args = spec.data.source.args as? JsonObject

    assertEquals(Adapter.SQLDELIGHT, spec.data.source.adapter)
    assertEquals("RevenueQueries.byAccount", spec.data.source.queryName)
    assertTrue(args != null)
    assertEquals(JsonPrimitive("acct_123"), args["accountId"])
    assertEquals(JsonPrimitive(30), args["windowDays"])
  }
}
