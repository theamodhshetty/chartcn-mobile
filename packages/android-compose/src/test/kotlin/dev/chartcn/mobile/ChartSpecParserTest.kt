package dev.chartcn.mobile

import kotlin.test.Test
import kotlin.test.assertEquals

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
}
