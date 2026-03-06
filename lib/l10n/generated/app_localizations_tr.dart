// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Personality.ai';

  @override
  String get homeTitle => 'Yapılacaklar';

  @override
  String get tasksTitle => 'Görevlerim';

  @override
  String get addTaskLabel => 'Yeni Görev Ekle';

  @override
  String get noTasksMessage => 'Henüz görev yok.';

  @override
  String get calendar => 'Takvim';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get selectLanguage => 'Dil Seçin';

  @override
  String get financeTitle => 'Finans';

  @override
  String get notesTitle => 'Notlar';

  @override
  String get calendarTitle => 'Takvim';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get today => 'Bugün';

  @override
  String get tasks => 'Görevler';

  @override
  String get noTasksToday => 'Bu tarihte görev yok.';

  @override
  String get events => 'Etkinlikler';

  @override
  String get noEventsToday => 'Bu tarihte etkinlik yok.';

  @override
  String get notes => 'Notlar';

  @override
  String get noNotesToday => 'Bu tarihte not yok.';

  @override
  String get editTask => 'Görevi Düzenle';

  @override
  String get taskTitleHint => 'Görev başlığı...';

  @override
  String get edit => 'Düzenle';

  @override
  String get delete => 'Sil';

  @override
  String get unnamedEvent => 'Adsız Etkinlik';

  @override
  String get editingSoon => 'Düzenleme yakında';

  @override
  String totalUncompletedTasks(int count) {
    return 'Toplam $count tamamlanmamış görev';
  }

  @override
  String uncompletedTasks(int count) {
    return '$count tamamlanmamış görev';
  }

  @override
  String overdueTasksTitle(int count) {
    return '$count Tamamlanamayan İş';
  }

  @override
  String get overdueTasksDesc =>
      'Geçmiş tarihlerden kalan tamamlanmamış görevleriniz.';

  @override
  String get noOverdueTasks => 'Harika! Gecikmiş göreviniz yok.';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get error => 'Hata';

  @override
  String get close => 'Kapat';

  @override
  String get newEvent => 'Yeni Etkinlik Ekle';

  @override
  String get eventName => 'Etkinlik Adı';

  @override
  String get eventNameHint => 'Örn: Toplantı';

  @override
  String get date => 'Tarih';

  @override
  String get time => 'Saat';

  @override
  String get sync => 'Senkronize et';

  @override
  String get syncDesc => 'Sistem takvimine ekler';

  @override
  String noRecordsFound(String date) {
    return '$date için kayıt bulunamadı.';
  }

  @override
  String get externalEvent => 'Sistem Takvimi';

  @override
  String get event => 'Etkinlik';

  @override
  String get task => 'Görev';

  @override
  String get totalBalance => 'Toplam Bakiye';

  @override
  String get income => 'Gelir';

  @override
  String get expense => 'Gider';

  @override
  String get recentTransactions => 'Son İşlemler';

  @override
  String get noTransactions => 'Henüz işlem yok.';

  @override
  String get addNewTransaction => 'Yeni İşlem Ekle';

  @override
  String get addIncome => 'Gelir Ekle';

  @override
  String amountWithCurrency(String currency) {
    return 'Miktar ($currency)';
  }

  @override
  String get add => 'Ekle';

  @override
  String get incomeAdded => 'Gelir eklendi';

  @override
  String get cameraPermissionRequired => 'Kamera izni gerekli';

  @override
  String get receiptScanned => 'Fiş tarandı ve bilgiler dolduruldu';

  @override
  String get pleaseEnterValidValues => 'Lütfen geçerli değerler girin';

  @override
  String get receiptAdded => 'Fiş Eklendi (Değiştirmek için dokun)';

  @override
  String get scanReceipt => 'Fiş Tara (Otomatik Doldur)';

  @override
  String get description => 'Açıklama';

  @override
  String get descriptionHint =>
      'Fişten otomatik alınır veya manuel girilir (Maks 40)';

  @override
  String get amount => 'Tutar';

  @override
  String get category => 'Kategori';

  @override
  String get categoryMarket => 'Market';

  @override
  String get categoryRent => 'Kira';

  @override
  String get categoryBill => 'Fatura';

  @override
  String get categorySalary => 'Maaş';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get incomeAddition => 'Gelir Eklemesi';

  @override
  String get aiAnalysisTitle => 'Yapay Zeka Analizi';

  @override
  String get analysingContent => 'İçerik analiz ediliyor...';

  @override
  String get analysisFailedOrEmpty => 'Analiz yapılamadı veya içerik boş.';

  @override
  String get saveSelected => 'Seçilenleri Kaydet';

  @override
  String get unknownError => 'Bilinmeyen hata';

  @override
  String itemsSavedCount(int count) {
    return '$count öğe kaydedildi!';
  }

  @override
  String get updatedAndClassified => 'Güncellendi ve sınıflandırıldı';

  @override
  String get noDateSelectedNoteHint =>
      'Tarih seçilmedi (Not olarak kaydedilir)';

  @override
  String get pickDate => 'Tarih Seç';

  @override
  String get editItemTip =>
      'İPUCU: Tarih seçerseniz GÖREV, seçmezseniz NOT olarak kaydedilir.';

  @override
  String get alreadyExists => 'Zaten mevcut';

  @override
  String get noDate => 'Tarih yok';

  @override
  String get editNote => 'Notu Düzenle';

  @override
  String get addNewNote => 'Yeni Not Ekle';

  @override
  String get noteHint => 'Notunuzu buraya yazın...';

  @override
  String get quickAudioNote => 'Hızlı Ses Kaydı';

  @override
  String get tapToRecord => 'Kaydetmek için mikrofona dokunun.';

  @override
  String get audioNoteAddedNoText =>
      'Ses kaydı notlara eklendi! (Analiz için metin yok)';

  @override
  String get listening => 'Dinleniyor...';

  @override
  String get smartInputHint => 'Hızlı Ekle (Toplantı, Görev, Not...)';

  @override
  String get voiceNote => 'Sesli Not';

  @override
  String get note => 'Not';

  @override
  String get complete => 'Tamamla';

  @override
  String get undo => 'Geri Al';

  @override
  String get dataRefreshed => 'Veriler güncellendi';

  @override
  String get aiConfiguration => 'AI Yapılandırması';

  @override
  String get aiConfigSubtitle => 'API ayarları ve model seçimi';

  @override
  String get accountInfo => 'Hesap Bilgileri';

  @override
  String get accountInfoSubtitle =>
      'Profil bilgilerini ve e-posta ayarlarını düzenleyin';

  @override
  String get clearReceiptImages => 'Fiş Görsellerini Temizle';

  @override
  String get clearReceiptsTitle => 'Fişleri Temizle';

  @override
  String get clearReceiptsConfirm =>
      'Cihazda saklanan tüm fiş görselleri silinecek. Bu işlem geri alınamaz.';

  @override
  String get allImagesCleared => 'Tüm görseller temizlendi';

  @override
  String get tagManagement => 'Etiket Yönetimi';

  @override
  String get tagManagementSubtitle =>
      'Görevleri kategorize etmek için kullanılan etiketler';

  @override
  String get backupAndRestore => 'Veri Yedekleme ve Geri Yükleme';

  @override
  String get backupAndRestoreSubtitle =>
      'Veritabanı ve medya dosyalarınızı saklayın veya geri yükleyin';

  @override
  String get aboutApp => 'Hakkında';

  @override
  String get backupAndRestoreTitle => 'Yedekleme ve Geri Yükleme';

  @override
  String get backupNow => 'Şimdi Yedekle';

  @override
  String get backupNowSubtitle => 'Tüm verilerinizi ZIP olarak dışa aktarır';

  @override
  String backupError(String error) {
    return 'Yedekleme hatası: $error';
  }

  @override
  String get restoreFromBackup => 'Yedekten Geri Yükle';

  @override
  String get restoreFromBackupSubtitle => 'Seçilen yedek dosyasını geri yükler';

  @override
  String get restoreConfirmTitle => 'Geri Yükle?';

  @override
  String get restoreConfirmMessage =>
      'Mevcut verileriniz silinecek ve yedek dosyasındakilerle değiştirilecek. İşlemden sonra uygulama kapatılacaktır.';

  @override
  String get restoreSuccessTitle => 'Geri Yükleme Başarılı';

  @override
  String get restoreSuccessMessage =>
      'Verileriniz geri yüklendi. Değişikliklerin etkili olması için lütfen uygulamayı tamamen kapatıp tekrar açın.';

  @override
  String get closeApp => 'Uygulamayı Kapat';

  @override
  String restoreError(String error) {
    return 'Geri yükleme hatası: $error';
  }

  @override
  String get calendarSync => 'Takvim Senkronizasyonu';

  @override
  String get enableSync => 'Senkronizasyonu Etkinleştir';

  @override
  String get enableSyncSubtitle => 'Etkinlikleri cihaz takvimiyle paylaşır';

  @override
  String get selectTargetCalendar => 'Hedef Takvim Seçin';

  @override
  String get noCalendarFound => 'Takvim bulunamadı veya izin verilmedi.';

  @override
  String get unnamedCalendar => 'Adsız Takvim';

  @override
  String get syncAllOldRecords => 'Tüm Eski Kayıtları Senkronize Et';

  @override
  String eventsSynced(int count) {
    return '$count etkinlik senkronize edildi.';
  }

  @override
  String get noEventsToSync => 'Senkronize edilecek yeni etkinlik yok.';

  @override
  String get resetToDefaults => 'Varsayılana Dön';

  @override
  String get resetConfirmTitle => 'Varsayılana Dön';

  @override
  String get resetConfirmMessage =>
      'Tüm AI ayarları varsayılan değerlere sıfırlanacak. Devam etmek istiyor musunuz?';

  @override
  String get reset => 'Sıfırla';

  @override
  String get settingsResetSuccess => 'Ayarlar varsayılan değerlere sıfırlandı';

  @override
  String get connectionSuccess => 'Bağlantı başarılı! ✓';

  @override
  String get connectionFailed =>
      'Bağlantı başarısız. Lütfen ayarları kontrol edin.';

  @override
  String get testConnection => 'Bağlantıyı Test Et';

  @override
  String get testing => 'Test ediliyor...';

  @override
  String get apiEndpoint => 'API Endpoint / IP';

  @override
  String get apiEndpointHint => 'AI servisinin API endpoint adresi';

  @override
  String get apiKey => 'API Key';

  @override
  String get apiKeySecureHint => 'API anahtarınız güvenli şekilde saklanır';

  @override
  String get model => 'Model';

  @override
  String get temperature => 'Temperature';

  @override
  String get temperatureHint =>
      'Düşük değerler daha tutarlı, yüksek değerler daha yaratıcı yanıtlar verir';

  @override
  String get maxTokens => 'Max Tokens';

  @override
  String get maxTokensHint =>
      'Maksimum yanıt uzunluğu (daha yüksek = daha uzun yanıtlar)';

  @override
  String get apiKeySecureInfo =>
      'API anahtarınız cihazınızda güvenli şekilde şifrelenerek saklanır. Hiçbir zaman sunuculara gönderilmez.';

  @override
  String get reminder => 'Hatırlatıcı';

  @override
  String get reminderTime => 'Hatırlatma Zamanı';

  @override
  String get notSelected => 'Seçilmedi';

  @override
  String minutesBefore(int minutes) {
    return '$minutes dakika önce';
  }

  @override
  String get onTime => 'Tam vaktinde';

  @override
  String get howManyMinutesBefore => 'Kaç dakika önce?';

  @override
  String get editEvent => 'Etkinliği Düzenle';

  @override
  String get title => 'Başlık';

  @override
  String nearFuture(int count) {
    return 'Yakın Gelecek ($count Kayıt)';
  }

  @override
  String get nearFutureSchedule => 'Yakın Gelecek Programı';

  @override
  String get profileInfo => 'Profil Bilgileri';

  @override
  String get profileInfoSubtitle =>
      'Yedeklerinizi farklı cihazlarda doğrulamak için bilgilerini kaydedin.';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get email => 'E-posta';

  @override
  String get infoUpdated => 'Bilgiler güncellendi';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get aboutAppTitle => 'Personality.ai Hakkında';

  @override
  String get version => 'Versiyon';

  @override
  String get developer => 'Geliştirici';

  @override
  String get privacyPolicyContent =>
      'Bu uygulama kişisel verilerinizi cihazınızda güvenle saklar. Hiçbir veri sunuculara gönderilmez. AI özellikleri kullandığınızda, veriler yalnızca sizin yapılandırdığınız API\'ye gönderilir.';

  @override
  String get newTaskTitle => 'Yeni Görev Ekle';

  @override
  String get urgentTask => 'Acil Görev';

  @override
  String get reminderActive => 'Hatırlatıcı Aktif';

  @override
  String get recurrenceInterval => 'Tekrar Aralığı';

  @override
  String get whichDays => 'Hangi Günler?';

  @override
  String get startDate => 'Başlangıç Tarihi';

  @override
  String get routineTime => 'Rutin Saat';

  @override
  String get endDateOptional => 'Bitiş Tarihi (Opsiyonel)';

  @override
  String get pleaseEnterTitle => 'Lütfen bir başlık girin';

  @override
  String get selectEndDateFirst => 'Önce bitiş tarihi seçiniz';

  @override
  String get recurring => 'Tekrarlayan';

  @override
  String get daily => 'Günlük';

  @override
  String get weekly => 'Haftalık';

  @override
  String get selectEnd => 'Bitiş Seç';

  @override
  String get endNone => 'Süresiz';

  @override
  String get analyzing => 'Analiz ediliyor...';

  @override
  String get archiveTasks => 'Arşiv Görevler';

  @override
  String get statistics => 'İstatistikler';

  @override
  String get themeSettings => 'Tema Ayarları';

  @override
  String get appPermissions => 'Uygulama İzinleri';

  @override
  String get managePermissions =>
      'Kamera, Rehber, Mikrofon vb. izinleri yönetin';

  @override
  String get openSystemSettings => 'Sistem Ayarlarını Aç';

  @override
  String get appNotes => 'Uygulama Notları';

  @override
  String get deleteAttachment => 'Eki Sil';

  @override
  String get takePhoto => 'Fotoğraf Çek';

  @override
  String get chooseFromGallery => 'Galeriden Seç';

  @override
  String get chooseFile => 'Dosya Seç';

  @override
  String get chooseAudioFile => 'Ses Dosyası Seç';

  @override
  String get chooseVideo => 'Video Çek/Seç';

  @override
  String get otherFiles => 'Diğer Dosyalar';

  @override
  String get attachmentAdded => 'Ek başarıyla eklendi';

  @override
  String get addFile => 'Dosya Ekle';

  @override
  String get deleteMedia => 'Media Sil';

  @override
  String get search => 'Arama';

  @override
  String searchError(String error) {
    return 'Arama hatası: $error';
  }

  @override
  String get deleteTransaction => 'İşlemi Sil?';

  @override
  String get deleteTransactionConfirm =>
      'Bu finansal işlem kalıcı olarak silinecektir.';

  @override
  String get microphonePermissionRequired => 'Mikrofon izni gerekli!';

  @override
  String transcriptionError(int code) {
    return 'Çeviri hatası: $code';
  }

  @override
  String get aiTranscribing => 'Yapay Zeka sesi metne dönüştürüyor...';

  @override
  String errorGeneric(String msg) {
    return 'Hata: $msg';
  }

  @override
  String errorOccurred(String msg) {
    return 'Hata oluştu: $msg';
  }

  @override
  String errLoadSettings(String error) {
    return 'Ayarlar yüklenirken hata oluştu: $error';
  }

  @override
  String get alwaysUseLocalAudio => 'Her Zaman Yerel Ses Analizi Kullan';

  @override
  String get testBackupConnection => 'Yedek Bağlantıyı Test Et';

  @override
  String get testVisionConnection => 'Vision Bağlantısını Test Et';

  @override
  String get aiGuide => 'Yapay Zeka Rehberi';

  @override
  String get understood => 'Anladım';

  @override
  String savedSuccessCount(int tasks, int notes, int events) {
    return '$tasks görev, $notes not, $events etkinlik başarıyla kaydedildi!';
  }

  @override
  String saveError(String error) {
    return 'Kaydetme hatası: $error';
  }

  @override
  String get imageFileNotFound => 'Görsel dosyası bulunamadı.';

  @override
  String contactSaveError(String error) {
    return 'Rehber kaydetme hatası: $error';
  }

  @override
  String get newScan => 'Yeni Tarama';

  @override
  String saveItems(int count) {
    return 'Seçilenleri Kaydet ($count)';
  }

  @override
  String get selectItems => 'Öğe Seçin';

  @override
  String get saveContactsHint =>
      'Kişileri sağdaki butonlarla rehbere kaydedin.';

  @override
  String get drawAreaHint =>
      'İsteğe bağlı: Analiz edilecek alanı çizerek seçebilirsiniz.';

  @override
  String get analyzeAll => 'TÜMÜNÜ ANALİZ ET';

  @override
  String get selectedArea => 'SEÇİLİ ALAN';

  @override
  String get scannedText => 'Taranan Metin';

  @override
  String get showOriginalImage => 'Orijinal Görseli Göster';

  @override
  String get selectAll => 'Tümünü Seç';

  @override
  String get deselectAll => 'Tümünü Kaldır';

  @override
  String get contacts => 'Kişiler';

  @override
  String get saveToContacts => 'Rehbere Kaydet';

  @override
  String get contactSaved => 'Kişi rehbere kaydedildi';

  @override
  String get contactPermissionRequired => 'Rehber izni gerekli';

  @override
  String get eventDeleted => 'Etkinlik silindi';

  @override
  String get eventUpdated => 'Etkinlik güncellendi';

  @override
  String get back => 'Geri';

  @override
  String get onboardingComplete => 'Başlayalım';

  @override
  String get apiKeyNotSet =>
      'API anahtarı ayarlanmamış. Ayarlar > AI Ayarları\'ndan API anahtarınızı girin.';

  @override
  String get apiQuotaExceeded =>
      'API kota limiti aşıldı. Lütfen 1 dakika bekleyip tekrar deneyin.';

  @override
  String get apiParseError => 'AI yanıtı ayrıştırılamadı.';

  @override
  String apiError(int code) {
    return 'API Hatası ($code)';
  }

  @override
  String analysisError(String error) {
    return 'Analiz hatası: $error';
  }

  @override
  String mediaFilesCount(int count) {
    return 'Media Dosyaları ($count)';
  }

  @override
  String get addMedia => 'Media Ekle';

  @override
  String get noMediaYet => 'Henüz media eklenmemiş';

  @override
  String get fileAddedSuccess => 'Dosya başarıyla eklendi';

  @override
  String get fileNotFound => 'Dosya bulunamadı';

  @override
  String fileOpenFail(String msg) {
    return 'Dosya açılamadı: $msg';
  }

  @override
  String get openFile => 'Aç';

  @override
  String imageLabel(String name) {
    return 'Resim: $name';
  }

  @override
  String audioFileLabel(String name) {
    return 'Ses dosyası: $name';
  }

  @override
  String fileLabel(String name) {
    return 'Dosya: $name';
  }

  @override
  String get deleteAttachmentSemantic => 'Eki sil';

  @override
  String get audioAttachment => 'Ses eki';

  @override
  String get imageAttachment => 'Resim eki';

  @override
  String get fileAttachment => 'Dosya eki';

  @override
  String attachmentCount(int count) {
    return '$count ek';
  }

  @override
  String get statusCompleted => 'tamamlandı';

  @override
  String get statusUrgent => 'acil';

  @override
  String dateLabelFmt(String date) {
    return 'Tarih: $date';
  }

  @override
  String timeLabelFmt(String time) {
    return 'Saat: $time';
  }

  @override
  String deleteConfirmFile(String name) {
    return '\"$name\" dosyasını silmek istiyor musunuz?';
  }
}
