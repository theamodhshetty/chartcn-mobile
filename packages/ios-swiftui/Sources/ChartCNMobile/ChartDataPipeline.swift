import Foundation

public struct ChartPoint: Identifiable, Sendable {
    public let id = UUID()
    public let xLabel: String
    public let yValue: Double
    public let seriesField: String
    public let seriesLabel: String
}

public enum ChartDataPipeline {
    public static func points(from spec: ChartSpec, rows: [ChartRow]) -> [ChartPoint] {
        let xField = spec.visual.xField

        return rows.flatMap { row in
            spec.visual.series.compactMap { series in
                guard let y = row[series.field]?.doubleValue else {
                    return nil
                }

                let label: String
                if let xField, let xValue = row[xField] {
                    switch xValue {
                    case .string(let value):
                        label = value
                    case .number(let value):
                        label = String(value)
                    case .bool(let value):
                        label = String(value)
                    case .null:
                        label = ""
                    }
                } else {
                    label = ""
                }

                return ChartPoint(
                    xLabel: label,
                    yValue: y,
                    seriesField: series.field,
                    seriesLabel: series.label
                )
            }
        }
    }
}
