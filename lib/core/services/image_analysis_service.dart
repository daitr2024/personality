import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../database/app_database.dart';
import 'ai_config_service.dart';

/// Result from image analysis containing extracted items
class ImageAnalysisResult {
  final List<ExtractedTask> tasks;
  final List<ExtractedNote> notes;
  final List<ExtractedEvent> events;
  final List<ExtractedContact> contacts;
  final String rawText;

  ImageAnalysisResult({
    required this.tasks,
    required this.notes,
    required this.events,
    required this.contacts,
    required this.rawText,
  });
}

class ExtractedContact {
  final String? name;
  final String? phone;
  final String? email;
  final String? company;
  final String? jobTitle;
  final String? department;
  final String? address;

  ExtractedContact({
    this.name,
    this.phone,
    this.email,
    this.company,
    this.jobTitle,
    this.department,
    this.address,
  });
}

class ExtractedTask {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;

  ExtractedTask({
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
  });
}

class ExtractedNote {
  final String title;
  final String content;
  final DateTime? date;

  ExtractedNote({required this.title, required this.content, this.date});
}

class ExtractedEvent {
  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? location;

  ExtractedEvent({
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.location,
  });
}

class ImageAnalysisService {
  final _picker = ImagePicker();
  final AppDatabase _database;
  final AIConfigService _configService;

  ImageAnalysisService(
    this._database,
    this._configService,
    dynamic _, // unused attachmentService
  );

  Future<XFile?> pickImageFromCamera() async =>
      await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  Future<XFile?> pickImageFromGallery() async =>
      await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

