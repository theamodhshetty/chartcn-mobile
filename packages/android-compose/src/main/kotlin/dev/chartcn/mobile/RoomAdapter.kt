package dev.chartcn.mobile

import androidx.sqlite.db.SimpleSQLiteQuery
import androidx.sqlite.db.SupportSQLiteDatabase
import androidx.sqlite.db.SupportSQLiteQuery
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive

class RoomAdapter(private val database: SupportSQLiteDatabase) {
  fun fetchRows(
    table: String,
    whereClause: String? = null,
    args: List<Any?> = emptyList(),
    orderBy: List<OrderBy> = emptyList(),
    limit: Int? = null
  ): List<ChartRow> {
    require(table.matches(Regex("^[a-zA-Z0-9_]+$"))) {
      "Unsafe table name."
    }

    val sql = buildString {
      append("SELECT * FROM ")
      append(table)

      if (!whereClause.isNullOrBlank()) {
        append(" WHERE ")
        append(whereClause)
      }

      if (orderBy.isNotEmpty()) {
        append(" ORDER BY ")
        append(orderBy.joinToString(", ") { "${it.field} ${it.direction.uppercase()}" })
      }

      if (limit != null && limit > 0) {
        append(" LIMIT ")
        append(limit)
      }
    }

    val query: SupportSQLiteQuery = SimpleSQLiteQuery(sql, args.toTypedArray())
    val cursor = database.query(query)

    cursor.use {
      val rows = mutableListOf<ChartRow>()
      val columnNames = cursor.columnNames

      while (cursor.moveToNext()) {
        val row = buildMap<String, kotlinx.serialization.json.JsonElement> {
          for (index in columnNames.indices) {
            val key = columnNames[index]
            val value = when (cursor.getType(index)) {
              android.database.Cursor.FIELD_TYPE_NULL -> JsonNull
              android.database.Cursor.FIELD_TYPE_INTEGER -> JsonPrimitive(cursor.getLong(index))
              android.database.Cursor.FIELD_TYPE_FLOAT -> JsonPrimitive(cursor.getDouble(index))
              android.database.Cursor.FIELD_TYPE_STRING -> JsonPrimitive(cursor.getString(index))
              android.database.Cursor.FIELD_TYPE_BLOB -> JsonPrimitive(cursor.getBlob(index).decodeToString())
              else -> JsonNull
            }
            put(key, value)
          }
        }
        rows.add(row)
      }

      return rows
    }
  }
}
