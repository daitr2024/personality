// ignore_for_file: unused_import, unused_field, unused_local_variable, unused_element
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'ai_config_service.dart';
import '../utils/turkish_nlp_utils.dart';

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
            DateFormat('yyyy-MM-dd').format(parsedDate) == todayStr)) {
      parsedDate = DateTime(
        now.year,
        now.month,
        now.day + 1,
        parsedDate?.hour ?? 9,
        parsedDate?.minute ?? 0,
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
    if (dateValue is DateTime) return dateValue;
    final String s = dateValue.toString();
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

  Future<(AnalysisResult?, String?)> analyzeText(
    String text, {
    String language = 'tr',
  }) async {
    try {
      final apiKey = await _configService.getApiKey();
      final model = await _configService.getModel();

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

      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      final response = await http
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

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String content =
            data['candidates'][0]['content']['parts'][0]['text']?.toString() ??
            '';

        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start != -1 && end != -1) {
          content = content.substring(start, end + 1);
        }

        try {
          final jsonResult = jsonDecode(content);
          final List<AnalysisTask> tasks = (jsonResult['tasks'] as List? ?? [])
              .map((e) {
                if (e is String)
                  return AnalysisTask.fromMap({'title': e}, originalText: text);
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
        debugPrint('AI API Error: ${response.statusCode} - ${response.body}');
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
            'المهام المتكررة:\n'
            'اكتشف أنماط مثل "كل يوم"، "أسبوعي".\n'
            '{"isRecurring":true,"recurrencePattern":"daily|weekly","recurrenceDays":["Monday"]}\n\n'
            'أعد JSON فقط:\n'
            '{"tasks":[{"title":"","date":"ISO8601","isRecurring":false}],"events":[{"title":"","date":"ISO8601"}],"notes":[]}\n\n'
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
            'RECURRING TASKS:\n'
            'Detect patterns like "every day", "weekly".\n'
            '{"isRecurring":true,"recurrencePattern":"daily|weekly","recurrenceDays":["Monday"]}\n\n'
            'Return ONLY JSON:\n'
            '{"tasks":[{"title":"","date":"ISO8601","isRecurring":false}],"events":[{"title":"","date":"ISO8601"}],"notes":[]}\n\n'
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
            'TEKRARLAYAN GÖREVLER:\n'
            '"her gün", "haftalık" gibi kalıpları tespit et.\n'
            '{"isRecurring":true,"recurrencePattern":"daily|weekly","recurrenceDays":["Monday"]}\n\n'
            'SADECE JSON dön:\n'
            '{"tasks":[{"title":"","date":"ISO8601","isRecurring":false}],"events":[{"title":"","date":"ISO8601"}],"notes":[]}\n\n'
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
