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

    public static func optimizeForViewport(
        points: [ChartPoint],
        chartType: ChartType,
        seriesOrder: [String]
    ) -> [ChartPoint] {
        guard !points.isEmpty else {
            return []
        }

        let limits = viewportLimits(for: chartType)
        var buckets = bucketize(points)

        if buckets.count > limits.window {
            buckets = Array(buckets.suffix(limits.window))
        }

        if buckets.count > limits.sample {
            buckets = sampleBuckets(buckets, targetCount: limits.sample)
        }

        let order = Dictionary(uniqueKeysWithValues: seriesOrder.enumerated().map { ($0.element, $0.offset) })
        var optimized: [ChartPoint] = []
        optimized.reserveCapacity(buckets.reduce(0) { $0 + $1.points.count })

        for (index, bucket) in buckets.enumerated() {
            let sortedPoints = bucket.points.sorted { left, right in
                let lRank = order[left.seriesField] ?? Int.max
                let rRank = order[right.seriesField] ?? Int.max
                if lRank != rRank {
                    return lRank < rRank
                }
                return left.seriesField < right.seriesField
            }

            for point in sortedPoints {
                optimized.append(
                    ChartPoint(
                        xIndex: index,
                        xLabel: bucket.xLabel,
                        yValue: point.yValue,
                        seriesField: point.seriesField,
                        seriesLabel: point.seriesLabel
                    )
                )
            }
        }

        return optimized
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

    private static func viewportLimits(for chartType: ChartType) -> (window: Int, sample: Int) {
        switch chartType {
        case .line, .area, .scatter, .combo:
            return (window: 420, sample: 180)
        case .bar:
            return (window: 260, sample: 140)
        case .pie, .donut, .kpi:
            return (window: Int.max, sample: Int.max)
        }
    }

    private static func bucketize(_ points: [ChartPoint]) -> [Bucket] {
        var grouped: [Int: [ChartPoint]] = [:]
        grouped.reserveCapacity(points.count)

        for point in points {
            grouped[point.xIndex, default: []].append(point)
        }

        let sortedIndexes = grouped.keys.sorted()
        return sortedIndexes.map { index in
            let items = grouped[index] ?? []
            let label = items.first?.xLabel ?? ""
            return Bucket(sourceIndex: index, xLabel: label, points: items)
        }
    }

    private static func sampleBuckets(_ buckets: [Bucket], targetCount: Int) -> [Bucket] {
        guard targetCount > 1, buckets.count > targetCount else {
            return buckets
        }

        let step = Double(buckets.count - 1) / Double(targetCount - 1)
        var sampled: [Bucket] = []
        sampled.reserveCapacity(targetCount)

        for i in 0..<targetCount {
            let raw = Double(i) * step
            let idx = min(buckets.count - 1, Int(raw))
            sampled.append(buckets[idx])
        }

        return sampled
    }
}

private struct Bucket {
    let sourceIndex: Int
    let xLabel: String
    let points: [ChartPoint]
}
