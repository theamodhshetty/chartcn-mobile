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
}
