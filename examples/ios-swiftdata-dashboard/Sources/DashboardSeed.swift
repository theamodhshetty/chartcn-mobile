import Foundation
import SwiftData

enum DashboardSeed {
    @MainActor
    static func install(into context: ModelContext) throws {
        let revenueCount = try context.fetchCount(FetchDescriptor<DailyRevenue>())
        let channelCount = try context.fetchCount(FetchDescriptor<ChannelPerformance>())

        if revenueCount == 0 {
            revenueRows.forEach(context.insert)
        }

        if channelCount == 0 {
            channelRows.forEach(context.insert)
        }

        if revenueCount == 0 || channelCount == 0 {
            try context.save()
        }
    }

    private static let revenueRows: [DailyRevenue] = [
        DailyRevenue(day: "2026-02-10", revenue: 96200, orders: 142),
        DailyRevenue(day: "2026-02-11", revenue: 101400, orders: 149),
        DailyRevenue(day: "2026-02-12", revenue: 104800, orders: 155),
        DailyRevenue(day: "2026-02-13", revenue: 108100, orders: 161),
        DailyRevenue(day: "2026-02-14", revenue: 110900, orders: 166),
        DailyRevenue(day: "2026-02-15", revenue: 113600, orders: 171),
        DailyRevenue(day: "2026-02-16", revenue: 117400, orders: 176),
        DailyRevenue(day: "2026-02-17", revenue: 121900, orders: 182),
        DailyRevenue(day: "2026-02-18", revenue: 126800, orders: 190),
        DailyRevenue(day: "2026-02-19", revenue: 129600, orders: 194),
        DailyRevenue(day: "2026-02-20", revenue: 131200, orders: 198),
        DailyRevenue(day: "2026-02-21", revenue: 134900, orders: 203),
        DailyRevenue(day: "2026-02-22", revenue: 138900, orders: 209)
    ]

    private static let channelRows: [ChannelPerformance] = [
        ChannelPerformance(segment: "Organic", conversionRate: 42.3, leads: 640),
        ChannelPerformance(segment: "Paid", conversionRate: 34.8, leads: 510),
        ChannelPerformance(segment: "Referral", conversionRate: 48.5, leads: 290),
        ChannelPerformance(segment: "Lifecycle", conversionRate: 45.1, leads: 360)
    ]
}
