import XCTest
@testable import ChartCNMobile

final class APIAdapterTests: XCTestCase {
    func testFetchRowsAggregatesPagesUsingQueryCursor() async throws {
        let requestStore = APIRequestStore()
        let adapter = APIAdapter { request in
            await requestStore.append(request)

            switch request.pageIndex {
            case 0:
                return APIPageResponse(
                    payload: try decodeChartValue("""
                    {
                      "data": [{ "day": "2026-02-01", "value": 10 }],
                      "pagination": { "nextCursor": "token_2" }
                    }
                    """)
                )
            case 1:
                return APIPageResponse(
                    payload: try decodeChartValue("""
                    {
                      "data": [{ "day": "2026-02-02", "value": 12 }],
                      "pagination": { "nextCursor": null }
                    }
                    """)
                )
            default:
                XCTFail("Unexpected page index \(request.pageIndex)")
                return APIPageResponse(payload: .array([]))
            }
        }

        let source = try apiSource(
            method: "GET",
            dataPath: "data",
            queryJSON: #"{ "accountId": "acct_1" }"#
        )

        let rows = try await adapter.fetchRows(from: source)
        let requests = await requestStore.snapshot()

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0]["day"]?.stringValue, "2026-02-01")
        XCTAssertEqual(rows[1]["value"]?.doubleValue, 12)

        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].query["accountId"]?.stringValue, "acct_1")
        XCTAssertNil(requests[0].query["cursor"])
        XCTAssertEqual(requests[1].query["cursor"]?.stringValue, "token_2")
    }

    func testFetchRowsSupportsBodyCursorAndMaxPages() async throws {
        let requestStore = APIRequestStore()
        let adapter = APIAdapter { request in
            await requestStore.append(request)
            return APIPageResponse(
                payload: try decodeChartValue("""
                {
                  "rows": [{ "idx": \(request.pageIndex + 1) }],
                  "meta": { "next": "cursor_\(request.pageIndex + 1)" }
                }
                """)
            )
        }

        let source = try apiSource(
            method: "POST",
            dataPath: "rows",
            bodyJSON: #"{ "scope": "monthly" }"#
        )

        let rows = try await adapter.fetchRows(
            from: source,
            pagination: .init(
                cursorParameter: "cursor",
                nextCursorPath: "meta.next",
                maxPages: 2,
                maxRows: 100,
                cursorLocation: .body
            )
        )
        let requests = await requestStore.snapshot()

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0]["idx"]?.doubleValue, 1)
        XCTAssertEqual(rows[1]["idx"]?.doubleValue, 2)

        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].body["scope"]?.stringValue, "monthly")
        XCTAssertNil(requests[0].body["cursor"])
        XCTAssertEqual(requests[1].body["cursor"]?.stringValue, "cursor_1")
    }

    func testRejectsNonAPISource() async throws {
        let source = try nonAPISource()
        let adapter = APIAdapter { _ in
            XCTFail("Fetcher should not be called for non-api source.")
            return APIPageResponse(payload: .array([]))
        }

        do {
            _ = try await adapter.fetchRows(from: source)
            XCTFail("Expected invalidSpec error.")
        } catch let error as ChartRuntimeError {
            switch error {
            case .invalidSpec(let message):
                XCTAssertTrue(message.contains("adapter"))
            default:
                XCTFail("Unexpected runtime error: \(error)")
            }
        }
    }
}

private actor APIRequestStore {
    private var requests: [APIPageRequest] = []

    func append(_ request: APIPageRequest) {
        requests.append(request)
    }

    func snapshot() -> [APIPageRequest] {
        requests
    }
}

private func apiSource(
    method: String,
    dataPath: String,
    queryJSON: String = "{}",
    bodyJSON: String = "{}"
) throws -> ChartSpec.Source {
    let json = """
    {
      "specVersion": "1.1.0",
      "id": "api.test",
      "metadata": {
        "name": "API Test",
        "status": "stable",
        "owners": ["team"]
      },
      "data": {
        "source": {
          "adapter": "api",
          "endpoint": "https://api.example.com/data",
          "method": "\(method)",
          "query": \(queryJSON),
          "body": \(bodyJSON),
          "dataPath": "\(dataPath)"
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
        "chartTitle": "API chart",
        "summaryTemplate": "Summary"
      }
    }
    """

    let spec = try ChartSpecLoader.load(from: Data(json.utf8))
    return spec.data.source
}

private func nonAPISource() throws -> ChartSpec.Source {
    let json = """
    {
      "specVersion": "1.1.0",
      "id": "static.test",
      "metadata": {
        "name": "Static Test",
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
        "chartTitle": "Static chart",
        "summaryTemplate": "Summary"
      }
    }
    """

    let spec = try ChartSpecLoader.load(from: Data(json.utf8))
    return spec.data.source
}

private func decodeChartValue(_ raw: String) throws -> ChartValue {
    let data = Data(raw.utf8)
    return try JSONDecoder().decode(ChartValue.self, from: data)
}
