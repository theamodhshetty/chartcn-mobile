package dev.chartcn.example.dashboard

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase

@Entity(tableName = "daily_revenue")
data class DailyRevenueEntity(
  @PrimaryKey val day: String,
  val revenue: Double,
  val orders: Int
)

@Entity(tableName = "channel_performance")
data class ChannelPerformanceEntity(
  @PrimaryKey val segment: String,
  val conversion_rate: Double,
  val leads: Int
)

@Dao
interface DailyRevenueDao {
  @Query("SELECT COUNT(*) FROM daily_revenue")
  suspend fun count(): Int

  @Insert(onConflict = OnConflictStrategy.REPLACE)
  suspend fun insertAll(rows: List<DailyRevenueEntity>)
}

@Dao
interface ChannelPerformanceDao {
  @Query("SELECT COUNT(*) FROM channel_performance")
  suspend fun count(): Int

  @Insert(onConflict = OnConflictStrategy.REPLACE)
  suspend fun insertAll(rows: List<ChannelPerformanceEntity>)
}

@Database(
  entities = [DailyRevenueEntity::class, ChannelPerformanceEntity::class],
  version = 1,
  exportSchema = false
)
abstract class DashboardDatabase : RoomDatabase() {
  abstract fun dailyRevenueDao(): DailyRevenueDao
  abstract fun channelPerformanceDao(): ChannelPerformanceDao

  companion object {
    fun build(context: Context): DashboardDatabase {
      return Room.databaseBuilder(
        context,
        DashboardDatabase::class.java,
        "chartcn-dashboard.db"
      )
        .fallbackToDestructiveMigration()
        .build()
    }
  }
}
