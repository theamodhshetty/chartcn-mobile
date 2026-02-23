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
                VStack(alignment: .leading, spacing: 6) {
                    Text(spec.visual.emptyState?.title ?? "No Data")
                        .font(.subheadline)
                    if let description = spec.visual.emptyState?.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                chartBody
                    .frame(minHeight: 220)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(spec.accessibility.chartTitle))
        .accessibilityHint(Text(spec.accessibility.summaryTemplate))
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

    private var lineChart: some View {
        Chart(points) { point in
            LineMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(color(forSeriesField: point.seriesField))
            .lineStyle(.init(lineWidth: lineWidth(forSeriesField: point.seriesField)))

            PointMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(color(forSeriesField: point.seriesField))
        }
    }

    private var barChart: some View {
        Chart(points) { point in
            BarMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(color(forSeriesField: point.seriesField))
        }
    }

    private var areaChart: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(color(forSeriesField: point.seriesField).opacity(0.25))

            LineMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(color(forSeriesField: point.seriesField))
        }
    }

    private var scatterChart: some View {
        Chart(points) { point in
            PointMark(
                x: .value("X", point.xLabel),
                y: .value("Y", point.yValue)
            )
            .foregroundStyle(color(forSeriesField: point.seriesField))
        }
    }

    private var comboChart: some View {
        Chart(points) { point in
            if let renderer = spec.visual.series.first(where: { $0.field == point.seriesField })?.renderer,
               renderer == "bar" {
                BarMark(
                    x: .value("X", point.xLabel),
                    y: .value("Y", point.yValue)
                )
                .foregroundStyle(color(forSeriesField: point.seriesField))
            } else {
                LineMark(
                    x: .value("X", point.xLabel),
                    y: .value("Y", point.yValue)
                )
                .foregroundStyle(color(forSeriesField: point.seriesField))
                .lineStyle(.init(lineWidth: lineWidth(forSeriesField: point.seriesField)))
            }
        }
    }

    private func pieChart(innerRadiusRatio: Double) -> some View {
        let firstSeries = spec.visual.series.first
        let dimensionKey = spec.data.dimensions.first?.key

        let slices: [(label: String, value: Double, field: String)] = rows.compactMap { row in
            guard
                let seriesField = firstSeries?.field,
                let value = row[seriesField]?.doubleValue
            else {
                return nil
            }

            let label: String
            if let dimensionKey, let dim = row[dimensionKey] {
                label = dim.stringValue ?? ""
            } else {
                label = firstSeries?.label ?? "Slice"
            }

            return (label, value, seriesField)
        }

        let enumeratedSlices = Array(slices.enumerated())

        return Chart(enumeratedSlices, id: \.offset) { item in
            let slice = item.element
            SectorMark(
                angle: .value("Value", max(slice.value, 0)),
                innerRadius: .ratio(innerRadiusRatio)
            )
            .foregroundStyle(color(forSeriesField: slice.field))
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

    private func formatted(_ value: Double?) -> String {
        guard let value else { return "--" }

        if let currencyCode = spec.formatting?.currency?.code {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            if let maximumFractionDigits = spec.formatting?.number?.maximumFractionDigits {
                formatter.maximumFractionDigits = maximumFractionDigits
            }
            return formatter.string(from: NSNumber(value: value)) ?? String(value)
        }

        return String(format: "%.2f", value)
    }

    private func lineWidth(forSeriesField field: String) -> CGFloat {
        let width = spec.visual.series
            .first(where: { $0.field == field })?
            .style?
            .lineWidth
        return CGFloat(width ?? 2)
    }

    private func color(forSeriesField field: String) -> Color {
        let raw = spec.visual.series
            .first(where: { $0.field == field })?
            .style?
            .color

        if let raw,
           let resolved = resolveColor(raw) {
            return resolved
        }

        return .blue
    }

    private func resolveColor(_ tokenOrHex: String) -> Color? {
        if tokenOrHex.hasPrefix("token."),
           let tokenValue = spec.theming?.tokens?[tokenOrHex] {
            return Color(hex: tokenValue)
        }

        return Color(hex: tokenOrHex)
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
