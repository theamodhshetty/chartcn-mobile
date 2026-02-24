import Foundation

#if canImport(SwiftUI) && canImport(Charts)
import SwiftUI
import Charts

public struct ChartCNView: View {
    private let spec: ChartSpec
    private let rows: [ChartRow]

    public init(spec: ChartSpec, rows: [ChartRow]) {
        self.spec = spec
        self.rows = rows
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(spec.metadata.name)
                .font(.headline)

            if rows.isEmpty {
                emptyStateView
            } else {
                chartBody
                    .frame(minHeight: 220)

                if shouldShowLegend {
                    legendView
                }

                if isCartesianChart, !xAxisLabels.isEmpty {
                    axisLabelRow
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(spec.accessibility.chartTitle))
        .accessibilityHint(Text(spec.accessibility.summaryTemplate))
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(spec.visual.emptyState?.title ?? "No Data")
                .font(.subheadline)
            if let description = spec.visual.emptyState?.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var chartBody: some View {
        switch spec.visual.chartType {
        case .line:
            lineChart
        case .bar:
            barChart
        case .area:
            areaChart
        case .pie, .donut:
            pieChart(innerRadiusRatio: spec.visual.chartType == .donut ? 0.6 : 0.0)
        case .scatter:
            scatterChart
        case .combo:
            comboChart
        case .kpi:
            kpiView
        }
    }

    private var points: [ChartPoint] {
        ChartDataPipeline.points(from: spec, rows: rows)
    }

    private var seriesByField: [String: ChartSpec.VisualConfig.Series] {
        Dictionary(uniqueKeysWithValues: spec.visual.series.map { ($0.field, $0) })
    }

    private var seriesColors: [String: Color] {
        Dictionary(uniqueKeysWithValues: spec.visual.series.enumerated().map { index, series in
            (series.field, resolvedSeriesColor(series, fallbackIndex: index))
        })
    }

    private var isCartesianChart: Bool {
        switch spec.visual.chartType {
        case .line, .bar, .area, .scatter, .combo:
            return true
        case .pie, .donut, .kpi:
            return false
        }
    }

    private var xAxisLabels: [String] {
        guard !points.isEmpty else {
            return []
        }

        let maxIndex = points.map(\.xIndex).max() ?? 0
        var labels = Array(repeating: "", count: maxIndex + 1)

        for point in points where labels[point.xIndex].isEmpty {
            labels[point.xIndex] = point.xLabel
        }

        return labels
    }

    private var lineInterpolation: InterpolationMethod {
        switch spec.platformOverrides?.ios?.interpolation {
        case "monotone":
            return .monotone
        case "catmullRom":
            return .catmullRom
        default:
            return .linear
        }
    }

    private var symbolSize: CGFloat {
        CGFloat(spec.platformOverrides?.ios?.symbolSize ?? 22)
    }

    private var lineChart: some View {
        Chart(points) { point in
            LineMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(seriesColor(forSeriesField: point.seriesField))
            .lineStyle(
                .init(
                    lineWidth: lineWidth(forSeriesField: point.seriesField),
                    dash: lineDash(forSeriesField: point.seriesField)
                )
            )
            .interpolationMethod(lineInterpolation)

            PointMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(seriesColor(forSeriesField: point.seriesField))
            .symbolSize(symbolSize)
        }
    }

    private var barChart: some View {
        Chart(points) { point in
            BarMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(seriesColor(forSeriesField: point.seriesField).opacity(opacity(forSeriesField: point.seriesField)))
        }
    }

    private var areaChart: some View {
        Chart(points) { point in
            let color = seriesColor(forSeriesField: point.seriesField)
            let opacity = opacity(forSeriesField: point.seriesField)

            AreaMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(color.opacity(0.20 * opacity))

            LineMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(color.opacity(opacity))
            .lineStyle(.init(lineWidth: lineWidth(forSeriesField: point.seriesField)))
            .interpolationMethod(lineInterpolation)
        }
    }

    private var scatterChart: some View {
        Chart(points) { point in
            PointMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(seriesColor(forSeriesField: point.seriesField))
            .symbolSize(symbolSize + 4)
        }
    }

    private var comboChart: some View {
        Chart(points) { point in
            let renderer = seriesByField[point.seriesField]?.renderer
            let color = seriesColor(forSeriesField: point.seriesField)

            if renderer == "bar" {
                BarMark(
                    x: .value("X", point.xLabel),
                    y: .value("Y", point.yValue)
                )
                .foregroundStyle(color.opacity(opacity(forSeriesField: point.seriesField)))
            } else {
                LineMark(
                    x: .value("X", point.xLabel),
                    y: .value("Y", point.yValue)
                )
                .foregroundStyle(color)
                .lineStyle(.init(lineWidth: lineWidth(forSeriesField: point.seriesField)))
                .interpolationMethod(lineInterpolation)

                PointMark(
                    x: .value("X", point.xLabel),
                    y: .value("Y", point.yValue)
                )
                .foregroundStyle(color)
                .symbolSize(symbolSize)
            }
        }
    }

    private func pieChart(innerRadiusRatio: Double) -> some View {
        Chart(pieSlices) { slice in
            SectorMark(
                angle: .value("Value", max(slice.value, 0)),
                innerRadius: .ratio(innerRadiusRatio)
            )
            .foregroundStyle(slice.color)
        }
    }

    private var pieSlices: [PieSlice] {
        let firstSeries = spec.visual.series.first
        let dimensionKey = spec.data.dimensions.first?.key

        return rows.enumerated().compactMap { index, row in
            guard
                let seriesField = firstSeries?.field,
                let value = row[seriesField]?.doubleValue,
                value > 0
            else {
                return nil
            }

            let label: String
            if let dimensionKey, let dim = row[dimensionKey] {
                label = dim.stringValue ?? ""
            } else {
                label = "Slice \(index + 1)"
            }

            return PieSlice(
                id: "\(index)-\(label)",
                label: label.isEmpty ? "Slice \(index + 1)" : label,
                value: value,
                color: defaultPalette(index)
            )
        }
    }

    private var kpiView: some View {
        let firstSeries = spec.visual.series.first
        let latest = rows.last?[firstSeries?.field ?? ""]?.doubleValue

        return VStack(alignment: .leading, spacing: 6) {
            Text(firstSeries?.label ?? "KPI")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(formatted(latest))
                .font(.system(size: 34, weight: .bold, design: .rounded))
        }
    }

    private var shouldShowLegend: Bool {
        if spec.visual.legend?.visible == false {
            return false
        }

        switch spec.visual.chartType {
        case .kpi:
            return false
        case .pie, .donut:
            return !pieSlices.isEmpty
        case .line, .bar, .area, .scatter, .combo:
            return spec.visual.series.count > 1
        }
    }

    @ViewBuilder
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if spec.visual.chartType == .pie || spec.visual.chartType == .donut {
                ForEach(pieSlices) { slice in
                    legendItem(label: slice.label, color: slice.color)
                }
            } else {
                ForEach(Array(spec.visual.series.enumerated()), id: \.offset) { index, series in
                    legendItem(
                        label: series.label,
                        color: seriesColors[series.field] ?? defaultPalette(index)
                    )
                }
            }
        }
    }

