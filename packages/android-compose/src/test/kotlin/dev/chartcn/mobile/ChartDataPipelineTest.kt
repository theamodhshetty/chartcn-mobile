package dev.chartcn.mobile

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlinx.serialization.json.JsonPrimitive

class ChartDataPipelineTest {
  @Test
  fun pointsExtractedFromRows() {
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
    val rows = listOf(
      mapOf("day" to JsonPrimitive("Mon"), "value" to JsonPrimitive(10.0)),
      mapOf("day" to JsonPrimitive("Tue"), "value" to JsonPrimitive(15.5))
    )

    val points = ChartDataPipeline.points(spec, rows)

    assertEquals(2, points.size)
    assertEquals(0, points.first().xIndex)
    assertEquals("Mon", points.first().xLabel)
    assertEquals(10.0, points.first().yValue)
  }

  @Test
  fun viewportOptimizationAppliesWindowingAndDownsampling() {
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
    val rows = (0 until 1000).map { index ->
      mapOf("day" to JsonPrimitive("d$index"), "value" to JsonPrimitive(index.toDouble()))
    }

    val points = ChartDataPipeline.points(spec, rows)
    val optimized = ChartDataPipeline.optimizeForViewport(
      points = points,
      chartType = ChartType.LINE,
      seriesOrder = listOf("value")
    )

    assertEquals(1000, points.size)
    assertTrue(optimized.size <= 180)
    assertEquals(0, optimized.first().xIndex)
    assertEquals("d999", optimized.last().xLabel)
  }
}
