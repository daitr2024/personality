package com.daitr2024.personalityai

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Background processor for Wear OS voice input.
 *
 * Handles the complete pipeline WITHOUT showing any UI:
 * 1. Reads AI API config from Flutter secure storage
 * 2. Sends voice text to AI API for classification
 * 3. Parses AI response into task/event/note
 * 4. Writes directly to the Drift SQLite database
 * 5. Returns a human-readable confirmation message
 *
 * This allows the watch user to add items without touching their phone.
 */
object WearVoiceProcessor {

    private const val TAG = "WearVoiceProcessor"

    data class ProcessResult(
        val success: Boolean,
        val message: String,
        val savedCount: Int = 0
    )

    /**
     * Process voice text from the watch: AI classify → save to DB.
     */
    fun process(context: Context, voiceText: String): ProcessResult {
        return try {
            // 1. Read API config
            val config = readApiConfig(context)
            if (config == null) {
                return ProcessResult(false, "API ayarları bulunamadı")
            }

            // 2. Call AI API
            val aiResponse = callAiApi(config, voiceText)
            if (aiResponse == null) {
                // If AI fails, save as a plain note as fallback
                saveAsNote(context, voiceText)
                return ProcessResult(true, "📝 \"$voiceText\" not olarak kaydedildi", 1)
            }

            // 3. Parse AI response and save to DB
            val (count, summary) = parseAndSave(context, aiResponse, voiceText)

            ProcessResult(true, summary, count)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing voice input", e)
            // Fallback: save as note
            try {
                saveAsNote(context, voiceText)
                ProcessResult(true, "📝 \"$voiceText\" not olarak kaydedildi", 1)
            } catch (e2: Exception) {
                ProcessResult(false, "Hata: ${e.message}")
            }
        }
    }

    // ─── AI Config ───────────────────────────────────────────────

    private data class AiConfig(
        val endpoint: String,
        val apiKey: String,
        val model: String
    )

    private fun readApiConfig(context: Context): AiConfig? {
        // flutter_secure_storage on Android stores values in SharedPreferences
        // encrypted with AndroidKeyStore. The prefs file is named:
        // "FlutterSecureStorage" (default) in the app's shared prefs dir.
        try {
            val prefs = context.getSharedPreferences(
                "FlutterSecureStorage", Context.MODE_PRIVATE
            )

            // Keys are stored with their flutter key names
            val apiKey = prefs.getString("ai_api_key", null)
            if (apiKey.isNullOrBlank()) {
                Log.w(TAG, "No API key found in secure storage")
                return null
            }

            val endpoint = prefs.getString(
                "ai_api_endpoint",
                "https://generativelanguage.googleapis.com/v1beta/openai/v1"
            ) ?: "https://generativelanguage.googleapis.com/v1beta/openai/v1"

            val model = prefs.getString("ai_model", "gemini-2.0-flash")
                ?: "gemini-2.0-flash"

            return AiConfig(endpoint, apiKey, model)
        } catch (e: Exception) {
            Log.e(TAG, "Error reading API config", e)
            return null
        }
    }

    // ─── AI API Call ─────────────────────────────────────────────

