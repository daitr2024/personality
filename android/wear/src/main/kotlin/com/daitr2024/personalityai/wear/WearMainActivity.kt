package com.daitr2024.personalityai.wear

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import androidx.wear.widget.WearableLinearLayoutManager
import androidx.wear.widget.WearableRecyclerView
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import org.json.JSONArray

/**
 * Main Wear OS Activity — Shows today's tasks/events and provides a mic button.
 *
 * Data flow:
 * 1. Phone app sends task data via DataClient → /personality/tasks
 * 2. This activity reads the data and displays it in a scrollable list
 * 3. Mic button → VoiceInputActivity → sends voice text to phone → phone AI processes it
 */
class WearMainActivity : Activity(), DataClient.OnDataChangedListener {

    private lateinit var recyclerView: WearableRecyclerView
    private lateinit var emptyState: View
    private lateinit var micFab: View
    private val taskItems = mutableListOf<TaskItem>()
    private lateinit var adapter: TaskAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_wear_main)

        recyclerView = findViewById(R.id.task_list)
        emptyState = findViewById(R.id.empty_state)
        micFab = findViewById(R.id.mic_fab)

        // Setup curved layout for round watches
        recyclerView.isEdgeItemsCenteringEnabled = true
        recyclerView.layoutManager = WearableLinearLayoutManager(this)

        adapter = TaskAdapter(taskItems)
        recyclerView.adapter = adapter

        // Mic button → start voice input
        micFab.setOnClickListener {
            startActivity(Intent(this, VoiceInputActivity::class.java))
        }

        // Load cached data
        loadCachedData()
    }

    override fun onResume() {
        super.onResume()
        Wearable.getDataClient(this).addListener(this)
        // Request fresh data from phone
        requestDataFromPhone()
    }

    override fun onPause() {
        super.onPause()
        Wearable.getDataClient(this).removeListener(this)
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED) {
                val path = event.dataItem.uri.path ?: continue
                if (path == "/personality/tasks") {
                    val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                    val jsonStr = dataMap.getString("task_json", "[]")
                    parseAndDisplay(jsonStr)

                    // Cache locally
                    getSharedPreferences("wear_data", MODE_PRIVATE)
                        .edit()
                        .putString("task_json", jsonStr)
                        .apply()
                }
            }
        }
    }

    private fun loadCachedData() {
        val cached = getSharedPreferences("wear_data", MODE_PRIVATE)
            .getString("task_json", null)
        if (cached != null) {
            parseAndDisplay(cached)
        } else {
            updateEmptyState()
        }
    }

    private fun requestDataFromPhone() {
        // Send a message to phone requesting fresh task data
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            for (node in nodes) {
                Wearable.getMessageClient(this)
                    .sendMessage(node.id, "/personality/request_sync", byteArrayOf())
            }
        }
    }

    private fun parseAndDisplay(jsonStr: String) {
        runOnUiThread {
            taskItems.clear()
            try {
                val arr = JSONArray(jsonStr)
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    taskItems.add(
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
                e.printStackTrace()
            }
            adapter.notifyDataSetChanged()
            updateEmptyState()
        }
    }

    private fun updateEmptyState() {
        if (taskItems.isEmpty()) {
            emptyState.visibility = View.VISIBLE
            recyclerView.visibility = View.GONE
        } else {
            emptyState.visibility = View.GONE
            recyclerView.visibility = View.VISIBLE
        }
    }
}

// ─── Data Model ──────────────────────────────────────────────────

data class TaskItem(
    val title: String,
    val time: String,
    val type: String, // "task", "event", "note"
    val isUrgent: Boolean,
    val isCompleted: Boolean
)

// ─── RecyclerView Adapter ────────────────────────────────────────

class TaskAdapter(private val items: List<TaskItem>) :
    RecyclerView.Adapter<TaskAdapter.ViewHolder>() {

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val titleText: TextView = view.findViewById(R.id.item_title)
        val timeText: TextView = view.findViewById(R.id.item_time)
        val typeBadge: TextView = view.findViewById(R.id.item_type_badge)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_task, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]

        // Title with status indicators
        val prefix = when {
            item.isCompleted -> "✅ "
            item.isUrgent -> "❗ "
            item.type == "event" -> "📅 "
            item.type == "note" -> "📝 "
            else -> "☐ "
        }
        holder.titleText.text = "$prefix${item.title}"

        // Time
        if (item.time.isNotEmpty()) {
            holder.timeText.text = item.time
            holder.timeText.visibility = View.VISIBLE
        } else {
            holder.timeText.visibility = View.GONE
        }

        // Type badge
        val badge = when (item.type) {
            "event" -> "Etkinlik"
            "note" -> "Not"
            else -> if (item.isUrgent) "Acil Görev" else "Görev"
        }
        holder.typeBadge.text = badge
    }

    override fun getItemCount() = items.size
}
