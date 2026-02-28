import Foundation

public enum APICursorLocation: Sendable {
    case query
    case body
}

public struct APIPaginationOptions: Sendable {
    public let cursorParameter: String
    public let nextCursorPath: String
    public let maxPages: Int
    public let maxRows: Int
    public let cursorLocation: APICursorLocation

    public init(
        cursorParameter: String = "cursor",
        nextCursorPath: String = "pagination.nextCursor",
        maxPages: Int = 20,
        maxRows: Int = 5000,
        cursorLocation: APICursorLocation = .query
    ) {
        self.cursorParameter = cursorParameter
        self.nextCursorPath = nextCursorPath
        self.maxPages = maxPages
        self.maxRows = maxRows
        self.cursorLocation = cursorLocation
    }
}

public struct APIPageRequest: Sendable {
    public let source: ChartSpec.Source
    public let pageIndex: Int
    public let cursor: String?
    public let query: [String: ChartValue]
    public let body: [String: ChartValue]
}

public struct APIPageResponse: Sendable {
    public let payload: ChartValue
    public let nextCursor: String?

    public init(payload: ChartValue, nextCursor: String? = nil) {
        self.payload = payload
        self.nextCursor = nextCursor
    }
}

public typealias APIPageFetcher = @Sendable (APIPageRequest) async throws -> APIPageResponse

public final class APIAdapter {
    private let fetchPage: APIPageFetcher

    public init(fetchPage: @escaping APIPageFetcher) {
        self.fetchPage = fetchPage
    }

    public func fetchRows(
        from source: ChartSpec.Source,
        pagination: APIPaginationOptions = .init()
    ) async throws -> [ChartRow] {
        guard source.adapter == .api else {
            throw ChartRuntimeError.invalidSpec("Source adapter must be 'api'.")
        }
        guard let endpoint = source.endpoint?.trimmingCharacters(in: .whitespacesAndNewlines), !endpoint.isEmpty else {
            throw ChartRuntimeError.invalidSpec("api source requires a non-empty endpoint.")
        }
        guard let method = source.method?.trimmingCharacters(in: .whitespacesAndNewlines), !method.isEmpty else {
            throw ChartRuntimeError.invalidSpec("api source requires a non-empty method.")
        }
        guard pagination.maxPages > 0 else {
            throw ChartRuntimeError.invalidSpec("maxPages must be greater than 0.")
        }
        guard pagination.maxRows > 0 else {
            throw ChartRuntimeError.invalidSpec("maxRows must be greater than 0.")
        }
        guard pagination.cursorParameter.range(of: "^[a-zA-Z0-9_.-]+$", options: .regularExpression) != nil else {
            throw ChartRuntimeError.invalidSpec("cursorParameter contains unsupported characters.")
        }

        var rows: [ChartRow] = []
        var seenCursors = Set<String>()
        var cursor: String?
        var pageIndex = 0

        while pageIndex < pagination.maxPages, rows.count < pagination.maxRows {
            let baseQuery = source.query ?? [:]
            let baseBody = source.body ?? [:]
            let query: [String: ChartValue]
            let body: [String: ChartValue]

            switch pagination.cursorLocation {
            case .query:
                query = withCursor(base: baseQuery, cursor: cursor, parameter: pagination.cursorParameter)
                body = baseBody
            case .body:
                query = baseQuery
                body = withCursor(base: baseBody, cursor: cursor, parameter: pagination.cursorParameter)
            }

            let request = APIPageRequest(
                source: source.with(endpoint: endpoint, method: method),
                pageIndex: pageIndex,
                cursor: cursor,
                query: query,
                body: body
            )
            let response = try await fetchPage(request)
            let pageRows = extractRows(from: response.payload, dataPath: source.dataPath)

            if !pageRows.isEmpty {
                let remaining = max(0, pagination.maxRows - rows.count)
                rows.append(contentsOf: pageRows.prefix(remaining))
            }

            let nextCursor = normalizedCursor(response.nextCursor)
                ?? extractCursor(from: response.payload, path: pagination.nextCursorPath)

            if nextCursor == nil || pageRows.isEmpty {
                break
            }

            guard let unwrappedCursor = nextCursor, seenCursors.insert(unwrappedCursor).inserted else {
                break
            }

            cursor = unwrappedCursor
            pageIndex += 1
        }

        return rows
    }
}

private func withCursor(
    base: [String: ChartValue],
    cursor: String?,
    parameter: String
) -> [String: ChartValue] {
    guard let cursor = normalizedCursor(cursor) else {
        return base
    }
    var next = base
    next[parameter] = .string(cursor)
    return next
}

private func extractRows(
    from payload: ChartValue,
    dataPath: String?
) -> [ChartRow] {
    guard let target = value(atPath: dataPath, in: payload) else {
        return []
    }

    switch target {
    case .array(let values):
        return values.compactMap { value in
            guard case .object(let row) = value else { return nil }
            return row
        }
    case .object(let row):
        return [row]
    default:
        return []
    }
}

private func extractCursor(
    from payload: ChartValue,
    path: String
) -> String? {
    guard let value = value(atPath: path, in: payload) else {
        return nil
    }

    switch value {
    case .string(let text):
        return normalizedCursor(text)
    case .number(let number):
        return normalizedCursor(String(number))
    case .bool(let flag):
        return normalizedCursor(String(flag))
    default:
        return nil
    }
}

private func value(atPath path: String?, in root: ChartValue) -> ChartValue? {
    guard let path, !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return root
    }

    var current: ChartValue = root
    let parts = path.split(separator: ".").map(String.init).filter { !$0.isEmpty }

    for part in parts {
        switch current {
        case .object(let object):
            guard let next = object[part] else {
                return nil
            }
            current = next
        case .array(let values):
            guard let index = Int(part), values.indices.contains(index) else {
                return nil
            }
            current = values[index]
        default:
            return nil
        }
    }

    return current
}

private func normalizedCursor(_ cursor: String?) -> String? {
    guard let value = cursor?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
        return nil
    }
    return value
}

private extension ChartSpec.Source {
    func with(endpoint: String, method: String) -> ChartSpec.Source {
        .init(
            adapter: adapter,
            entity: entity,
            predicate: predicate,
            sort: sort,
            limit: limit,
            table: table,
            where: `where`,
            args: args,
            orderBy: orderBy,
            queryName: queryName,
            endpoint: endpoint,
            method: method,
            headers: headers,
            query: query,
            body: body,
            dataPath: dataPath,
            rows: rows
        )
    }
}
