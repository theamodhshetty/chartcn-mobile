package dev.chartcn.example.dashboard

object DashboardSeed {
  suspend fun install(database: DashboardDatabase) {
    if (database.dailyRevenueDao().count() == 0) {
      database.dailyRevenueDao().insertAll(
        listOf(
          DailyRevenueEntity(day = "2026-02-10", revenue = 96200.0, orders = 142),
          DailyRevenueEntity(day = "2026-02-11", revenue = 101400.0, orders = 149),
          DailyRevenueEntity(day = "2026-02-12", revenue = 104800.0, orders = 155),
          DailyRevenueEntity(day = "2026-02-13", revenue = 108100.0, orders = 161),
          DailyRevenueEntity(day = "2026-02-14", revenue = 110900.0, orders = 166),
          DailyRevenueEntity(day = "2026-02-15", revenue = 113600.0, orders = 171),
          DailyRevenueEntity(day = "2026-02-16", revenue = 117400.0, orders = 176),
          DailyRevenueEntity(day = "2026-02-17", revenue = 121900.0, orders = 182),
          DailyRevenueEntity(day = "2026-02-18", revenue = 126800.0, orders = 190),
          DailyRevenueEntity(day = "2026-02-19", revenue = 129600.0, orders = 194),
          DailyRevenueEntity(day = "2026-02-20", revenue = 131200.0, orders = 198),
          DailyRevenueEntity(day = "2026-02-21", revenue = 134900.0, orders = 203),
          DailyRevenueEntity(day = "2026-02-22", revenue = 138900.0, orders = 209)
        )
      )
    }

    if (database.channelPerformanceDao().count() == 0) {
      database.channelPerformanceDao().insertAll(
        listOf(
          ChannelPerformanceEntity(segment = "Organic", conversion_rate = 42.3, leads = 640),
          ChannelPerformanceEntity(segment = "Paid", conversion_rate = 34.8, leads = 510),
          ChannelPerformanceEntity(segment = "Referral", conversion_rate = 48.5, leads = 290),
          ChannelPerformanceEntity(segment = "Lifecycle", conversion_rate = 45.1, leads = 360)
        )
      )
    }
  }
}
