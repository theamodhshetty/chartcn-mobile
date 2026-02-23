package dev.chartcn.mobile

import kotlinx.serialization.json.Json

object ChartSpecParser {
  private val json = Json {
    ignoreUnknownKeys = true
    explicitNulls = false
    isLenient = true
  }

  fun parse(raw: String): ChartSpec {
    return json.decodeFromString(ChartSpec.serializer(), raw)
  }
}
