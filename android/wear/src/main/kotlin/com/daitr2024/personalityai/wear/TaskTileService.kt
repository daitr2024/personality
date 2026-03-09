package com.daitr2024.personalityai.wear

import android.content.Context
import android.util.Log
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import org.json.JSONArray

/**
 * Tile Service — Shows today's tasks/events on the watch face tile area.
 *
 * Users add this tile by swiping left/right on their watch face.
 * The tile shows:
 * - Title: "Bugünün Programı"
 * - Up to 4 task/event items with time and title
 * - A "🎤" button that launches voice input
 *
 * Data is read from SharedPreferences (synced from phone via WearDataListenerService).
 */
class TaskTileService : TileService() {

    companion object {
        private const val TAG = "TaskTileService"
        private const val RESOURCE_VERSION = "1"

        fun requestTileUpdate(context: Context) {
            getUpdater(context).requestUpdate(TaskTileService::class.java)
        }
    }

    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> {
        Log.d(TAG, "Tile requested")

        val items = loadItems()
        val timeline = createTimeline(items)

        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCE_VERSION)
            .setTileTimeline(timeline)
            .setFreshnessIntervalMillis(300_000) // Refresh every 5 minutes
            .build()

        return Futures.immediateFuture(tile)
    }

    override fun onTileResourcesRequest(requestParams: RequestBuilders.ResourcesRequest): ListenableFuture<ResourceBuilders.Resources> {
        return Futures.immediateFuture(
            ResourceBuilders.Resources.Builder()
                .setVersion(RESOURCE_VERSION)
                .build()
        )
    }

    private fun loadItems(): List<TaskItem> {
        val prefs = getSharedPreferences(WearDataListenerService.PREFS_NAME, MODE_PRIVATE)
        val jsonStr = prefs.getString(WearDataListenerService.KEY_TASK_JSON, "[]") ?: "[]"

        val items = mutableListOf<TaskItem>()
        try {
            val arr = JSONArray(jsonStr)
            val limit = minOf(arr.length(), 4) // Show max 4 items on tile
            for (i in 0 until limit) {
                val obj = arr.getJSONObject(i)
                items.add(
                    TaskItem(
                        title = obj.getString("title"),
                        time = obj.optString("time", ""),
                        type = obj.optString("type", "task"),
                        isUrgent = obj.optBoolean("urgent", false),
                        isCompleted = obj.optBoolean("completed", false)
                    )
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing task JSON", e)
        }
        return items
    }

    private fun createTimeline(items: List<TaskItem>): TimelineBuilders.Timeline {
        val layout = createLayout(items)

        val entry = TimelineBuilders.TimelineEntry.Builder()
            .setLayout(layout)
            .build()

        return TimelineBuilders.Timeline.Builder()
            .addTimelineEntry(entry)
            .build()
    }

    private fun createLayout(items: List<TaskItem>): LayoutElementBuilders.Layout {
        val column = LayoutElementBuilders.Column.Builder()
            .setWidth(expand())
            .setModifiers(
                ModifiersBuilders.Modifiers.Builder()
                    .setPadding(
                        ModifiersBuilders.Padding.Builder()
                            .setAll(dp(12f))
                            .build()
                    )
                    .build()
            )

        // Title
        column.addContent(
            LayoutElementBuilders.Text.Builder()
                .setText("📋 Görevlerim")
                .setFontStyle(
                    LayoutElementBuilders.FontStyle.Builder()
                        .setSize(sp(14f))
                        .setColor(argb(0xFFE94560.toInt()))
                        .setWeight(LayoutElementBuilders.FONT_WEIGHT_BOLD)
                        .build()
                )
                .build()
        )

        // Spacer
        column.addContent(
            LayoutElementBuilders.Spacer.Builder()
                .setHeight(dp(6f))
                .build()
        )

        if (items.isEmpty()) {
            // Empty state
            column.addContent(
                LayoutElementBuilders.Text.Builder()
                    .setText("✨ Görev yok")
                    .setFontStyle(
                        LayoutElementBuilders.FontStyle.Builder()
                            .setSize(sp(12f))
                            .setColor(argb(0xFFB0B0B0.toInt()))
                            .build()
                    )
                    .build()
            )
        } else {
            // Task items
            for (item in items) {
                val icon = when {
                    item.isCompleted -> "✅"
                    item.type == "event" -> "📅"
                    item.isUrgent -> "❗"
                    else -> "☐"
                }

                val timePrefix = if (item.time.isNotEmpty()) "${item.time} " else ""

                column.addContent(
                    LayoutElementBuilders.Text.Builder()
                        .setText("$icon $timePrefix${item.title}")
                        .setFontStyle(
                            LayoutElementBuilders.FontStyle.Builder()
                                .setSize(sp(11f))
                                .setColor(argb(0xFFD0D0E8.toInt()))
                                .build()
                        )
                        .setMaxLines(1)
                        .build()
                )

                column.addContent(
                    LayoutElementBuilders.Spacer.Builder()
                        .setHeight(dp(3f))
                        .build()
                )
            }
        }

        // Spacer before mic hint
        column.addContent(
            LayoutElementBuilders.Spacer.Builder()
                .setHeight(dp(8f))
                .build()
        )

        // Mic hint — tapping opens the wear app
        column.addContent(
            LayoutElementBuilders.Text.Builder()
                .setText("🎤 Sesli ekle")
                .setFontStyle(
                    LayoutElementBuilders.FontStyle.Builder()
                        .setSize(sp(11f))
                        .setColor(argb(0xFFE94560.toInt()))
                        .build()
                )
                .setModifiers(
                    ModifiersBuilders.Modifiers.Builder()
                        .setClickable(
                            ModifiersBuilders.Clickable.Builder()
                                .setId("open_voice")
                                .setOnClick(
                                    ActionBuilders.LaunchAction.Builder()
                                        .setAndroidActivity(
                                            ActionBuilders.AndroidActivity.Builder()
                                                .setClassName(
                                                    "com.daitr2024.personalityai.wear.VoiceInputActivity"
                                                )
                                                .setPackageName(
                                                    "com.daitr2024.personalityai"
                                                )
                                                .build()
                                        )
                                        .build()
                                )
                                .build()
                        )
                        .build()
                )
                .build()
        )

        return LayoutElementBuilders.Layout.Builder()
            .setRoot(column.build())
            .build()
    }
}
