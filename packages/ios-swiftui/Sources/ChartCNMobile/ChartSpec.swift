import Foundation

public enum ChartType: String, Codable, Sendable {
    case line
    case bar
    case area
    case pie
    case donut
    case scatter
    case combo
    case kpi
}

public enum ChartAdapterType: String, Codable, Sendable {
    case swiftdata
    case room
    case sqldelight
    case api
    case `static`
}

public enum ChartValue: Codable, Sendable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([ChartValue])
    case object([String: ChartValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }

        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
            return
        }

        if let number = try? container.decode(Double.self) {
            self = .number(number)
            return
        }

        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }

        if let array = try? container.decode([ChartValue].self) {
            self = .array(array)
            return
        }

        if let object = try? container.decode([String: ChartValue].self) {
            self = .object(object)
            return
        }

        throw DecodingError.typeMismatch(
            ChartValue.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported ChartValue type")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var doubleValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    public var arrayValue: [ChartValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    public var objectValue: [String: ChartValue]? {
        if case .object(let value) = self { return value }
        return nil
    }
}

public typealias ChartRow = [String: ChartValue]

public struct ChartSpec: Codable, Sendable {
    public let specVersion: String
    public let id: String
    public let metadata: Metadata
    public let data: DataConfig
    public let visual: VisualConfig
    public let formatting: Formatting?
    public let interactions: Interactions?
    public let theming: Theming?
    public let accessibility: Accessibility
    public let platformOverrides: PlatformOverrides?

    public struct Metadata: Codable, Sendable {
        public let name: String
        public let description: String?
        public let tags: [String]?
        public let status: String
        public let owners: [String]
        public let updatedAt: String?
    }

    public struct DataConfig: Codable, Sendable {
        public let source: Source
        public let dimensions: [Dimension]
        public let measures: [Measure]
        public let filters: [Filter]?
        public let transforms: [Transform]?
    }

    public struct Source: Codable, Sendable {
        public let adapter: ChartAdapterType
        public let entity: String?
        public let predicate: String?
        public let sort: [OrderBy]?
        public let limit: Int?

        public let table: String?
        public let `where`: String?
        public let args: ChartValue?
        public let orderBy: [OrderBy]?

        public let queryName: String?

        public let endpoint: String?
        public let method: String?
        public let headers: [String: String]?
        public let query: [String: ChartValue]?
        public let body: [String: ChartValue]?
        public let dataPath: String?

        public let rows: [ChartRow]?
    }

    public struct OrderBy: Codable, Sendable {
        public let field: String
        public let direction: String
    }

    public struct Dimension: Codable, Sendable {
        public let key: String
        public let type: String
        public let label: String
    }

    public struct Measure: Codable, Sendable {
        public let key: String
        public let type: String
        public let label: String
        public let unit: String?
        public let currency: String?
    }

    public struct Filter: Codable, Sendable {
        public let field: String
        public let op: String
        public let value: ChartValue
    }

    public struct Transform: Codable, Sendable {
        public let type: String
        public let by: String?
        public let direction: String?
        public let input: String?
        public let window: Int?
        public let `as`: String?
        public let aggregations: [Aggregation]?

        public struct Aggregation: Codable, Sendable {
            public let field: String
            public let op: String
            public let `as`: String
        }
    }

    public struct VisualConfig: Codable, Sendable {
        public let chartType: ChartType
        public let xField: String?
        public let groupField: String?
        public let stacked: Bool?
        public let series: [Series]
        public let legend: Legend?
        public let axes: Axes?
        public let tooltip: Tooltip?
        public let emptyState: EmptyState?

        public struct Series: Codable, Sendable {
            public let field: String
            public let label: String
            public let renderer: String?
            public let style: Style?

            public struct Style: Codable, Sendable {
                public let color: String?
                public let lineWidth: Double?
                public let dash: [Double]?
                public let opacity: Double?
            }
        }

        public struct Legend: Codable, Sendable {
            public let visible: Bool?
            public let position: String?
        }

        public struct Axes: Codable, Sendable {
            public let x: Axis?
            public let y: Axis?

            public struct Axis: Codable, Sendable {
                public let label: String?
                public let min: Double?
                public let max: Double?
                public let tickCount: Int?
            }
        }

        public struct Tooltip: Codable, Sendable {
            public let enabled: Bool?
            public let mode: String?
        }

        public struct EmptyState: Codable, Sendable {
            public let title: String?
            public let description: String?
        }
    }

    public struct Formatting: Codable, Sendable {
        public let number: NumberFormatting?
        public let currency: CurrencyFormatting?
        public let date: DateFormatting?

        public struct NumberFormatting: Codable, Sendable {
            public let notation: String?
            public let maximumFractionDigits: Int?
        }

        public struct CurrencyFormatting: Codable, Sendable {
            public let code: String?
            public let display: String?
        }

        public struct DateFormatting: Codable, Sendable {
            public let granularity: String?
        }
    }

    public struct Interactions: Codable, Sendable {
        public let selection: String?
        public let drilldown: Drilldown?
        public let gestures: [String]?

        public struct Drilldown: Codable, Sendable {
            public let enabled: Bool?
            public let targetRoute: String?
            public let paramField: String?
        }
    }

    public struct Theming: Codable, Sendable {
        public let palette: String?
        public let tokens: [String: String]?
    }

    public struct Accessibility: Codable, Sendable {
        public let chartTitle: String
        public let summaryTemplate: String
        public let announceOnLoad: Bool?
    }

    public struct PlatformOverrides: Codable, Sendable {
        public let ios: IOSOverrides?
        public let android: AndroidOverrides?

        public struct IOSOverrides: Codable, Sendable {
            public let interpolation: String?
            public let symbolSize: Double?
        }

        public struct AndroidOverrides: Codable, Sendable {
            public let curveStyle: String?
            public let pointRadius: Double?
        }
    }
}
