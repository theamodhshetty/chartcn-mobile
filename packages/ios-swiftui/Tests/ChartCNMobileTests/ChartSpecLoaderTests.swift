import XCTest
@testable import ChartCNMobile

final class ChartSpecLoaderTests: XCTestCase {
    func testLoadsTypedSpec() throws {
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
            "measures": [{ "key": "value", "type": "number", "label": "Value" }]
          },
          "visual": {
            "chartType": "line",
            "xField": "date",
            "series": [{ "field": "value", "label": "Value" }]
          },
          "accessibility": {
            "chartTitle": "Test chart",
            "summaryTemplate": "Summary"
          }
        }
        """.data(using: .utf8)!

        let spec = try ChartSpecLoader.load(from: json)
        XCTAssertEqual(spec.id, "kpi.test")
        XCTAssertEqual(spec.visual.chartType, .line)
        XCTAssertEqual(spec.visual.series.first?.field, "value")
    }
}
