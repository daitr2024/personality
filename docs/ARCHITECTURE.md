# Personality.AI — Mimari Doküman

## Genel Bakış

Personality.AI, Flutter ile geliştirilmiş kişisel asistan uygulamasıdır. Not tutma, görev yönetimi, finans takibi, takvim yönetimi ve yapay zeka destekli analiz özelliklerini bir arada sunar.

## Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| **Framework** | Flutter 3.x (Dart) |
| **State Yönetimi** | Riverpod (flutter_riverpod) |
| **Routing** | GoRouter |
| **Veritabanı** | SQLite (sqflite) |
| **Güvenli Depolama** | flutter_secure_storage |
| **AI Backend** | Google Gemini API (ses, görsel, metin) |
| **OCR** | Google ML Kit Text Recognition |
| **Ses Kaydı** | record paketi |
| **Firebase** | Crashlytics, Analytics |
| **Bildirimler** | flutter_local_notifications |
| **Lokalizasyon** | Flutter intl (ARB dosyaları) |

## Proje Yapısı

```
lib/
├── main.dart                          # Uygulama giriş noktası
├── config/                            # Uygulama konfigürasyonları
│   ├── router.dart                    # GoRouter tanımları
│   └── theme.dart                     # Tema konfigürasyonu
├── core/                              # Paylaşılan çekirdek katman
│   ├── database/                      # SQLite veritabanı helper
│   ├── exceptions/                    # Özel exception sınıfları
│   │   └── app_exceptions.dart        # ApiKeyNotSet, Network, Quota vb.
│   ├── services/                      # İş mantığı servisleri
│   │   ├── ai_config_service.dart     # AI yapılandırma & key yönetimi
│   │   ├── audio_analysis_service.dart # Ses transkripsiyonu & analizi
│   │   ├── image_analysis_service.dart # Görsel analiz (Gemini Vision)
│   │   ├── notification_service.dart  # Bildirim yönetimi
│   │   ├── receipt_scanner_service.dart# Fiş OCR tarama
│   │   ├── search_service.dart        # Arama motoru
│   │   └── ...
│   ├── utils/                         # Yardımcı fonksiyonlar
│   │   ├── api_key_scanner.dart       # OCR ile API key tarama
│   │   ├── recording_defaults.dart    # Paylaşılan ses kayıt ayarları
│   │   └── ...
│   └── widgets/                       # Paylaşılan widget'lar
├── features/                          # Feature modülleri
│   ├── calendar/                      # Takvim
│   ├── finance/                       # Gelir-gider takibi
│   ├── home/                          # Ana sayfa & smart input
│   ├── image_scan/                    # Görsel tarama
│   ├── notes/                         # Not yönetimi
│   ├── notifications/                 # Bildirim ayarları
│   ├── onboarding/                    # İlk kurulum
│   ├── search/                        # Arama
│   ├── settings/                      # Ayarlar & AI yapılandırma
│   ├── statistics/                    # İstatistikler
│   ├── tasks/                         # Görev yönetimi
│   └── voice/                         # Ses kaydı
└── l10n/                              # Lokalizasyon
    └── generated/                     # Otomatik üretilen çeviri
```

## Feature Modül Yapısı

Her feature modülü Clean Architecture prensiplerini takip eder:

```
feature_name/
├── data/
│   ├── models/          # Veri modelleri (JSON serialization)
│   └── repositories/    # Veri erişim katmanı
├── domain/              # İş kuralları (gerektiğinde)
└── presentation/
    ├── pages/           # Tam sayfa widget'lar
    ├── widgets/         # Küçük, yeniden kullanılabilir widget'lar
    └── providers/       # Riverpod provider tanımları
```

## AI Servisleri Akışı

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ SmartInputBar│───▶│AudioAnalysisServ.│───▶│  Gemini API     │
│ (ses kaydı) │    │ transcribeFile() │    │ (transcription) │
└─────────────┘    └──────────────────┘    └─────────────────┘
                          │                         │
                          ▼                         ▼
                   ┌──────────────┐         ┌───────────────┐
                   │ Error Tuple  │         │ Gemini Vision │
                   │(text, error) │         │ (image_analysis)│
                   └──────────────┘         └───────────────┘
```

### Ses Kaydı Pipeline

1. **Kayıt başlar** → `RecordingDefaults.voiceConfig` kullanılır
2. **Donanım filtreleri** → noiseSuppress + echoCancel + autoGain
3. **Sessizlik algılama** → 3 sn grace period, 3 sn silence duration
4. **Transkripsiyon** → Gemini API (en yakın/baskın ses odaklı prompt)
5. **Hata yönetimi** → `(String? text, String? error)` tuple döner

### API Key Yönetimi

- Tüm key'ler `flutter_secure_storage` ile şifrelenerek saklanır
- Birincil ve yedek (backup) API key desteği
- Ses + Görsel aynı key'i paylaşır (birleştirilmiş yapı)
- OCR ile key tarama: `ApiKeyScanner` utility sınıfı

## Güvenlik

| Öğe | Yöntem |
|-----|--------|
| API Key'ler | flutter_secure_storage (Android Keystore / iOS Keychain) |
| Ağ istekleri | HTTPS only |
| Ses kaydı | Geçici dosya, işlem sonrası siliniyor |
| OCR görüntüleri | İşlem sonrası otomatik siliniyor |

## Test Stratejisi

```
test/
├── core_utils_test.dart              # ApiKeyScanner, RecordingDefaults, Exceptions
├── currency_input_formatter_test.dart # Para birimi formatlama
├── date_utils_test.dart              # Tarih yardımcıları
├── recurrence_pattern_test.dart      # Tekrarlanan görev desenleri
└── search_results_test.dart          # Arama sonuçları
```

Tüm testler: `flutter test`
