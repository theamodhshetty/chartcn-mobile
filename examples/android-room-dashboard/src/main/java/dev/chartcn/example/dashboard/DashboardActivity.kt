package dev.chartcn.example.dashboard

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface

class DashboardActivity : ComponentActivity() {
  private val database by lazy { DashboardDatabase.build(applicationContext) }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    setContent {
      MaterialTheme {
        Surface {
          DashboardScreen(database = database)
        }
      }
    }
  }
}