    private fun callAiApi(config: AiConfig, voiceText: String): JSONObject? {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Calendar.getInstance().time)
        val now = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Calendar.getInstance().time)

        val systemPrompt = """Sen bir kişisel asistansın. Kullanıcının sesli komutunu analiz et ve JSON olarak sınıflandır.
Bugünün tarihi: $today, saat: $now.

Yanıtını SADECE aşağıdaki JSON formatında ver, başka bir şey yazma:
{
  "items": [
    {
      "type": "task" | "event" | "note",
      "title": "başlık",
      "date": "YYYY-MM-DD" veya null,
      "time": "HH:mm" veya null,
      "urgent": true/false
    }
  ]
}

Kurallar:
- "yarın" → bugünün tarihi + 1 gün
- "bugün" → bugünün tarihi  
- Saat belirtilmişse time alanını doldur
- Tarih/saat belirtilmemişse note olarak kaydet
- Tarih varsa ve eylem içeriyorsa task
- Belirli bir saat + tarih varsa event
- Sadece bilgi notu ise note"""

        val requestBody = JSONObject().apply {
            put("model", config.model)
            put("messages", JSONArray().apply {
                put(JSONObject().apply {
                    put("role", "system")
                    put("content", systemPrompt)
                })
                put(JSONObject().apply {
                    put("role", "user")
                    put("content", voiceText)
                })
            })
            put("temperature", 0.3)
            put("max_tokens", 500)
        }

        try {
            var cleanEndpoint = config.endpoint.trim().trimEnd('/')
            val isGeminiDirect = cleanEndpoint.contains("generativelanguage.googleapis.com")
                    && !cleanEndpoint.contains("/openai")

            val url: URL
            val connection: HttpURLConnection

            if (isGeminiDirect) {
                // Direct Gemini API — use ?key= query parameter
                url = URL("$cleanEndpoint/chat/completions?key=${config.apiKey}")
                connection = url.openConnection() as HttpURLConnection
                connection.setRequestProperty("Content-Type", "application/json")
            } else {
                // OpenAI-compatible API — use Bearer auth
                url = URL("$cleanEndpoint/chat/completions")
                connection = url.openConnection() as HttpURLConnection
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Authorization", "Bearer ${config.apiKey}")
            }

            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.connectTimeout = 30000
            connection.readTimeout = 30000

            connection.outputStream.use { os ->
                os.write(requestBody.toString().toByteArray(Charsets.UTF_8))
            }

            val responseCode = connection.responseCode
            if (responseCode != 200) {
                val errorBody = connection.errorStream?.bufferedReader()?.readText() ?: "Unknown error"
                Log.e(TAG, "AI API error $responseCode: $errorBody")
                return null
            }

            val responseBody = connection.inputStream.bufferedReader().readText()
            val responseJson = JSONObject(responseBody)

            // Extract content from OpenAI-compatible response
            val content = responseJson
                .getJSONArray("choices")
                .getJSONObject(0)
                .getJSONObject("message")
                .getString("content")
                .trim()

            // Parse the JSON from the content (strip markdown if present)
            val cleanContent = content
                .replace("```json", "")
                .replace("```", "")
                .trim()

            return JSONObject(cleanContent)
        } catch (e: Exception) {
            Log.e(TAG, "AI API call failed", e)
            return null
        }
    }

    // ─── Parse & Save ────────────────────────────────────────────

    private fun parseAndSave(context: Context, aiResponse: JSONObject, originalText: String): Pair<Int, String> {
        val items = aiResponse.optJSONArray("items") ?: return Pair(0, "AI yanıtı ayrıştırılamadı")

        val db = openDatabase(context) ?: return Pair(0, "Veritabanı açılamadı")

        var savedCount = 0
        val summaries = mutableListOf<String>()

        try {
            for (i in 0 until items.length()) {
                val item = items.getJSONObject(i)
                val type = item.optString("type", "note")
                val title = item.optString("title", originalText)
                val dateStr = item.optString("date", "")
                val timeStr = item.optString("time", "")
                val urgent = item.optBoolean("urgent", false)

                when (type) {
                    "task" -> {
                        val epochSeconds = parseDateTimeToEpoch(dateStr, timeStr)
                        insertTask(db, title, epochSeconds, urgent)
                        val icon = if (urgent) "❗" else "☐"
                        val dateDisplay = if (dateStr.isNotEmpty()) " ($dateStr${if (timeStr.isNotEmpty()) " $timeStr" else ""})" else ""
                        summaries.add("$icon $title$dateDisplay")
                        savedCount++
                    }
                    "event" -> {
                        val epochSeconds = parseDateTimeToEpoch(dateStr, timeStr)
                        val startEpoch = if (timeStr.isNotEmpty()) epochSeconds else null
                        insertEvent(db, title, epochSeconds, startEpoch)
                        val dateDisplay = if (dateStr.isNotEmpty()) " ($dateStr${if (timeStr.isNotEmpty()) " $timeStr" else ""})" else ""
                        summaries.add("📅 $title$dateDisplay")
                        savedCount++
                    }
                    "note" -> {
                        insertNote(db, title)
                        summaries.add("📝 $title")
                        savedCount++
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error saving items", e)
        } finally {
            db.close()
        }

        val summary = if (summaries.isNotEmpty()) {
            "✅ ${summaries.joinToString("\n")}"
        } else {
            "Kaydedilecek öğe bulunamadı"
        }

        return Pair(savedCount, summary)
    }

    // ─── Database Operations ─────────────────────────────────────

    private fun openDatabase(context: Context): SQLiteDatabase? {
        return try {
            // Drift database is at: app_docs_dir/db_v2.sqlite
            val dbFile = File(context.filesDir.parentFile, "app_flutter/db_v2.sqlite")
            if (!dbFile.exists()) {
                Log.e(TAG, "Database file not found at ${dbFile.absolutePath}")
                return null
            }
            SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open database", e)
            null
        }
    }

    private fun insertTask(db: SQLiteDatabase, title: String, dateEpoch: Long?, urgent: Boolean) {
        db.execSQL(
            """INSERT INTO tasks (title, date, is_completed, is_urgent, is_deleted, reminder_enabled, is_recurring)
               VALUES (?, ?, 0, ?, 0, 0, 0)""",
            arrayOf<Any?>(title, dateEpoch, if (urgent) 1 else 0)
        )
        Log.d(TAG, "Task inserted: $title")
    }

    private fun insertEvent(db: SQLiteDatabase, title: String, dateEpoch: Long?, startTimeEpoch: Long?) {
        db.execSQL(
            """INSERT INTO calendar_events (title, date, start_time, is_deleted, reminder_enabled)
               VALUES (?, ?, ?, 0, 1)""",
            arrayOf<Any?>(title, dateEpoch ?: (System.currentTimeMillis() / 1000), startTimeEpoch)
        )
        Log.d(TAG, "Event inserted: $title")
    }

    private fun insertNote(db: SQLiteDatabase, content: String) {
        val nowEpoch = System.currentTimeMillis() / 1000
        db.execSQL(
            """INSERT INTO notes (content, date, is_deleted)
               VALUES (?, ?, 0)""",
            arrayOf<Any?>(content, nowEpoch)
        )
        Log.d(TAG, "Note inserted: $content")
    }

    private fun saveAsNote(context: Context, text: String) {
        val db = openDatabase(context) ?: return
        try {
            insertNote(db, text)
        } finally {
            db.close()
        }
    }

    // ─── Date Parsing ────────────────────────────────────────────

    private fun parseDateTimeToEpoch(dateStr: String, timeStr: String): Long? {
        if (dateStr.isEmpty()) return null

        return try {
            val cal = Calendar.getInstance()
            val parts = dateStr.split("-")
            cal.set(Calendar.YEAR, parts[0].toInt())
            cal.set(Calendar.MONTH, parts[1].toInt() - 1)
            cal.set(Calendar.DAY_OF_MONTH, parts[2].toInt())

            if (timeStr.isNotEmpty()) {
                val timeParts = timeStr.split(":")
                cal.set(Calendar.HOUR_OF_DAY, timeParts[0].toInt())
                cal.set(Calendar.MINUTE, timeParts[1].toInt())
                cal.set(Calendar.SECOND, 0)
            } else {
                cal.set(Calendar.HOUR_OF_DAY, 9) // Default 09:00
                cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 0)
            }

            cal.timeInMillis / 1000 // Drift stores as epoch seconds
        } catch (e: Exception) {
            Log.e(TAG, "Date parse error: $dateStr $timeStr", e)
            null
        }
    }
}
