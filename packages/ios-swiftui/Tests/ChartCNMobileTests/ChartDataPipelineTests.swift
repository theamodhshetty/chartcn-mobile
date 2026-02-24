import XCTest
@testable import ChartCNMobile

final class ChartDataPipelineTests: XCTestCase {
    func testConvertsRowsToPoints() throws {
        let json = """
        {
          "specVersion": "1.1.0",
          "id": "kpi.test",
          "metadata": {
            "name": "Test",
            "status": "stable",
            "owners": ["team"]
          },
          "data": {
            "source": { "adapter": "static", "rows": [] },
            "dimensions": [{ "key": "date", "type": "time", "label": "Date" }],
            "measures": [{ "key": "revenue", "type": "number", "label": "Revenue" }]
          },
          "visual": {
            "chartType": "line",
            "xField": "date",
            "series": [{ "field": "revenue", "label": "Revenue" }]
          },
          "accessibility": {
            "chartTitle": "Revenue chart",
            "summaryTemplate": "Summary"
          }
        }
        """.data(using: .utf8)!

        let spec = try ChartSpecLoader.load(from: json)
        let rows: [ChartRow] = [
            ["date": .string("2026-01-01"), "revenue": .number(1200)],
            ["date": .string("2026-01-02"), "revenue": .number(1300)]
        ]

        let points = ChartDataPipeline.points(from: spec, rows: rows)

        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points.first?.xIndex, 0)
        XCTAssertEqual(points.first?.xLabel, "2026-01-01")
        XCTAssertEqual(points.first?.yValue, 1200)
    }

    func testViewportOptimizationAppliesWindowingAndDownsampling() throws {
        let json = """
        {
          "specVersion": "1.1.0",
          "id": "kpi.test",
          "metadata": {
            "name": "Test",
            "status": "stable",
            "owners": ["team"]
          },
          "data": {
            "source": { "adapter": "static", "rows": [] },
            "dimensions": [{ "key": "date", "type": "time", "label": "Date" }],
            "measures": [{ "key": "revenue", "type": "number", "label": "Revenue" }]
          },
          "visual": {
            "chartType": "line",
            "xField": "date",
            "series": [{ "field": "revenue", "label": "Revenue" }]
          },
          "accessibility": {
            "chartTitle": "Revenue chart",
            "summaryTemplate": "Summary"
          }
        }
        """.data(using: .utf8)!

        let spec = try ChartSpecLoader.load(from: json)
        let rows: [ChartRow] = (0..<1000).map { index in
            [
                "date": .string("2026-01-\(index)"),
                "revenue": .number(Double(index))
            ]
        }

        let points = ChartDataPipeline.points(from: spec, rows: rows)
        let optimized = ChartDataPipeline.optimizeForViewport(
            points: points,
            chartType: .line,
            seriesOrder: ["revenue"]
        )

        XCTAssertEqual(points.count, 1000)
        XCTAssertLessThanOrEqual(optimized.count, 180)
        XCTAssertEqual(optimized.first?.xIndex, 0)
        XCTAssertEqual(optimized.last?.xLabel, "2026-01-999")
    }
}
