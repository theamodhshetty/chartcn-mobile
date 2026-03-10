import SwiftUI
import SwiftData

@main
struct ChartCNiOSDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .modelContainer(for: [DailyRevenue.self, ChannelPerformance.self])
    }
}