  Future<String> saveImageLocally(XFile image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'scanned_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(
      image.path,
    ).copy(p.join(imagesDir.path, fileName));
    return savedImage.path;
  }

  Future<ImageAnalysisResult> analyzeImage(
    String imagePath, {
    String language = 'tr',
  }) async {
    debugPrint('--- [STRICT AI MODE] ANALYSIS STARTED ---');

    final visionKeyRaw = await _configService.getVisionApiKey();
    final generalKeyRaw = await _configService.getApiKey();

    final visionKey = visionKeyRaw?.trim();
    final generalKey = generalKeyRaw?.trim();

    final effectiveKey = (visionKey != null && visionKey.isNotEmpty)
        ? visionKey
        : generalKey;

    if (effectiveKey != null && effectiveKey.isNotEmpty) {
      try {
        final result = await _analyzeWithVision(
          imagePath,
          customKey: effectiveKey,
          language: language,
        );
        if (result != null) {
          return result;
        }
        throw 'API_PARSE_ERROR';
      } catch (e) {
        debugPrint('Step 0 Failed: $e');
        if (e.toString().contains('401') || e.toString().contains('403')) {
          throw 'API_KEY_INVALID';
        }
        throw e.toString();
      }
    }

    throw 'API_KEY_NOT_SET';
  }

  Map<String, dynamic>? _extractJsonRobustly(String content) {
    try {
      final codeBlockRegex = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```');
      final match = codeBlockRegex.firstMatch(content);
      if (match != null) {
        return jsonDecode(match.group(1)!);
      }

      final start = content.indexOf('{');
      final end = content.lastIndexOf('}');
      if (start != -1 && end != -1) {
        return jsonDecode(content.substring(start, end + 1));
      }
    } catch (e) {
      debugPrint('JSON Extraction Error: $e');
    }
    return null;
  }

  DateTime? _tryParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // Try date-only format YYYY-MM-DD
        if (dateStr.length == 10) {
          return DateTime.parse('${dateStr}T00:00:00');
        }
      } catch (_) {}
    }
    return null;
  }

  static String _getVisionPrompt(
    String language,
    String currentDate,
    String currentTime,
  ) {
    switch (language) {
      case 'ar':
        return 'أنت محلل مستندات خبير. حلل الصورة وأعد البيانات بتنسيق JSON منظم.\n'
            'أعد JSON فقط. لا تكتب نصاً إضافياً.\n\n'
            'قواعد التصنيف (مهم جداً):\n'
            'كل عنصر يجب أن ينتمي لفئة واحدة فقط!\n\n'
            'مهمة (tasks) → عمل أو إجراء يجب القيام به:\n'
            '  أمثلة: "اشتر الحقيبة"، "أعد التقرير"، "اذهب للسوق"، "ادفع الفاتورة"\n'
            '  قاعدة: إذا كان يحتوي على أفعال مثل اشتر، أعد، أرسل، نظف → مهمة\n\n'
            'حدث (events) → حدث يُحضر في وقت ومكان محدد:\n'
            '  أمثلة: "اجتماع الساعة 14:00"، "موعد طبيب"، "حفل زفاف"، "محاضرة"\n'
            '  قاعدة: اجتماع، موعد، حفل أو حدث يتطلب حضور → حدث\n\n'
            'ملاحظة (notes) → معلومات، وصف، عنوان، ملاحظة\n\n'
            'جهة اتصال (contacts) → اسم + رقم هاتف/بريد إلكتروني\n\n'
            'قواعد التاريخ:\n'
            '- استخدم التاريخ المكتوب في الصورة كما هو.\n'
            '- "غداً"، "الجمعة القادمة" = احسبها من اليوم.\n'
            '- إذا لم يوجد تاريخ، استخدم تاريخ اليوم: $currentDate\n'
            '- إذا لم يوجد وقت للحدث، افترض 09:00.\n\n'
            'تاريخ اليوم: $currentDate، الوقت: $currentTime\n\n'
            'مخطط JSON:\n'
            '{\n'
            '  "fullTranscript": "النص الكامل في الصورة",\n'
            '  "tasks": [{"title": "وصف المهمة", "dueDate": "YYYY-MM-DD"}],\n'
            '  "notes": [{"title": "العنوان", "content": "المحتوى", "date": "YYYY-MM-DD"}],\n'
            '  "events": [{"title": "اسم الحدث", "startTime": "YYYY-MM-DDTHH:MM:SS", "endTime": "YYYY-MM-DDTHH:MM:SS"}],\n'
            '  "contacts": [{"name": "الاسم", "phone": "الهاتف"}]\n'
            '}\n\n'
            'استخرج البيانات من الصورة.';
      case 'en':
        return 'You are an expert document analyzer. Analyze the image and return data as structured JSON.\n'
            'Return ONLY JSON. Do not write any additional text.\n\n'
            'CATEGORY RULES (VERY IMPORTANT):\n'
            'Each item must belong to ONLY ONE category!\n\n'
            'TASK (tasks) → An action or job that needs to be done:\n'
            '  Examples: "Buy the bag", "Prepare the report", "Go to market", "Pay the bill"\n'
            '  Rule: If it contains verbs like BUY, DO, SEND, PREPARE → TASK\n\n'
            'EVENT (events) → An occurrence at a specific TIME and PLACE:\n'
            '  Examples: "Meeting at 2:00 PM", "Doctor appointment", "Wedding", "Concert"\n'
            '  Rule: A MEETING, APPOINTMENT, CEREMONY or attendance-required event → EVENT\n\n'
            'NOTE (notes) → Pure information, description, address, note\n\n'
            'CONTACT (contacts) → Name + phone/email info\n\n'
            'DATE RULES:\n'
            '- Use the date written in the image as-is.\n'
            '- "Tomorrow", "next Friday" = calculate from today.\n'
            '- If no date found, use today: $currentDate\n'
            '- If no event time, assume 09:00.\n\n'
            'Today\'s date: $currentDate, Time: $currentTime\n\n'
            'JSON SCHEMA:\n'
            '{\n'
            '  "fullTranscript": "Full text from the image",\n'
            '  "tasks": [{"title": "Task description", "dueDate": "YYYY-MM-DD"}],\n'
            '  "notes": [{"title": "Title", "content": "Text content", "date": "YYYY-MM-DD"}],\n'
            '  "events": [{"title": "Event name", "startTime": "YYYY-MM-DDTHH:MM:SS", "endTime": "YYYY-MM-DDTHH:MM:SS"}],\n'
            '  "contacts": [{"name": "Full Name", "phone": "Phone"}]\n'
            '}\n\n'
            'Extract data from the image.';
      default: // Turkish
        return 'Sen uzman bir Türkçe doküman analizcisisin. Görseli analiz et ve verileri yapılandırılmış JSON olarak döndür.\n'
            'SADECE JSON dön. Ek metin yazma.\n\n'
            'KATEGORİ KURALLARI (ÇOK ÖNEMLİ):\n'
            'Her öğe SADECE BİR kategoriye ait olmalı!\n\n'
            'GÖREV (tasks) → Yapılması gereken bir İŞ veya EYLEM:\n'
            '  Örnekler: "Çantayı al", "Raporu hazırla", "Markete git", "Faturayı öde",\n'
            '  "Dosyayı gönder", "Araba yıkat", "İlacı al", "Evi temizle"\n'
            '  Kural: Bir şey YAPMAK, ALMAK, GÖNDERMEK, HAZIRLAMAK gibi fiiller içeriyorsa → GÖREV\n\n'
            'ETKİNLİK (events) → Belirli bir SAAT ve YERDE katılınan/gerçekleşen olay:\n'
            '  Örnekler: "Saat 14:00 toplantı", "Doktor randevusu", "Düğün",\n'
            '  "Konser", "Ders", "Görüşme", "Seminer"\n'
            '  Kural: Bir TOPLANTI, RANDEVU, TÖREN veya katılım gerektiren bir olay → ETKİNLİK\n\n'
            'NOT (notes) → Salt bilgi, açıklama, adres, not:\n'
            '  Örnekler: "Şifre: 1234", "Adres: ...", genel metin\n\n'
            'KİŞİ (contacts) → İsim + telefon/email bilgisi\n\n'
            'TARİH KURALLARI:\n'
            '- Görselde yazılı tarihi (ör: "5 Mart", "15/03/2026") AYNEN kullan.\n'
            '- "Yarın", "önümüzdeki Cuma" gibi ifadeleri bugüne göre hesapla.\n'
            '- Tarih yoksa bugünün tarihini kullan: $currentDate\n'
            '- Etkinlik saati yoksa 09:00 varsay.\n\n'
            'Bugünün tarihi: $currentDate, Saat: $currentTime\n\n'
            'JSON ŞEMASI:\n'
            '{\n'
            '  "fullTranscript": "Görseldeki metnin tam dökümü",\n'
            '  "tasks": [{"title": "Görev açıklaması", "dueDate": "YYYY-MM-DD"}],\n'
            '  "notes": [{"title": "Başlık", "content": "Metin içeriği", "date": "YYYY-MM-DD"}],\n'
            '  "events": [{"title": "Etkinlik adı", "startTime": "YYYY-MM-DDTHH:MM:SS", "endTime": "YYYY-MM-DDTHH:MM:SS"}],\n'
            '  "contacts": [{"name": "Ad Soyad", "phone": "Telefon"}]\n'
            '}\n\n'
            'Görseldeki verileri çıkar.';
    }
  }

  Future<ImageAnalysisResult?> _analyzeWithVision(
    String imagePath, {
    String? customKey,
    String language = 'tr',
  }) async {
    // Always use native Gemini generateContent API.
    final apiKey =
        customKey?.trim() ??
        (await _configService.getVisionApiKey())?.trim() ??
        (await _configService.getApiKey())?.trim();
    final model = await _configService.getVisionModel();

    if (apiKey == null || apiKey.isEmpty) return null;

    final file = File(imagePath);
    final originalBytes = await file.readAsBytes();
    Uint8List imgBytes = originalBytes;

    try {
      final image = img.decodeImage(originalBytes);
      if (image != null && (image.width > 2000 || image.height > 2000)) {
        final resized = img.copyResize(image, width: 1600);
        imgBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
      }
    } catch (_) {}

    final base64Image = base64Encode(imgBytes);

    final now = DateTime.now();
    final currentDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final prompt = _getVisionPrompt(language, currentDate, currentTime);

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.1},
    });

    // Try configured model first on v1beta
    final baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
    var url = '$baseUrl/models/$model:generateContent?key=$apiKey';
    debugPrint('Gemini Vision: $model');

    var response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(const Duration(seconds: 60));

    // If model not found, try fallback models
    if (response.statusCode == 404) {
      final fallbackModels = [
        'gemini-2.0-flash',
        'gemini-2.5-flash',
        'gemini-2.0-flash-lite',
      ];
      for (final fallback in fallbackModels) {
        if (fallback == model) continue; // skip already tried
        url = '$baseUrl/models/$fallback:generateContent?key=$apiKey';
        debugPrint('Fallback: $fallback');
        response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 60));
        if (response.statusCode != 404) break;
      }
    }

    if (response.statusCode == 200) {
      final rawBody = utf8.decode(response.bodyBytes);
      final outerJson = jsonDecode(rawBody);

      String content = '';
      try {
        content =
            outerJson['candidates'][0]['content']['parts'][0]['text']
                ?.toString() ??
            '';
      } catch (e) {
        debugPrint('Gemini parse error: $e\nRaw: $rawBody');
      }

      final data = _extractJsonRobustly(content);
      if (data == null) {
        throw 'AI uygun formatta yanıt vermedi: ${content.substring(0, content.length > 100 ? 100 : content.length)}';
      }

      return ImageAnalysisResult(
        tasks: (data['tasks'] as List? ?? [])
            .map(
              (t) => ExtractedTask(
                title: t['title']?.toString() ?? '',
                dueDate: _tryParseDate(t['dueDate']?.toString()),
              ),
            )
            .toList(),
        notes: (data['notes'] as List? ?? [])
            .map(
              (n) => ExtractedNote(
                title: n['title']?.toString() ?? 'Not',
                content: n['content']?.toString() ?? '',
                date: _tryParseDate(n['date']?.toString()) ?? DateTime.now(),
              ),
            )
            .toList(),
        events: (data['events'] as List? ?? [])
            .map(
              (e) => ExtractedEvent(
                title: e['title']?.toString() ?? '',
                startTime: _tryParseDate(e['startTime']?.toString()),
                endTime: _tryParseDate(e['endTime']?.toString()),
              ),
            )
            .toList(),
        contacts: (data['contacts'] as List? ?? [])
            .map(
              (c) => ExtractedContact(
                name: c['name']?.toString(),
                phone: c['phone']?.toString(),
              ),
            )
            .toList(),
        rawText: data['fullTranscript']?.toString() ?? '',
      );
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      debugPrint('Gemini Vision error (${response.statusCode}): $errorBody');
      if (response.statusCode == 429) {
        throw 'API kota limiti aşıldı. Lütfen 1 dakika bekleyip tekrar deneyin.';
      }
      if (response.statusCode == 400) {
        throw 'Hata 400: Model adı geçersiz olabilir. Model: $model';
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw 'Hata ${response.statusCode}: API Anahtarı geçersiz veya yetkisiz.';
      }
      if (response.statusCode == 404) {
        throw 'Hata 404: Model bulunamadı. Ayarlardan modeli "gemini-2.0-flash" olarak değiştirin.';
      }
      throw 'API Hatası (${response.statusCode}): $errorBody';
    }
  }

  Future<void> saveTasksToDatabase(
    List<ExtractedTask> tasks, {
    String? imagePath,
  }) async {
    for (var task in tasks) {
      await _database
          .into(_database.tasks)
          .insert(
            TasksCompanion.insert(title: task.title, date: Value(task.dueDate)),
          );
    }
  }

  Future<void> saveNotesToDatabase(
    List<ExtractedNote> notes, {
    String? imagePath,
  }) async {
    for (var note in notes) {
      await _database
          .into(_database.notes)
          .insert(
            NotesCompanion.insert(
              content: '${note.title}\n${note.content}',
              date: note.date ?? DateTime.now(),
            ),
          );
    }
  }

  Future<void> saveEventsToDatabase(
    List<ExtractedEvent> events, {
    String? imagePath,
  }) async {
    for (var event in events) {
      await _database
          .into(_database.calendarEvents)
          .insert(
            CalendarEventsCompanion.insert(
              title: event.title,
              date: event.startTime ?? DateTime.now(),
              startTime: Value(event.startTime),
              endTime: Value(event.endTime),
            ),
          );
    }
  }

  Future<void> saveContactsAsNotes(
    List<ExtractedContact> contacts, {
    String? imagePath,
  }) async {
    for (var contact in contacts) {
      await _database
          .into(_database.notes)
          .insert(
            NotesCompanion.insert(
              content: 'İsim: ${contact.name}\nTel: ${contact.phone}',
              date: DateTime.now(),
            ),
          );
    }
  }
}
