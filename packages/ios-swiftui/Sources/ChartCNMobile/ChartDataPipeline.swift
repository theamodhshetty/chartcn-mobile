import Foundation

public struct ChartPoint: Identifiable, Sendable {
    public let id: String
    public let xIndex: Int
    public let xLabel: String
    public let yValue: Double
    public let seriesField: String
    public let seriesLabel: String

    init(xIndex: Int, xLabel: String, yValue: Double, seriesField: String, seriesLabel: String) {
        self.xIndex = xIndex
        self.xLabel = xLabel
        self.yValue = yValue
        self.seriesField = seriesField
        self.seriesLabel = seriesLabel
        self.id = "\(seriesField)|\(xIndex)|\(xLabel)"
    }
}

public enum ChartDataPipeline {
    public static func points(from spec: ChartSpec, rows: [ChartRow]) -> [ChartPoint] {
        let xField = spec.visual.xField
        let series = spec.visual.series
        if rows.isEmpty || series.isEmpty {
            return []
        }

        var points: [ChartPoint] = []
        points.reserveCapacity(rows.count * series.count)

        for (index, row) in rows.enumerated() {
            let label = xField.flatMap { field in
                row[field].map(label(from:))
            } ?? ""

            for item in series {
                guard let y = row[item.field]?.doubleValue else {
                    continue
                }

                points.append(
                    ChartPoint(
                        xIndex: index,
                        xLabel: label,
                        yValue: y,
                        seriesField: item.field,
                        seriesLabel: item.label
                    )
                )
            }
        }

        return points
    }

    private static func label(from value: ChartValue) -> String {
        switch value {
        case .string(let text):
            return text
        case .number(let number):
            return String(number)
        case .bool(let flag):
            return String(flag)
        case .null:
            return ""
        }
    }
}
