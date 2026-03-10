import Foundation
import SwiftData
import ChartCNMobile

@Model
final class DailyRevenue: ChartSwiftDataMappable {
    @Attribute(.unique) var day: String
    var revenue: Double
    var orders: Int

    init(day: String, revenue: Double, orders: Int) {
        self.day = day
        self.revenue = revenue
        self.orders = orders
    }

    func toChartRow() -> ChartRow {
        [
            "day": .string(day),
            "revenue": .number(revenue),
            "orders": .number(Double(orders))
        ]
    }
}

@Model
final class ChannelPerformance: ChartSwiftDataMappable {
    @Attribute(.unique) var segment: String
    var conversionRate: Double
    var leads: Int

    init(segment: String, conversionRate: Double, leads: Int) {
        self.segment = segment
        self.conversionRate = conversionRate
        self.leads = leads
    }

    func toChartRow() -> ChartRow {
        [
            "segment": .string(segment),
            "conversion_rate": .number(conversionRate),
            "leads": .number(Double(leads))
        ]
    }
}
