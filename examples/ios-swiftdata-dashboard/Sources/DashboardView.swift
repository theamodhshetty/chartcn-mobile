import SwiftUI
import SwiftData
import ChartCNMobile

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var revenueKpiSpec: ChartSpec?
    @State private var revenueTrendSpec: ChartSpec?
    @State private var channelComparisonSpec: ChartSpec?
    @State private var rowsBySpecID: [String: [ChartRow]] = [:]
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Executive Dashboard")
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    Text("SwiftData-backed charts loaded from bundled ChartSpec files.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }

                    if let revenueKpiSpec {
                        ChartCNView(
                            spec: revenueKpiSpec,
                            rows: rowsBySpecID[revenueKpiSpec.id] ?? []
                        )
                    }

                    if let revenueTrendSpec {
                        ChartCNView(
                            spec: revenueTrendSpec,
                            rows: rowsBySpecID[revenueTrendSpec.id] ?? []
                        )
                    }

                    if let channelComparisonSpec {
                        ChartCNView(
                            spec: channelComparisonSpec,
                            rows: rowsBySpecID[channelComparisonSpec.id] ?? []
                        )
                    }
                }
                .padding(20)
            }
            .task {
                await loadDashboard()
            }
        }
    }

    @MainActor
    private func loadDashboard() async {
        do {
            try DashboardSeed.install(into: modelContext)

            let revenueKpiSpec = try loadSpec(named: "revenue-kpi")
            let revenueTrendSpec = try loadSpec(named: "revenue-trend")
            let channelComparisonSpec = try loadSpec(named: "channel-comparison")
            let adapter = SwiftDataAdapter(context: modelContext)

            let revenueRows = try loadRows(for: revenueTrendSpec, adapter: adapter)
            let channelRows = try loadRows(for: channelComparisonSpec, adapter: adapter)

            self.revenueKpiSpec = revenueKpiSpec
            self.revenueTrendSpec = revenueTrendSpec
            self.channelComparisonSpec = channelComparisonSpec
            self.rowsBySpecID = [
                revenueKpiSpec.id: revenueRows,
                revenueTrendSpec.id: revenueRows,
                channelComparisonSpec.id: channelRows
            ]
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func loadSpec(named name: String) throws -> ChartSpec {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "chartspec.json",
            subdirectory: "Charts"
        ) else {
            throw ChartRuntimeError.invalidSpec("Missing bundled spec: \(name)")
        }

        return try ChartSpecLoader.load(from: url)
    }

    private func loadRows(
        for spec: ChartSpec,
        adapter: SwiftDataAdapter
    ) throws -> [ChartRow] {
        switch spec.data.source.entity {
        case "DailyRevenue":
            return try adapter.fetchRows(
                SwiftDataFetchConfiguration<DailyRevenue>(
                    sortDescriptors: [SortDescriptor(\DailyRevenue.day, order: .forward)],
                    limit: spec.data.source.limit
                )
            )
        case "ChannelPerformance":
            return try adapter.fetchRows(
                SwiftDataFetchConfiguration<ChannelPerformance>(
                    sortDescriptors: [SortDescriptor(\ChannelPerformance.segment, order: .forward)],
                    limit: spec.data.source.limit
                )
            )
        default:
            throw ChartRuntimeError.invalidSpec(
                "Example dashboard does not know how to fetch entity '\(spec.data.source.entity ?? "nil")'."
            )
        }
    }
}
