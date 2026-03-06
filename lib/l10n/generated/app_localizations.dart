import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personality.ai'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yapılacaklar'**
  String get homeTitle;

  /// No description provided for @tasksTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görevlerim'**
  String get tasksTitle;

  /// No description provided for @addTaskLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Görev Ekle'**
  String get addTaskLabel;

  /// No description provided for @noTasksMessage.
  ///
  /// In tr, this message translates to:
  /// **'Henüz görev yok.'**
  String get noTasksMessage;

  /// No description provided for @calendar.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get calendar;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil Seçin'**
  String get selectLanguage;

  /// No description provided for @financeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Finans'**
  String get financeTitle;

  /// No description provided for @notesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get notesTitle;

  /// No description provided for @calendarTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get calendarTitle;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @tasks.
  ///
  /// In tr, this message translates to:
  /// **'Görevler'**
  String get tasks;

  /// No description provided for @noTasksToday.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarihte görev yok.'**
  String get noTasksToday;

  /// No description provided for @events.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler'**
  String get events;

  /// No description provided for @noEventsToday.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarihte etkinlik yok.'**
  String get noEventsToday;

  /// No description provided for @notes.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get notes;

  /// No description provided for @noNotesToday.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarihte not yok.'**
  String get noNotesToday;

  /// No description provided for @editTask.
  ///
  /// In tr, this message translates to:
  /// **'Görevi Düzenle'**
  String get editTask;

  /// No description provided for @taskTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Görev başlığı...'**
  String get taskTitleHint;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @unnamedEvent.
  ///
  /// In tr, this message translates to:
  /// **'Adsız Etkinlik'**
  String get unnamedEvent;

  /// No description provided for @editingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Düzenleme yakında'**
  String get editingSoon;

  /// No description provided for @totalUncompletedTasks.
  ///
  /// In tr, this message translates to:
  /// **'Toplam {count} tamamlanmamış görev'**
  String totalUncompletedTasks(int count);

  /// No description provided for @uncompletedTasks.
  ///
  /// In tr, this message translates to:
  /// **'{count} tamamlanmamış görev'**
  String uncompletedTasks(int count);

  /// No description provided for @overdueTasksTitle.
  ///
  /// In tr, this message translates to:
  /// **'{count} Tamamlanamayan İş'**
  String overdueTasksTitle(int count);

  /// No description provided for @overdueTasksDesc.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş tarihlerden kalan tamamlanmamış görevleriniz.'**
  String get overdueTasksDesc;

  /// No description provided for @noOverdueTasks.
  ///
  /// In tr, this message translates to:
  /// **'Harika! Gecikmiş göreviniz yok.'**
  String get noOverdueTasks;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @newEvent.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Etkinlik Ekle'**
  String get newEvent;

  /// No description provided for @eventName.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Adı'**
  String get eventName;

  /// No description provided for @eventNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Toplantı'**
  String get eventNameHint;

  /// No description provided for @date.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get date;

  /// No description provided for @time.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get time;

  /// No description provided for @sync.
  ///
  /// In tr, this message translates to:
  /// **'Senkronize et'**
  String get sync;

  /// No description provided for @syncDesc.
  ///
  /// In tr, this message translates to:
  /// **'Sistem takvimine ekler'**
  String get syncDesc;

  /// No description provided for @noRecordsFound.
  ///
  /// In tr, this message translates to:
  /// **'{date} için kayıt bulunamadı.'**
  String noRecordsFound(String date);

  /// No description provided for @externalEvent.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Takvimi'**
  String get externalEvent;

  /// No description provided for @event.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik'**
  String get event;

  /// No description provided for @task.
  ///
  /// In tr, this message translates to:
  /// **'Görev'**
  String get task;

  /// No description provided for @totalBalance.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Bakiye'**
  String get totalBalance;

  /// No description provided for @income.
  ///
  /// In tr, this message translates to:
  /// **'Gelir'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In tr, this message translates to:
  /// **'Gider'**
  String get expense;

  /// No description provided for @recentTransactions.
  ///
  /// In tr, this message translates to:
  /// **'Son İşlemler'**
  String get recentTransactions;

  /// No description provided for @noTransactions.
  ///
  /// In tr, this message translates to:
  /// **'Henüz işlem yok.'**
  String get noTransactions;

  /// No description provided for @addNewTransaction.
  ///
  /// In tr, this message translates to:
  /// **'Yeni İşlem Ekle'**
  String get addNewTransaction;

  /// No description provided for @addIncome.
  ///
  /// In tr, this message translates to:
  /// **'Gelir Ekle'**
  String get addIncome;

  /// No description provided for @amountWithCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Miktar ({currency})'**
  String amountWithCurrency(String currency);

  /// No description provided for @add.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get add;

  /// No description provided for @incomeAdded.
  ///
  /// In tr, this message translates to:
  /// **'Gelir eklendi'**
  String get incomeAdded;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kamera izni gerekli'**
  String get cameraPermissionRequired;

  /// No description provided for @receiptScanned.
  ///
  /// In tr, this message translates to:
  /// **'Fiş tarandı ve bilgiler dolduruldu'**
  String get receiptScanned;

  /// No description provided for @pleaseEnterValidValues.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen geçerli değerler girin'**
  String get pleaseEnterValidValues;

  /// No description provided for @receiptAdded.
  ///
  /// In tr, this message translates to:
  /// **'Fiş Eklendi (Değiştirmek için dokun)'**
  String get receiptAdded;

  /// No description provided for @scanReceipt.
  ///
  /// In tr, this message translates to:
  /// **'Fiş Tara (Otomatik Doldur)'**
  String get scanReceipt;

  /// No description provided for @description.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In tr, this message translates to:
  /// **'Fişten otomatik alınır veya manuel girilir (Maks 40)'**
  String get descriptionHint;

  /// No description provided for @amount.
  ///
  /// In tr, this message translates to:
  /// **'Tutar'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @categoryMarket.
  ///
  /// In tr, this message translates to:
  /// **'Market'**
  String get categoryMarket;

  /// No description provided for @categoryRent.
  ///
  /// In tr, this message translates to:
  /// **'Kira'**
  String get categoryRent;

  /// No description provided for @categoryBill.
  ///
  /// In tr, this message translates to:
  /// **'Fatura'**
  String get categoryBill;

  /// No description provided for @categorySalary.
  ///
  /// In tr, this message translates to:
  /// **'Maaş'**
  String get categorySalary;

  /// No description provided for @categoryOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get categoryOther;

  /// No description provided for @incomeAddition.
  ///
  /// In tr, this message translates to:
  /// **'Gelir Eklemesi'**
  String get incomeAddition;

  /// No description provided for @aiAnalysisTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zeka Analizi'**
  String get aiAnalysisTitle;

  /// No description provided for @analysingContent.
  ///
  /// In tr, this message translates to:
  /// **'İçerik analiz ediliyor...'**
  String get analysingContent;

  /// No description provided for @analysisFailedOrEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Analiz yapılamadı veya içerik boş.'**
  String get analysisFailedOrEmpty;

  /// No description provided for @saveSelected.
  ///
  /// In tr, this message translates to:
  /// **'Seçilenleri Kaydet'**
  String get saveSelected;

  /// No description provided for @unknownError.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen hata'**
  String get unknownError;

  /// No description provided for @itemsSavedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} öğe kaydedildi!'**
  String itemsSavedCount(int count);

  /// No description provided for @updatedAndClassified.
  ///
  /// In tr, this message translates to:
  /// **'Güncellendi ve sınıflandırıldı'**
  String get updatedAndClassified;

  /// No description provided for @noDateSelectedNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seçilmedi (Not olarak kaydedilir)'**
  String get noDateSelectedNoteHint;

  /// No description provided for @pickDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih Seç'**
  String get pickDate;

  /// No description provided for @editItemTip.
  ///
  /// In tr, this message translates to:
  /// **'İPUCU: Tarih seçerseniz GÖREV, seçmezseniz NOT olarak kaydedilir.'**
  String get editItemTip;

  /// No description provided for @alreadyExists.
  ///
  /// In tr, this message translates to:
  /// **'Zaten mevcut'**
  String get alreadyExists;

  /// No description provided for @noDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih yok'**
  String get noDate;

  /// No description provided for @editNote.
  ///
  /// In tr, this message translates to:
  /// **'Notu Düzenle'**
  String get editNote;

  /// No description provided for @addNewNote.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Not Ekle'**
  String get addNewNote;

  /// No description provided for @noteHint.
  ///
  /// In tr, this message translates to:
  /// **'Notunuzu buraya yazın...'**
  String get noteHint;

  /// No description provided for @quickAudioNote.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Ses Kaydı'**
  String get quickAudioNote;

  /// No description provided for @tapToRecord.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetmek için mikrofona dokunun.'**
  String get tapToRecord;

  /// No description provided for @audioNoteAddedNoText.
  ///
  /// In tr, this message translates to:
  /// **'Ses kaydı notlara eklendi! (Analiz için metin yok)'**
  String get audioNoteAddedNoText;

  /// No description provided for @listening.
  ///
  /// In tr, this message translates to:
  /// **'Dinleniyor...'**
  String get listening;

  /// No description provided for @smartInputHint.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Ekle (Toplantı, Görev, Not...)'**
  String get smartInputHint;

  /// No description provided for @voiceNote.
  ///
  /// In tr, this message translates to:
  /// **'Sesli Not'**
  String get voiceNote;

  /// No description provided for @note.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get note;

  /// No description provided for @complete.
  ///
  /// In tr, this message translates to:
  /// **'Tamamla'**
  String get complete;

  /// No description provided for @undo.
  ///
  /// In tr, this message translates to:
  /// **'Geri Al'**
  String get undo;

  /// No description provided for @dataRefreshed.
  ///
  /// In tr, this message translates to:
  /// **'Veriler güncellendi'**
  String get dataRefreshed;

  /// No description provided for @aiConfiguration.
  ///
  /// In tr, this message translates to:
  /// **'AI Yapılandırması'**
  String get aiConfiguration;

  /// No description provided for @aiConfigSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'API ayarları ve model seçimi'**
  String get aiConfigSubtitle;

  /// No description provided for @accountInfo.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Bilgileri'**
  String get accountInfo;

  /// No description provided for @accountInfoSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil bilgilerini ve e-posta ayarlarını düzenleyin'**
  String get accountInfoSubtitle;

  /// No description provided for @clearReceiptImages.
  ///
  /// In tr, this message translates to:
  /// **'Fiş Görsellerini Temizle'**
  String get clearReceiptImages;

  /// No description provided for @clearReceiptsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fişleri Temizle'**
  String get clearReceiptsTitle;

  /// No description provided for @clearReceiptsConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Cihazda saklanan tüm fiş görselleri silinecek. Bu işlem geri alınamaz.'**
  String get clearReceiptsConfirm;

  /// No description provided for @allImagesCleared.
  ///
  /// In tr, this message translates to:
  /// **'Tüm görseller temizlendi'**
  String get allImagesCleared;

  /// No description provided for @tagManagement.
  ///
  /// In tr, this message translates to:
  /// **'Etiket Yönetimi'**
  String get tagManagement;

  /// No description provided for @tagManagementSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Görevleri kategorize etmek için kullanılan etiketler'**
  String get tagManagementSubtitle;

  /// No description provided for @backupAndRestore.
  ///
  /// In tr, this message translates to:
  /// **'Veri Yedekleme ve Geri Yükleme'**
  String get backupAndRestore;

  /// No description provided for @backupAndRestoreSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Veritabanı ve medya dosyalarınızı saklayın veya geri yükleyin'**
  String get backupAndRestoreSubtitle;

  /// No description provided for @aboutApp.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get aboutApp;

  /// No description provided for @backupAndRestoreTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme ve Geri Yükleme'**
  String get backupAndRestoreTitle;

  /// No description provided for @backupNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Yedekle'**
  String get backupNow;

  /// No description provided for @backupNowSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verilerinizi ZIP olarak dışa aktarır'**
  String get backupNowSubtitle;

  /// No description provided for @backupError.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme hatası: {error}'**
  String backupError(String error);

  /// No description provided for @restoreFromBackup.
  ///
  /// In tr, this message translates to:
  /// **'Yedekten Geri Yükle'**
  String get restoreFromBackup;

  /// No description provided for @restoreFromBackupSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen yedek dosyasını geri yükler'**
  String get restoreFromBackupSubtitle;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geri Yükle?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut verileriniz silinecek ve yedek dosyasındakilerle değiştirilecek. İşlemden sonra uygulama kapatılacaktır.'**
  String get restoreConfirmMessage;

  /// No description provided for @restoreSuccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geri Yükleme Başarılı'**
  String get restoreSuccessTitle;

  /// No description provided for @restoreSuccessMessage.
  ///
  /// In tr, this message translates to:
  /// **'Verileriniz geri yüklendi. Değişikliklerin etkili olması için lütfen uygulamayı tamamen kapatıp tekrar açın.'**
  String get restoreSuccessMessage;

  /// No description provided for @closeApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Kapat'**
  String get closeApp;

  /// No description provided for @restoreError.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme hatası: {error}'**
  String restoreError(String error);

  /// No description provided for @calendarSync.
  ///
  /// In tr, this message translates to:
  /// **'Takvim Senkronizasyonu'**
  String get calendarSync;

  /// No description provided for @enableSync.
  ///
  /// In tr, this message translates to:
  /// **'Senkronizasyonu Etkinleştir'**
  String get enableSync;

  /// No description provided for @enableSyncSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikleri cihaz takvimiyle paylaşır'**
  String get enableSyncSubtitle;

  /// No description provided for @selectTargetCalendar.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Takvim Seçin'**
  String get selectTargetCalendar;

  /// No description provided for @noCalendarFound.
  ///
  /// In tr, this message translates to:
  /// **'Takvim bulunamadı veya izin verilmedi.'**
  String get noCalendarFound;

  /// No description provided for @unnamedCalendar.
  ///
  /// In tr, this message translates to:
  /// **'Adsız Takvim'**
  String get unnamedCalendar;

  /// No description provided for @syncAllOldRecords.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Eski Kayıtları Senkronize Et'**
  String get syncAllOldRecords;

  /// No description provided for @eventsSynced.
  ///
  /// In tr, this message translates to:
  /// **'{count} etkinlik senkronize edildi.'**
  String eventsSynced(int count);

  /// No description provided for @noEventsToSync.
  ///
  /// In tr, this message translates to:
  /// **'Senkronize edilecek yeni etkinlik yok.'**
  String get noEventsToSync;

  /// No description provided for @resetToDefaults.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılana Dön'**
  String get resetToDefaults;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılana Dön'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Tüm AI ayarları varsayılan değerlere sıfırlanacak. Devam etmek istiyor musunuz?'**
  String get resetConfirmMessage;

  /// No description provided for @reset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get reset;

  /// No description provided for @settingsResetSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar varsayılan değerlere sıfırlandı'**
  String get settingsResetSuccess;

  /// No description provided for @connectionSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı başarılı! ✓'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı başarısız. Lütfen ayarları kontrol edin.'**
  String get connectionFailed;

  /// No description provided for @testConnection.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı Test Et'**
  String get testConnection;

  /// No description provided for @testing.
  ///
  /// In tr, this message translates to:
  /// **'Test ediliyor...'**
  String get testing;

  /// No description provided for @apiEndpoint.
  ///
  /// In tr, this message translates to:
  /// **'API Endpoint / IP'**
  String get apiEndpoint;

  /// No description provided for @apiEndpointHint.
  ///
  /// In tr, this message translates to:
  /// **'AI servisinin API endpoint adresi'**
  String get apiEndpointHint;

  /// No description provided for @apiKey.
  ///
  /// In tr, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @apiKeySecureHint.
  ///
  /// In tr, this message translates to:
  /// **'API anahtarınız güvenli şekilde saklanır'**
  String get apiKeySecureHint;

  /// No description provided for @model.
  ///
  /// In tr, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @temperature.
  ///
  /// In tr, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @temperatureHint.
  ///
  /// In tr, this message translates to:
  /// **'Düşük değerler daha tutarlı, yüksek değerler daha yaratıcı yanıtlar verir'**
  String get temperatureHint;

  /// No description provided for @maxTokens.
  ///
  /// In tr, this message translates to:
  /// **'Max Tokens'**
  String get maxTokens;

  /// No description provided for @maxTokensHint.
  ///
  /// In tr, this message translates to:
  /// **'Maksimum yanıt uzunluğu (daha yüksek = daha uzun yanıtlar)'**
  String get maxTokensHint;

  /// No description provided for @apiKeySecureInfo.
  ///
  /// In tr, this message translates to:
  /// **'API anahtarınız cihazınızda güvenli şekilde şifrelenerek saklanır. Hiçbir zaman sunuculara gönderilmez.'**
  String get apiKeySecureInfo;

  /// No description provided for @reminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı'**
  String get reminder;

  /// No description provided for @reminderTime.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma Zamanı'**
  String get reminderTime;

  /// No description provided for @notSelected.
  ///
  /// In tr, this message translates to:
  /// **'Seçilmedi'**
  String get notSelected;

  /// No description provided for @minutesBefore.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dakika önce'**
  String minutesBefore(int minutes);

  /// No description provided for @onTime.
  ///
  /// In tr, this message translates to:
  /// **'Tam vaktinde'**
  String get onTime;

  /// No description provided for @howManyMinutesBefore.
  ///
  /// In tr, this message translates to:
  /// **'Kaç dakika önce?'**
  String get howManyMinutesBefore;

  /// No description provided for @editEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliği Düzenle'**
  String get editEvent;

  /// No description provided for @title.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get title;

  /// No description provided for @nearFuture.
  ///
  /// In tr, this message translates to:
  /// **'Yakın Gelecek ({count} Kayıt)'**
  String nearFuture(int count);

  /// No description provided for @nearFutureSchedule.
  ///
  /// In tr, this message translates to:
  /// **'Yakın Gelecek Programı'**
  String get nearFutureSchedule;

  /// No description provided for @profileInfo.
  ///
  /// In tr, this message translates to:
  /// **'Profil Bilgileri'**
  String get profileInfo;

  /// No description provided for @profileInfoSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedeklerinizi farklı cihazlarda doğrulamak için bilgilerini kaydedin.'**
  String get profileInfoSubtitle;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @infoUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Bilgiler güncellendi'**
  String get infoUpdated;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @aboutAppTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personality.ai Hakkında'**
  String get aboutAppTitle;

  /// No description provided for @version.
  ///
  /// In tr, this message translates to:
  /// **'Versiyon'**
  String get version;

  /// No description provided for @developer.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici'**
  String get developer;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu uygulama kişisel verilerinizi cihazınızda güvenle saklar. Hiçbir veri sunuculara gönderilmez. AI özellikleri kullandığınızda, veriler yalnızca sizin yapılandırdığınız API\'ye gönderilir.'**
  String get privacyPolicyContent;

  /// No description provided for @newTaskTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Görev Ekle'**
  String get newTaskTitle;

  /// No description provided for @urgentTask.
  ///
  /// In tr, this message translates to:
  /// **'Acil Görev'**
  String get urgentTask;

  /// No description provided for @reminderActive.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı Aktif'**
  String get reminderActive;

  /// No description provided for @recurrenceInterval.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Aralığı'**
  String get recurrenceInterval;

  /// No description provided for @whichDays.
  ///
  /// In tr, this message translates to:
  /// **'Hangi Günler?'**
  String get whichDays;

  /// No description provided for @startDate.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç Tarihi'**
  String get startDate;

  /// No description provided for @routineTime.
  ///
  /// In tr, this message translates to:
  /// **'Rutin Saat'**
  String get routineTime;

  /// No description provided for @endDateOptional.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş Tarihi (Opsiyonel)'**
  String get endDateOptional;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir başlık girin'**
  String get pleaseEnterTitle;

  /// No description provided for @selectEndDateFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce bitiş tarihi seçiniz'**
  String get selectEndDateFirst;

  /// No description provided for @recurring.
  ///
  /// In tr, this message translates to:
  /// **'Tekrarlayan'**
  String get recurring;

  /// No description provided for @daily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get weekly;

  /// No description provided for @selectEnd.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş Seç'**
  String get selectEnd;

  /// No description provided for @endNone.
  ///
  /// In tr, this message translates to:
  /// **'Süresiz'**
  String get endNone;

  /// No description provided for @analyzing.
  ///
  /// In tr, this message translates to:
  /// **'Analiz ediliyor...'**
  String get analyzing;

  /// No description provided for @archiveTasks.
  ///
  /// In tr, this message translates to:
  /// **'Arşiv Görevler'**
  String get archiveTasks;

  /// No description provided for @statistics.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get statistics;

  /// No description provided for @themeSettings.
  ///
  /// In tr, this message translates to:
  /// **'Tema Ayarları'**
  String get themeSettings;

  /// No description provided for @appPermissions.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama İzinleri'**
  String get appPermissions;

  /// No description provided for @managePermissions.
  ///
  /// In tr, this message translates to:
  /// **'Kamera, Rehber, Mikrofon vb. izinleri yönetin'**
  String get managePermissions;

  /// No description provided for @openSystemSettings.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Ayarlarını Aç'**
  String get openSystemSettings;

  /// No description provided for @appNotes.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Notları'**
  String get appNotes;

  /// No description provided for @deleteAttachment.
  ///
  /// In tr, this message translates to:
  /// **'Eki Sil'**
  String get deleteAttachment;

  /// No description provided for @takePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Çek'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden Seç'**
  String get chooseFromGallery;

  /// No description provided for @chooseFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosya Seç'**
  String get chooseFile;

  /// No description provided for @chooseAudioFile.
  ///
  /// In tr, this message translates to:
  /// **'Ses Dosyası Seç'**
  String get chooseAudioFile;

  /// No description provided for @chooseVideo.
  ///
  /// In tr, this message translates to:
  /// **'Video Çek/Seç'**
  String get chooseVideo;

  /// No description provided for @otherFiles.
  ///
  /// In tr, this message translates to:
  /// **'Diğer Dosyalar'**
  String get otherFiles;

  /// No description provided for @attachmentAdded.
  ///
  /// In tr, this message translates to:
  /// **'Ek başarıyla eklendi'**
  String get attachmentAdded;

  /// No description provided for @addFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosya Ekle'**
  String get addFile;

  /// No description provided for @deleteMedia.
  ///
  /// In tr, this message translates to:
  /// **'Media Sil'**
  String get deleteMedia;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Arama'**
  String get search;

  /// No description provided for @searchError.
  ///
  /// In tr, this message translates to:
  /// **'Arama hatası: {error}'**
  String searchError(String error);

  /// No description provided for @deleteTransaction.
  ///
  /// In tr, this message translates to:
  /// **'İşlemi Sil?'**
  String get deleteTransaction;

  /// No description provided for @deleteTransactionConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu finansal işlem kalıcı olarak silinecektir.'**
  String get deleteTransactionConfirm;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon izni gerekli!'**
  String get microphonePermissionRequired;

  /// No description provided for @transcriptionError.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri hatası: {code}'**
  String transcriptionError(int code);

  /// No description provided for @aiTranscribing.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zeka sesi metne dönüştürüyor...'**
  String get aiTranscribing;

  /// No description provided for @errorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {msg}'**
  String errorGeneric(String msg);

  /// No description provided for @errorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Hata oluştu: {msg}'**
  String errorOccurred(String msg);

  /// No description provided for @errLoadSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar yüklenirken hata oluştu: {error}'**
  String errLoadSettings(String error);

  /// No description provided for @alwaysUseLocalAudio.
  ///
  /// In tr, this message translates to:
  /// **'Her Zaman Yerel Ses Analizi Kullan'**
  String get alwaysUseLocalAudio;

  /// No description provided for @testBackupConnection.
  ///
  /// In tr, this message translates to:
  /// **'Yedek Bağlantıyı Test Et'**
  String get testBackupConnection;

  /// No description provided for @testVisionConnection.
  ///
  /// In tr, this message translates to:
  /// **'Vision Bağlantısını Test Et'**
  String get testVisionConnection;

  /// No description provided for @aiGuide.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zeka Rehberi'**
  String get aiGuide;

  /// No description provided for @understood.
  ///
  /// In tr, this message translates to:
  /// **'Anladım'**
  String get understood;

  /// No description provided for @savedSuccessCount.
  ///
  /// In tr, this message translates to:
  /// **'{tasks} görev, {notes} not, {events} etkinlik başarıyla kaydedildi!'**
  String savedSuccessCount(int tasks, int notes, int events);

  /// No description provided for @saveError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetme hatası: {error}'**
  String saveError(String error);

  /// No description provided for @imageFileNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Görsel dosyası bulunamadı.'**
  String get imageFileNotFound;

  /// No description provided for @contactSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Rehber kaydetme hatası: {error}'**
  String contactSaveError(String error);

  /// No description provided for @newScan.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Tarama'**
  String get newScan;

  /// No description provided for @saveItems.
  ///
  /// In tr, this message translates to:
  /// **'Seçilenleri Kaydet ({count})'**
  String saveItems(int count);

  /// No description provided for @selectItems.
  ///
  /// In tr, this message translates to:
  /// **'Öğe Seçin'**
  String get selectItems;

  /// No description provided for @saveContactsHint.
  ///
  /// In tr, this message translates to:
  /// **'Kişileri sağdaki butonlarla rehbere kaydedin.'**
  String get saveContactsHint;

  /// No description provided for @drawAreaHint.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı: Analiz edilecek alanı çizerek seçebilirsiniz.'**
  String get drawAreaHint;

  /// No description provided for @analyzeAll.
  ///
  /// In tr, this message translates to:
  /// **'TÜMÜNÜ ANALİZ ET'**
  String get analyzeAll;

  /// No description provided for @selectedArea.
  ///
  /// In tr, this message translates to:
  /// **'SEÇİLİ ALAN'**
  String get selectedArea;

  /// No description provided for @scannedText.
  ///
  /// In tr, this message translates to:
  /// **'Taranan Metin'**
  String get scannedText;

  /// No description provided for @showOriginalImage.
  ///
  /// In tr, this message translates to:
  /// **'Orijinal Görseli Göster'**
  String get showOriginalImage;

  /// No description provided for @selectAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Seç'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Kaldır'**
  String get deselectAll;

  /// No description provided for @contacts.
  ///
  /// In tr, this message translates to:
  /// **'Kişiler'**
  String get contacts;

  /// No description provided for @saveToContacts.
  ///
  /// In tr, this message translates to:
  /// **'Rehbere Kaydet'**
  String get saveToContacts;

  /// No description provided for @contactSaved.
  ///
  /// In tr, this message translates to:
  /// **'Kişi rehbere kaydedildi'**
  String get contactSaved;

  /// No description provided for @contactPermissionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Rehber izni gerekli'**
  String get contactPermissionRequired;

  /// No description provided for @eventDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik silindi'**
  String get eventDeleted;

  /// No description provided for @eventUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik güncellendi'**
  String get eventUpdated;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @onboardingComplete.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get onboardingComplete;

  /// No description provided for @apiKeyNotSet.
  ///
  /// In tr, this message translates to:
  /// **'API anahtarı ayarlanmamış. Ayarlar > AI Ayarları\'ndan API anahtarınızı girin.'**
  String get apiKeyNotSet;

  /// No description provided for @apiQuotaExceeded.
  ///
  /// In tr, this message translates to:
  /// **'API kota limiti aşıldı. Lütfen 1 dakika bekleyip tekrar deneyin.'**
  String get apiQuotaExceeded;

  /// No description provided for @apiParseError.
  ///
  /// In tr, this message translates to:
  /// **'AI yanıtı ayrıştırılamadı.'**
  String get apiParseError;

  /// No description provided for @apiError.
  ///
  /// In tr, this message translates to:
  /// **'API Hatası ({code})'**
  String apiError(int code);

  /// No description provided for @analysisError.
  ///
  /// In tr, this message translates to:
  /// **'Analiz hatası: {error}'**
  String analysisError(String error);

  /// No description provided for @mediaFilesCount.
  ///
  /// In tr, this message translates to:
  /// **'Media Dosyaları ({count})'**
  String mediaFilesCount(int count);

  /// No description provided for @addMedia.
  ///
  /// In tr, this message translates to:
  /// **'Media Ekle'**
  String get addMedia;

  /// No description provided for @noMediaYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz media eklenmemiş'**
  String get noMediaYet;

  /// No description provided for @fileAddedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Dosya başarıyla eklendi'**
  String get fileAddedSuccess;

  /// No description provided for @fileNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Dosya bulunamadı'**
  String get fileNotFound;

  /// No description provided for @fileOpenFail.
  ///
  /// In tr, this message translates to:
  /// **'Dosya açılamadı: {msg}'**
  String fileOpenFail(String msg);

  /// No description provided for @openFile.
  ///
  /// In tr, this message translates to:
  /// **'Aç'**
  String get openFile;

  /// No description provided for @imageLabel.
  ///
  /// In tr, this message translates to:
  /// **'Resim: {name}'**
  String imageLabel(String name);

  /// No description provided for @audioFileLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ses dosyası: {name}'**
  String audioFileLabel(String name);

  /// No description provided for @fileLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dosya: {name}'**
  String fileLabel(String name);

  /// No description provided for @deleteAttachmentSemantic.
  ///
  /// In tr, this message translates to:
  /// **'Eki sil'**
  String get deleteAttachmentSemantic;

  /// No description provided for @audioAttachment.
  ///
  /// In tr, this message translates to:
  /// **'Ses eki'**
  String get audioAttachment;

  /// No description provided for @imageAttachment.
  ///
  /// In tr, this message translates to:
  /// **'Resim eki'**
  String get imageAttachment;

  /// No description provided for @fileAttachment.
  ///
  /// In tr, this message translates to:
  /// **'Dosya eki'**
  String get fileAttachment;

  /// No description provided for @attachmentCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} ek'**
  String attachmentCount(int count);

  /// No description provided for @statusCompleted.
  ///
  /// In tr, this message translates to:
  /// **'tamamlandı'**
  String get statusCompleted;

  /// No description provided for @statusUrgent.
  ///
  /// In tr, this message translates to:
  /// **'acil'**
  String get statusUrgent;

  /// No description provided for @dateLabelFmt.
  ///
  /// In tr, this message translates to:
  /// **'Tarih: {date}'**
  String dateLabelFmt(String date);

  /// No description provided for @timeLabelFmt.
  ///
  /// In tr, this message translates to:
  /// **'Saat: {time}'**
  String timeLabelFmt(String time);

  /// No description provided for @deleteConfirmFile.
  ///
  /// In tr, this message translates to:
  /// **'\"{name}\" dosyasını silmek istiyor musunuz?'**
  String deleteConfirmFile(String name);

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Silmek istediğinize emin misiniz?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz.'**
  String get deleteConfirmMessage;

  /// No description provided for @emptyTasksCta.
  ///
  /// In tr, this message translates to:
  /// **'İlk görevinizi ekleyin'**
  String get emptyTasksCta;

  /// No description provided for @emptyEventsCta.
  ///
  /// In tr, this message translates to:
  /// **'Yeni etkinlik oluşturun'**
  String get emptyEventsCta;

  /// No description provided for @emptyNotesCta.
  ///
  /// In tr, this message translates to:
  /// **'Bir not yazın'**
  String get emptyNotesCta;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
