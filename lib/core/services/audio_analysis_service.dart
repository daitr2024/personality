// ignore_for_file: unused_import, unused_field, unused_local_variable, unused_element
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'ai_config_service.dart';
import '../utils/turkish_nlp_utils.dart';
import '../utils/date_utils.dart';

class AnalysisResult {
  final List<AnalysisTask> tasks;
  final List<AnalysisEvent> events;
  final List<String> notes;
  final bool isLocal;

  AnalysisResult({
    required this.tasks,
    required this.events,
    required this.notes,
    this.isLocal = false,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      tasks: (json['tasks'] as List? ?? []).map((e) {
        if (e is String) return AnalysisTask(title: e);
        return AnalysisTask.fromJson(e);
      }).toList(),
      events: (json['events'] as List? ?? [])
          .map((e) => AnalysisEvent.fromJson(e))
          .toList(),
      notes: List<String>.from(json['notes'] ?? []),
      isLocal: json['isLocal'] ?? false,
    );
  }
}

class AnalysisTask {
  final String title;
  final DateTime? date;
  final bool isRecurring;
  final String? recurrencePattern;
  final int? recurrenceInterval;
  final List<String>? recurrenceDays;
  final DateTime? recurrenceEndDate;

  AnalysisTask({
    required this.title,
    this.date,
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceInterval,
    this.recurrenceDays,
    this.recurrenceEndDate,
  });

  factory AnalysisTask.fromJson(Map<String, dynamic> json) {
    return AnalysisTask.fromMap(json);
  }

  factory AnalysisTask.fromMap(
    Map<String, dynamic> json, {
    String? originalText,
  }) {
    DateTime? parsedDate = _parseFlexibleDate(json['date']);
    DateTime? parsedEndDate = _parseFlexibleDate(json['recurrenceEndDate']);

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final textToCheck = (json['title'] ?? '') + (originalText ?? '');
    final isTomorrowInText = textToCheck.toLowerCase().contains('yarın');

    if (isTomorrowInText &&
        (parsedDate == null ||
            DateFormat('yyyy-MM-dd').format(parsedDate.toAppLocal) ==
                todayStr)) {
      final baseDate = parsedDate ?? now;
      parsedDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        baseDate.hour,
        baseDate.minute,
      );
    }

    return AnalysisTask(
      title: json['title'] ?? '',
      date: parsedDate,
      isRecurring: json['isRecurring'] ?? false,
      recurrencePattern: json['recurrencePattern'],
      recurrenceInterval: json['recurrenceInterval'],
      recurrenceDays: json['recurrenceDays'] != null
          ? List<String>.from(json['recurrenceDays'])
          : null,
      recurrenceEndDate: parsedEndDate,
    );
  }

  static DateTime? _parseFlexibleDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) {
      // If already local, return as-is. If UTC, convert to local.
      return dateValue.isUtc ? dateValue.toLocal() : dateValue;
    }
    String s = dateValue.toString();
    // Strip timezone suffixes BEFORE parsing so DateTime.parse treats
    // the wall-clock time as local (e.g. "18:00+03:00" → "18:00" local).
    s = _stripTimezone(s);
    try {
      return DateTime.parse(s);
    } catch (_) {
      try {
        if (s.contains(' ') && !s.contains('T')) {
          return DateTime.parse(s.replaceFirst(' ', 'T'));
        }
      } catch (_) {}
    }
    return null;
  }

  /// Strip timezone suffixes (Z, +03:00, -05:00, +0300, etc.) from an
  /// ISO 8601 string so that DateTime.parse treats it as local time.
  static String _stripTimezone(String s) {
    // Remove trailing Z
    if (s.endsWith('Z') || s.endsWith('z')) {
      return s.substring(0, s.length - 1);
    }
    // Remove +HH:MM or -HH:MM or +HHMM at the end
    final tzRegex = RegExp(r'[+-]\d{2}:?\d{2}$');
    return s.replaceFirst(tzRegex, '');
  }
}

class AnalysisEvent {
  final String title;
  final DateTime? date;

  AnalysisEvent({required this.title, this.date});

  factory AnalysisEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate = AnalysisTask._parseFlexibleDate(json['date']);
    return AnalysisEvent(title: json['title'] ?? '', date: parsedDate);
  }
}

class AudioAnalysisService {
  final AIConfigService _configService;

  AudioAnalysisService(this._configService);