    private var axisLabelRow: some View {
        let first = xAxisLabels.first ?? ""
        let middle = xAxisLabels[safe: xAxisLabels.count / 2] ?? ""
        let last = xAxisLabels.last ?? ""

        return HStack(spacing: 8) {
            Text(first)
                .frame(maxWidth: .infinity, alignment: .leading)

            if xAxisLabels.count > 2 {
                Text(middle)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if xAxisLabels.count > 1 {
                Text(last)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
        }
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else { return "--" }

        let formatter = NumberFormatter()

        if let currencyCode = spec.formatting?.currency?.code {
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
        } else {
            formatter.numberStyle = .decimal
        }

        if let maximumFractionDigits = spec.formatting?.number?.maximumFractionDigits {
            formatter.maximumFractionDigits = maximumFractionDigits
        }

        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func lineWidth(forSeriesField field: String) -> CGFloat {
        let width = seriesByField[field]?.style?.lineWidth
        return CGFloat(width ?? 2.5)
    }

    private func lineDash(forSeriesField field: String) -> [CGFloat] {
        let raw = seriesByField[field]?.style?.dash ?? []
        return raw.map { CGFloat($0) }
    }

    private func opacity(forSeriesField field: String) -> Double {
        seriesByField[field]?.style?.opacity ?? 1
    }

    private func seriesColor(forSeriesField field: String) -> Color {
        if let color = seriesColors[field] {
            return color
        }

        let fallbackIndex = spec.visual.series.firstIndex(where: { $0.field == field }) ?? 0
        return defaultPalette(fallbackIndex)
    }

    private func resolvedSeriesColor(_ series: ChartSpec.VisualConfig.Series, fallbackIndex: Int) -> Color {
        guard let raw = series.style?.color else {
            return defaultPalette(fallbackIndex)
        }

        if raw.hasPrefix("token."),
           let tokenValue = spec.theming?.tokens?[raw],
           let resolved = Color(hex: tokenValue) {
            return resolved
        }

        return Color(hex: raw) ?? defaultPalette(fallbackIndex)
    }

    private func defaultPalette(_ index: Int) -> Color {
        let palette: [Color] = [
            Color(hex: "#1D4ED8") ?? .blue,
            Color(hex: "#06B6D4") ?? .cyan,
            Color(hex: "#F97316") ?? .orange,
            Color(hex: "#059669") ?? .green,
            Color(hex: "#8B5CF6") ?? .purple
        ]
        return palette[max(0, index) % palette.count]
    }
}

private struct PieSlice: Identifiable {
    let id: String
    let label: String
    let value: Double
    let color: Color
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension Color {
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6 || cleaned.count == 8,
              let value = UInt64(cleaned, radix: 16)
        else {
            return nil
        }

        if cleaned.count == 6 {
            let r = Double((value & 0xFF0000) >> 16) / 255.0
            let g = Double((value & 0x00FF00) >> 8) / 255.0
            let b = Double(value & 0x0000FF) / 255.0
            self = Color(red: r, green: g, blue: b)
        } else {
            let a = Double((value & 0xFF000000) >> 24) / 255.0
            let r = Double((value & 0x00FF0000) >> 16) / 255.0
            let g = Double((value & 0x0000FF00) >> 8) / 255.0
            let b = Double(value & 0x000000FF) / 255.0
            self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
        }
    }
}

#else

public struct ChartsRenderer {
    public init() {}

    public func renderHint(chartType: String) -> String {
        "SwiftUI + Charts unavailable in current toolchain. Requested: \(chartType)"
    }
}

#endif
