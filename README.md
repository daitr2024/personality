# Personality.ai

<p align="center">
  <img src="assets/app_icon.png" width="120" alt="Personality.ai Logo"/>
</p>

<p align="center">
  <strong>Akıllı Kişisel Asistanınız</strong><br/>
  Görevler • Notlar • Takvim • Finans — Hepsi Yapay Zeka ile Güçlendirilmiş
</p>

---

## ✨ Özellikler

- 📝 **Akıllı Görev Yönetimi** — Sesli, yazılı veya görsel komutlarla hızla görev oluşturun
- 🗓 **Takvim Entegrasyonu** — Cihaz takvimiyle senkronize çalışma
- 📒 **Notlar & Ses Kayıtları** — Ses kayıtlarını AI ile metne dönüştürün
- 💰 **Finans Takibi** — Gelir/gider yönetimi, fiş tarama özelliği
- 📸 **Görsel Tarama** — Kameradan veya galeriden metin tanıma (OCR)
- 🤖 **Yapay Zeka Desteği** — Doğal dil ile görev oluşturma ve sınıflandırma
- 🔔 **Akıllı Bildirimler** — Görev ve etkinlik hatırlatıcıları
- 📊 **İstatistikler** — Üretkenlik analizleri ve görselleştirmeler
- 🌙 **Karanlık Mod** — Göz dostu koyu tema desteği
- 🌍 **Çoklu Dil** — Türkçe, İngilizce ve Arapça desteği
- 📱 **Ana Ekran Widget'ları** — Hızlı erişim widget'ları

## 🛠 Teknoloji

| Katman | Teknoloji |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Veritabanı | SQLite (Drift) |
| AI | Gemini API (OpenAI-uyumlu endpoint) |
| Crash Reporting | Firebase Crashlytics |
| Localization | Flutter Intl (ARB) |

## 📋 Gereksinimler

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android SDK 21+
- Gemini veya OpenAI-uyumlu bir AI API anahtarı

## 🚀 Kurulum

```bash
# Repoyu klonlayın
git clone https://github.com/daitr2024/personality.ai.git
cd personality.ai

# Bağımlılıkları yükleyin
flutter pub get

# Firebase yapılandırması (Firebase Console'dan indirin)
# android/app/google-services.json dosyasını ekleyin

# Uygulamayı çalıştırın
flutter run
```

## 📁 Proje Yapısı

```
lib/
├── config/          # Tema, router yapılandırması
├── core/            # Veritabanı, servisler, yardımcı modüller
├── features/        # Özellik modülleri
│   ├── calendar/    # Takvim
│   ├── finance/     # Finans yönetimi
│   ├── home/        # Ana sayfa & widget'lar
│   ├── image_scan/  # Görsel tarama (OCR)
│   ├── notes/       # Notlar & ses kayıtları
│   ├── search/      # Arama
│   ├── settings/    # Ayarlar
│   ├── statistics/  # İstatistikler
│   ├── tasks/       # Görev yönetimi
│   └── voice/       # Sesli giriş
├── l10n/            # Çoklu dil dosyaları (TR, EN, AR)
└── main.dart        # Uygulama giriş noktası
```

## 🔒 Gizlilik

- Tüm veriler cihazda yerel olarak saklanır (SQLite)
- Hiçbir kişisel veri sunuculara gönderilmez
- AI özellikleri kullanıldığında veriler yalnızca kullanıcının yapılandırdığı API'ye gönderilir
- [Gizlilik Politikası](docs/index.html)

## 📬 İletişim

Soru, öneri veya geri bildirimleriniz için:

📧 **daitr2024@gmail.com**

---

<p align="center">
  © 2026 Personality.ai — Tüm hakları saklıdır.
</p>