  /// Transcribe an audio file using Gemini API (replaces local STT)
  /// Returns the transcribed text, or null on failure.
  Future<String?> transcribeAudioFile(String audioPath) async {
    final apiKey = (await _configService.getApiKey())?.trim();
    if (apiKey == null || apiKey.isEmpty) return null;

    final model = await _configService.getModel();
    final file = File(audioPath);
    if (!await file.exists()) return null;

    final audioBytes = await file.readAsBytes();
    final base64Audio = base64Encode(audioBytes);

    // Determine mime type from extension
    final ext = audioPath.split('.').last.toLowerCase();
    String mimeType;
    switch (ext) {
      case 'wav':
        mimeType = 'audio/wav';
        break;
      case 'mp3':
        mimeType = 'audio/mp3';
        break;
      case 'ogg':
        mimeType = 'audio/ogg';
        break;
      case 'm4a':
      case 'aac':
        mimeType = 'audio/aac';
        break;
      default:
        mimeType = 'audio/wav';
    }

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Transcribe this audio. Return ONLY the exact spoken text, nothing else. '
                  'If the language is Turkish, transcribe in Turkish. '
                  'Do not add any introduction, formatting, or explanation.',
            },
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Audio},
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.0},
    });

    final baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
    var url = '$baseUrl/models/$model:generateContent?key=$apiKey';

    try {
      var response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 60));

      // Fallback if model not found
      if (response.statusCode == 404) {
        url = '$baseUrl/models/gemini-2.0-flash:generateContent?key=$apiKey';
        response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 60));
      }

      if (response.statusCode == 200) {
        final rawBody = utf8.decode(response.bodyBytes);
        final outerJson = jsonDecode(rawBody);
        final text =
            outerJson['candidates']?[0]?['content']?['parts']?[0]?['text']
                ?.toString()
                .trim();
        return (text != null && text.isNotEmpty) ? text : null;
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        debugPrint(
          'Gemini audio transcription error (${response.statusCode}): $errorBody',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Audio transcription error: $e');
      return null;
    }
  }

  Future<(AnalysisResult?, String?)> analyzeText(
    String text, {
    String language = 'tr',
  }) async {
    // Try primary config first
    final result = await _tryAnalyze(text, language: language, isBackup: false);
    if (result.$1 != null) return result;

    // If primary failed with auth error, try backup
    final errorMsg = result.$2 ?? '';
    if (errorMsg.contains('401') ||
        errorMsg.contains('403') ||
        errorMsg.contains('API_KEY')) {
      debugPrint('Primary API failed, trying backup...');
      final backupResult = await _tryAnalyze(
        text,
        language: language,
        isBackup: true,
      );
      if (backupResult.$1 != null) return backupResult;
    }

    return result;
  }

  Future<(AnalysisResult?, String?)> _tryAnalyze(
    String text, {
    String language = 'tr',
    bool isBackup = false,
  }) async {
    try {
      final apiKey = isBackup
          ? await _configService.getApiKeyBackup()
          : await _configService.getApiKey();
      final model = isBackup
          ? await _configService.getModelBackup()
          : await _configService.getModel();
      final endpoint = isBackup
          ? await _configService.getEndpointBackup()
          : await _configService.getEndpoint();

      if (apiKey == null || apiKey.isEmpty) {
        return (null, 'API_KEY_NOT_SET');
      }

      final cleanedText = _cleanText(text);
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);
      final locale = language == 'ar'
          ? 'ar'
          : language == 'en'
          ? 'en'
          : 'tr';
      final dayName = DateFormat('EEEE', locale).format(now);

      final prompt = _getAnalysisPrompt(
        language,
        cleanedText,
        formattedDate,
        dayName,
        now,
      );

      // Determine if endpoint is OpenAI-compatible or direct Gemini
      final isOpenAICompatible =
          endpoint.contains('/openai') ||
          endpoint.contains('openai.com') ||
          endpoint.contains('groq.com') ||
          (!endpoint.contains('generativelanguage.googleapis.com'));

      final isDirectGemini =
          endpoint.contains('generativelanguage.googleapis.com') &&
          !endpoint.contains('/openai');

      http.Response response;

      if (isDirectGemini) {
        // Direct Gemini REST API: /v1beta/models/{model}:generateContent?key=
        String cleanEndpoint = endpoint.trim();
        if (cleanEndpoint.endsWith('/')) {
          cleanEndpoint = cleanEndpoint.substring(0, cleanEndpoint.length - 1);
        }
        // Extract base URL up to /v1beta
        String baseUrl = cleanEndpoint;
        final v1betaIndex = cleanEndpoint.indexOf('/v1beta');
        if (v1betaIndex != -1) {
          baseUrl = cleanEndpoint.substring(0, v1betaIndex + '/v1beta'.length);
        }
        final url = '$baseUrl/models/$model:generateContent?key=$apiKey';

        response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                    ],
                  },
                ],
                'generationConfig': {'temperature': 0.1},
              }),
            )
            .timeout(const Duration(seconds: 30));
      } else {
        // OpenAI-compatible endpoint (Gemini /openai, OpenAI, Groq, etc.)
        String cleanEndpoint = endpoint.trim();
        if (cleanEndpoint.endsWith('/')) {
          cleanEndpoint = cleanEndpoint.substring(0, cleanEndpoint.length - 1);
        }
        // Ensure /chat/completions path
        String url;
        if (cleanEndpoint.endsWith('/chat/completions')) {
          url = cleanEndpoint;
        } else if (cleanEndpoint.endsWith('/v1')) {
          url = '$cleanEndpoint/chat/completions';
        } else {
          url = '$cleanEndpoint/chat/completions';
        }

        response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'user', 'content': prompt},
                ],
                'temperature': 0.1,
              }),
            )
            .timeout(const Duration(seconds: 30));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String content;

        if (isDirectGemini) {
          content =
              data['candidates'][0]['content']['parts'][0]['text']
                  ?.toString() ??
              '';
        } else {
          // OpenAI-compatible response format
          content =
              data['choices']?[0]?['message']?['content']?.toString() ?? '';
        }

        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start != -1 && end != -1) {
          content = content.substring(start, end + 1);
        }

        try {
          final jsonResult = jsonDecode(content);
          final List<AnalysisTask> tasks = (jsonResult['tasks'] as List? ?? [])
              .map((e) {
                if (e is String) {
                  return AnalysisTask.fromMap({'title': e}, originalText: text);
                }
                return AnalysisTask.fromMap(
                  e as Map<String, dynamic>,
                  originalText: text,
                );
              })
              .toList();

          final List<AnalysisEvent> events =
              (jsonResult['events'] as List? ?? [])
                  .map((e) => AnalysisEvent.fromJson(e as Map<String, dynamic>))
                  .toList();

          final result = AnalysisResult(
            tasks: tasks,
            events: events,
            notes: List<String>.from(jsonResult['notes'] ?? []),
          );
          return (result, null);
        } catch (e) {
          debugPrint('JSON Decode Error: $e\nContent: $content');
          return (null, 'AI yanıtı ayrıştırılamadı.');
        }
      } else if (response.statusCode == 429) {
        return (
          null,
          'API kota limiti aşıldı. Lütfen 1 dakika bekleyip tekrar deneyin.',
        );
      } else {
        debugPrint(
          'AI API Error (${isBackup ? "backup" : "primary"}): ${response.statusCode} - ${utf8.decode(response.bodyBytes)}',
        );
        return (null, 'API Hatası (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Analysis Error: $e');
      return (null, 'ANALYSIS_ERROR: $e');
    }
  }

  static String _getAnalysisPrompt(
    String language,
    String cleanedText,
    String formattedDate,
    String dayName,
    DateTime now,
  ) {
    final tomorrow = DateFormat(
      'yyyy-MM-dd',
    ).format(now.add(const Duration(days: 1)));
    switch (language) {
      case 'ar':
        return 'حلل النص واستخرج المهام أو الأحداث أو الملاحظات.\n\n'
            'قواعد التصنيف:\n'
            'مهمة (tasks) → عمل/إجراء يجب القيام به (اشتر، أعد، أرسل)\n'
            'حدث (events) → حدث في وقت محدد (اجتماع، موعد، درس)\n'
            'ملاحظة (notes) → معلومات، وصف فقط\n\n'
            'العنوان: فقط اسم الإجراء. أزل عبارات مثل "أضف مهمة"، "احفظ".\n'
            'التاريخ: "غداً" → $tomorrow\n'
            'اليوم: $formattedDate ($dayName)\n\n'
            'تنسيق التاريخ: YYYY-MM-DDTHH:MM:SS بدون منطقة زمنية. لا تضف Z أو +03:00. استخدم التوقيت المحلي فقط.\n\n'
            'المهام المتكررة:\n'
            'اكتشف أنماط مثل "كل يوم"، "أسبوعي".\n'
            '{"isRecurring":true,"recurrencePattern":"daily|weekly","recurrenceDays":["Monday"]}\n\n'
            'أعد JSON فقط:\n'
            '{"tasks":[{"title":"","date":"YYYY-MM-DDTHH:MM:SS","isRecurring":false}],"events":[{"title":"","date":"YYYY-MM-DDTHH:MM:SS"}],"notes":[]}\n\n'
            'النص: "$cleanedText"';
      case 'en':
        return 'Analyze the text and extract Tasks, Events, or Notes.\n\n'
            'CATEGORY RULES:\n'
            'TASK (tasks) → Action/job to be done (buy, do, prepare, send)\n'
            'EVENT (events) → Occurrence at specific time (meeting, appointment, class)\n'
            'NOTE (notes) → Pure information, description\n\n'
            'TITLE: Only the action name. Remove phrases like "add task", "save".\n'
            'DATE: "tomorrow" → $tomorrow\n'
            'Today: $formattedDate ($dayName)\n\n'
            'DATE FORMAT: YYYY-MM-DDTHH:MM:SS without timezone. Do NOT add Z or +03:00. Use local time only.\n\n'
            'RECURRING TASKS:\n'
            'Detect patterns like "every day", "weekly".\n'
            '{"isRecurring":true,"recurrencePattern":"daily|weekly","recurrenceDays":["Monday"]}\n\n'
            'Return ONLY JSON:\n'
            '{"tasks":[{"title":"","date":"YYYY-MM-DDTHH:MM:SS","isRecurring":false}],"events":[{"title":"","date":"YYYY-MM-DDTHH:MM:SS"}],"notes":[]}\n\n'
            'Text: "$cleanedText"';
      default: // Turkish
        return 'Metni analiz et ve Görevler, Etkinlikler veya Notlar olarak çıkar.\n\n'
            'KATEGORİ KURALLARI:\n'
            'GÖREV (tasks) → Yapılması gereken iş/eylem (al, yap, hazırla, gönder)\n'
            'ETKİNLİK (events) → Belirli saatte katılınan olay (toplantı, randevu, ders)\n'
            'NOT (notes) → Salt bilgi, açıklama\n\n'
            'BAŞLIK: Sadece eylem adı olsun. "görevi ekle", "kaydet" gibi ifadeleri çıkar.\n'
            'TARİH: "yarın" → $tomorrow\n'
            'Bugün: $formattedDate ($dayName)\n\n'
            'TARİH FORMATI: YYYY-MM-DDTHH:MM:SS saat dilimi EKLEMEYİN. Z veya +03:00 KULLANMAYIN. Sadece yerel saat yazın.\n\n'
            'TEKRARLAYAN GÖREVLER:\n'
            '"her gün", "haftalık" gibi kalıpları tespit et.\n'
            '{"isRecurring":true,"recurrencePattern":"daily|weekly","recurrenceDays":["Monday"]}\n\n'
            'SADECE JSON dön:\n'
            '{"tasks":[{"title":"","date":"YYYY-MM-DDTHH:MM:SS","isRecurring":false}],"events":[{"title":"","date":"YYYY-MM-DDTHH:MM:SS"}],"notes":[]}\n\n'
            'Metin: "$cleanedText"';
    }
  }

  /// Basic Local Text NLP & Clean Rules
  String _cleanText(String input) {
    String result = input.trim();

    result = result.replaceAll(RegExp(r'\b(ııı+)\b', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'\b(eee+)\b', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'\b(ıı+)\b', caseSensitive: false), '');
    result = result.replaceAll(
      RegExp(r'\b(şey+|ee+)\b', caseSensitive: false),
      '',
    );

    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    final typoMap = {
      'bıgün': 'bugün',
      'şmdi': 'şimdi',
      'yarm': 'yarın',
      'yarin': 'yarın',
      'toplanty': 'toplantı',
      'toplanti': 'toplantı',
      'pazartesş': 'pazartesi',
      'çarşanba': 'çarşamba',
      'perşenbe': 'perşembe',
    };

    String lowerResult = result.toLowerCase();

    typoMap.forEach((wrong, correct) {
      if (lowerResult.contains(wrong)) {
        result = result.replaceAll(
          RegExp('\\b$wrong\\b', caseSensitive: false),
          correct,
        );
      }
    });

    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    result = TurkishNLPUtils.applyFuzzyCorrections(result);

    return result.trim();
  }

  void dispose() {
    // No local resources to dispose
  }
}
