import Foundation

#if canImport(SwiftUI) && canImport(Charts)
import SwiftUI
import Charts

public struct ChartCNView: View {
    private let spec: ChartSpec
    private let rows: [ChartRow]

    @State private var selectedXIndex: Int?

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

                if selectionEnabled, let _ = selectedXIndex, !selectedPoints.isEmpty {
                    selectionSummaryView
                }

                if shouldShowLegend {
                    legendView
                }

                if isCartesianChart, !xAxisLabels.isEmpty {
                    axisLabelRow
                }
            }
        }
        .onChange(of: xAxisLabels.count) {
            let count = xAxisLabels.count
            guard let selectedXIndex else { return }
            if selectedXIndex >= count {
                self.selectedXIndex = nil
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

    private var cartesianPoints: [ChartPoint] {
        ChartDataPipeline.optimizeForViewport(
            points: points,
            chartType: spec.visual.chartType,
            seriesOrder: spec.visual.series.map(\.field)
        )
    }

    private var seriesByField: [String: ChartSpec.VisualConfig.Series] {
        Dictionary(uniqueKeysWithValues: spec.visual.series.map { ($0.field, $0) })
    }

    private var seriesOrder: [String: Int] {
        Dictionary(uniqueKeysWithValues: spec.visual.series.enumerated().map { ($0.element.field, $0.offset) })
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

    private var selectionEnabled: Bool {
        guard isCartesianChart else { return false }
        if spec.visual.tooltip?.enabled == false {
            return false
        }
        return spec.interactions?.selection != "none"
    }

    private var xAxisLabels: [String] {
        guard !cartesianPoints.isEmpty else {
            return []
        }

        let maxIndex = cartesianPoints.map(\.xIndex).max() ?? 0
        var labels = Array(repeating: "", count: maxIndex + 1)

        for point in cartesianPoints where labels[point.xIndex].isEmpty {
            labels[point.xIndex] = point.xLabel
        }

        return labels
    }

    private var selectedPoints: [ChartPoint] {
        guard let selectedXIndex else {
            return []
        }

        return cartesianPoints
            .filter { $0.xIndex == selectedXIndex }
            .sorted { left, right in
                let lRank = seriesOrder[left.seriesField] ?? Int.max
                let rRank = seriesOrder[right.seriesField] ?? Int.max
                if lRank != rRank {
                    return lRank < rRank
                }
                return left.seriesField < right.seriesField
            }
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
        cartesianChart {
            Chart(cartesianPoints) { point in
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
                .opacity(markOpacity(forXIndex: point.xIndex))

                PointMark(
                    x: .value("X", point.xLabel),
                    y: .value("Y", point.yValue)
                )
                .foregroundStyle(seriesColor(forSeriesField: point.seriesField))
                .symbolSize(symbolSize)
                .opacity(markOpacity(forXIndex: point.xIndex))
            }
        }
    }

    private var barChart: some View {
        cartesianChart {
            Chart(cartesianPoints) { point in
                BarMark(
                    x: .value("X", point.xLabel),
                    y: .value("Y", point.yValue)
                )
                .foregroundStyle(seriesColor(forSeriesField: point.seriesField).opacity(opacity(forSeriesField: point.seriesField)))
                .opacity(markOpacity(forXIndex: point.xIndex))
            }
        }
    }

    private var areaChart: some View {
        cartesianChart {
            Chart(cartesianPoints) { point in
                let color = seriesColor(forSeriesField: point.seriesField)
                let pointOpacity = markOpacity(forXIndex: point.xIndex)
                let fillOpacity = (0.20 * opacity(forSeriesField: point.seriesField)) * pointOpacity

                AreaMark(
                    x: .value("X", point.xLabel),
                    y: .value("Y", point.yValue)
                )
                .foregroundStyle(color.opacity(fillOpacity))

                LineMark(
                    x: .value("X", point.xLabel),
                    y: .value("Y", point.yValue)
                )
                .foregroundStyle(color.opacity(opacity(forSeriesField: point.seriesField)))
                .lineStyle(.init(lineWidth: lineWidth(forSeriesField: point.seriesField)))
                .interpolationMethod(lineInterpolation)
                .opacity(pointOpacity)
            }
        }
    }

    private var scatterChart: some View {
        cartesianChart {
            Chart(cartesianPoints) { point in
                PointMark(
                    x: .value("X", point.xLabel),
                    y: .value("Y", point.yValue)
                )
                .foregroundStyle(seriesColor(forSeriesField: point.seriesField))
                .symbolSize(symbolSize + 4)
                .opacity(markOpacity(forXIndex: point.xIndex))
            }
        }
    }

    private var comboChart: some View {
        cartesianChart {
            Chart(cartesianPoints) { point in
                let renderer = seriesByField[point.seriesField]?.renderer
                let color = seriesColor(forSeriesField: point.seriesField)
                let pointOpacity = markOpacity(forXIndex: point.xIndex)

                if renderer == "bar" {
                    BarMark(
                        x: .value("X", point.xLabel),
                        y: .value("Y", point.yValue)
                    )
                    .foregroundStyle(color.opacity(opacity(forSeriesField: point.seriesField)))
                    .opacity(pointOpacity)
                } else {
                    LineMark(
                        x: .value("X", point.xLabel),
                        y: .value("Y", point.yValue)
                    )
                    .foregroundStyle(color)
                    .lineStyle(.init(lineWidth: lineWidth(forSeriesField: point.seriesField)))
                    .interpolationMethod(lineInterpolation)
                    .opacity(pointOpacity)

                    PointMark(
                        x: .value("X", point.xLabel),
                        y: .value("Y", point.yValue)
                    )
                    .foregroundStyle(color)
                    .symbolSize(symbolSize)
                    .opacity(pointOpacity)
                }
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

    @ViewBuilder
    private var selectionSummaryView: some View {
        if let selectedXIndex {
            VStack(alignment: .leading, spacing: 6) {
                Text(xAxisLabels[safe: selectedXIndex] ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(selectedPoints, id: \.id) { point in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(seriesColor(forSeriesField: point.seriesField))
                            .frame(width: 7, height: 7)
                        Text(point.seriesLabel)
                            .font(.caption)
                        Spacer(minLength: 8)
                        Text(formatted(point.yValue))
                            .font(.caption.monospacedDigit())
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.14))
            )
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

    private func cartesianChart<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateSelection(at: value.location, proxy: proxy, geometry: geometry)
                                }
                                .onEnded { _ in
                                    selectedXIndex = nil
                                }
                        )
                        .overlay(alignment: .topLeading) {
                            if selectionEnabled,
                               let crosshairX = crosshairXPosition(proxy: proxy, geometry: geometry) {
                                Path { path in
                                    let plotFrame = resolvedPlotFrame(proxy: proxy, geometry: geometry)
                                    path.move(to: CGPoint(x: crosshairX, y: plotFrame.minY))
                                    path.addLine(to: CGPoint(x: crosshairX, y: plotFrame.maxY))
                                }
                                .stroke(Color.secondary.opacity(0.65), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            }
                        }
                }
            }
    }

    private func updateSelection(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        guard selectionEnabled, !xAxisLabels.isEmpty else {
            selectedXIndex = nil
            return
        }

        let plotFrame = resolvedPlotFrame(proxy: proxy, geometry: geometry)
        guard plotFrame != .zero, plotFrame.contains(location) else {
            selectedXIndex = nil
            return
        }

        let localX = location.x - plotFrame.minX
        selectedXIndex = nearestIndex(
            localX: localX,
            plotWidth: plotFrame.width,
            pointCount: xAxisLabels.count
        )
    }

    private func crosshairXPosition(proxy: ChartProxy, geometry: GeometryProxy) -> CGFloat? {
        guard selectionEnabled,
              let selectedXIndex,
              !xAxisLabels.isEmpty else {
            return nil
        }

        let plotFrame = resolvedPlotFrame(proxy: proxy, geometry: geometry)
        guard plotFrame != .zero else {
            return nil
        }
        if xAxisLabels.count <= 1 {
            return plotFrame.midX
        }

        let step = plotFrame.width / CGFloat(max(1, xAxisLabels.count - 1))
        return plotFrame.minX + CGFloat(selectedXIndex) * step
    }

    private func nearestIndex(localX: CGFloat, plotWidth: CGFloat, pointCount: Int) -> Int {
        guard pointCount > 1, plotWidth > 0 else {
            return 0
        }

        let step = plotWidth / CGFloat(pointCount - 1)
        let raw = Int((localX / step).rounded())
        return min(max(0, raw), pointCount - 1)
    }

    private func resolvedPlotFrame(proxy: ChartProxy, geometry: GeometryProxy) -> CGRect {
        guard let anchor = proxy.plotFrame else {
            return .zero
        }
        return geometry[anchor]
    }

    private func markOpacity(forXIndex xIndex: Int) -> Double {
        guard let selectedXIndex, selectionEnabled else {
            return 1
        }
        return selectedXIndex == xIndex ? 1 : 0.32
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
