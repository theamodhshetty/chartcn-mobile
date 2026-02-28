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

    func testLoadsSqldelightArgsObject() throws {
        let json = """
        {
          "specVersion": "1.1.0",
          "id": "sqldelight.test",
          "metadata": {
            "name": "SQLDelight Test",
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
            "chartTitle": "Test chart",
            "summaryTemplate": "Summary"
          }
        }
        """.data(using: .utf8)!

        let spec = try ChartSpecLoader.load(from: json)
        XCTAssertEqual(spec.data.source.adapter, .sqldelight)
        XCTAssertEqual(spec.data.source.queryName, "RevenueQueries.byAccount")

        guard let args = spec.data.source.args?.objectValue else {
            XCTFail("Expected sqldelight args object")
            return
        }

        XCTAssertEqual(args["accountId"]?.stringValue, "acct_123")
        XCTAssertEqual(args["windowDays"]?.doubleValue, 30)
    }
}
