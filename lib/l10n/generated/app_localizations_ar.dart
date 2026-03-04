// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Personality.ai';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get tasksTitle => 'مهامي';

  @override
  String get addTaskLabel => 'إضافة مهمة جديدة';

  @override
  String get noTasksMessage => 'لا توجد مهام بعد.';

  @override
  String get calendar => 'التقويم';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get financeTitle => 'المالية';

  @override
  String get notesTitle => 'ملاحظات';

  @override
  String get calendarTitle => 'التقويم';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get today => 'اليوم';

  @override
  String get tasks => 'المهام';

  @override
  String get noTasksToday => 'لا توجد مهام لهذا التاريخ.';

  @override
  String get events => 'الأحداث';

  @override
  String get noEventsToday => 'لا توجد أحداث لهذا التاريخ.';

  @override
  String get notes => 'الملاحظات';

  @override
  String get noNotesToday => 'لا توجد ملاحظات لهذا التاريخ.';

  @override
  String get editTask => 'تعديل المهمة';

  @override
  String get taskTitleHint => 'عنوان المهمة...';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get unnamedEvent => 'حدث بدون اسم';

  @override
  String get editingSoon => 'التعديل قادم قريباً';

  @override
  String totalUncompletedTasks(int count) {
    return 'إجمالي $count مهام غير مكتملة';
  }

  @override
  String uncompletedTasks(int count) {
    return '$count مهام غير مكتملة';
  }

  @override
  String overdueTasksTitle(int count) {
    return '$count مهام متأخرة';
  }

  @override
  String get overdueTasksDesc => 'مهام غير مكتملة من تواريخ سابقة.';

  @override
  String get noOverdueTasks => 'رائع! لا توجد مهام متأخرة.';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get close => 'إغلاق';

  @override
  String get newEvent => 'إضافة حدث جديد';

  @override
  String get eventName => 'اسم الحدث';

  @override
  String get eventNameHint => 'مثال: اجتماع';

  @override
  String get date => 'التاريخ';

  @override
  String get time => 'الوقت';

  @override
  String get sync => 'مزامنة';

  @override
  String get syncDesc => 'يضيف إلى تقويم النظام';

  @override
  String noRecordsFound(String date) {
    return 'لم يتم العثور على سجلات لـ $date.';
  }

  @override
  String get externalEvent => 'تقويم النظام';

  @override
  String get event => 'حدث';

  @override
  String get task => 'مهمة';

  @override
  String get totalBalance => 'إجمالي الرصيد';

  @override
  String get income => 'الدخل';

  @override
  String get expense => 'المصروفات';

  @override
  String get recentTransactions => 'العمليات الأخيرة';

  @override
  String get noTransactions => 'لا توجد عمليات بعد.';

  @override
  String get addNewTransaction => 'إضافة عملية جديدة';

  @override
  String get addIncome => 'إضافة دخل';

  @override
  String amountWithCurrency(String currency) {
    return 'المبلغ ($currency)';
  }

  @override
  String get add => 'إضافة';

  @override
  String get incomeAdded => 'تم إضافة الدخل';

  @override
  String get cameraPermissionRequired => 'مطلوب إذن الكاميرا';

  @override
  String get receiptScanned => 'تم مسح الإيصال وملء المعلومات';

  @override
  String get pleaseEnterValidValues => 'يرجى إدخال قيم صالحة';

  @override
  String get receiptAdded => 'تم إضافة الإيصال (اضغط للتغيير)';

  @override
  String get scanReceipt => 'مسح الإيصال (تعبئة تلقائية)';

  @override
  String get description => 'الوصف';

  @override
  String get descriptionHint =>
      'تعبئة تلقائية من الإيصال أو يدوي (بحد أقصى 40)';

  @override
  String get amount => 'المبلغ';

  @override
  String get category => 'الفئة';

  @override
  String get categoryMarket => 'سوق';

  @override
  String get categoryRent => 'إيجار';

  @override
  String get categoryBill => 'فاتورة';

  @override
  String get categorySalary => 'راتب';

  @override
  String get categoryOther => 'آخر';

  @override
  String get incomeAddition => 'إضافة دخل';

  @override
  String get aiAnalysisTitle => 'تحليل الذكاء الاصطناعي';

  @override
  String get analysingContent => 'جاري تحليل المحتوى...';

  @override
  String get analysisFailedOrEmpty => 'فشل التحليل أو المحتوى فارغ.';

  @override
  String get saveSelected => 'حفظ المختار';

  @override
  String get unknownError => 'خطأ غير معروف';

  @override
  String itemsSavedCount(int count) {
    return 'تم حفظ $count عناصر!';
  }

  @override
  String get updatedAndClassified => 'تم التحديث والتصنيف';

  @override
  String get noDateSelectedNoteHint =>
      'لم يتم اختيار تاريخ (سيتم حفظه كملاحظة)';

  @override
  String get pickDate => 'اختر التاريخ';

  @override
  String get editItemTip =>
      'نصيحة: اختيار تاريخ يحفظه كمهمة، وإلا فسيتم حفظه كملاحظة.';

  @override
  String get alreadyExists => 'موجود بالفعل';

  @override
  String get noDate => 'لا يوجد تاريخ';

  @override
  String get editNote => 'تعديل الملاحظة';

  @override
  String get addNewNote => 'إضافة ملاحظة جديدة';

  @override
  String get noteHint => 'اكتب ملاحظتك هنا...';

  @override
  String get quickAudioNote => 'ملاحظة صوتية سريعة';

  @override
  String get tapToRecord => 'اضغط على الميكروفون للتسجيل.';

  @override
  String get audioNoteAddedNoText =>
      'تم إضافة الملاحظة الصوتية! (لا يوجد نص للتحليل)';

  @override
  String get listening => 'جاري الاستماع...';

  @override
  String get smartInputHint => 'إضافة ذكية (اجتماع، مهمة، ملاحظة...)';

  @override
  String get voiceNote => 'ملاحظة صوتية';

  @override
  String get note => 'ملاحظة';

  @override
  String get complete => 'إكمال';

  @override
  String get undo => 'تراجع';

  @override
  String get dataRefreshed => 'تم تحديث البيانات';

  @override
  String get aiConfiguration => 'إعدادات الذكاء الاصطناعي';

  @override
  String get aiConfigSubtitle => 'إعدادات API واختيار النموذج';

  @override
  String get accountInfo => 'معلومات الحساب';

  @override
  String get accountInfoSubtitle =>
      'تعديل معلومات الملف الشخصي وإعدادات البريد الإلكتروني';

  @override
  String get clearReceiptImages => 'مسح صور الإيصالات';

  @override
  String get clearReceiptsTitle => 'مسح الإيصالات';

  @override
  String get clearReceiptsConfirm =>
      'سيتم حذف جميع صور الإيصالات المخزنة على هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get allImagesCleared => 'تم مسح جميع الصور';

  @override
  String get tagManagement => 'إدارة العلامات';

  @override
  String get tagManagementSubtitle => 'علامات تُستخدم لتصنيف المهام';

  @override
  String get backupAndRestore => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupAndRestoreSubtitle =>
      'حفظ أو استعادة قاعدة البيانات وملفات الوسائط';

  @override
  String get aboutApp => 'حول التطبيق';

  @override
  String get backupAndRestoreTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupNow => 'نسخ احتياطي الآن';

  @override
  String get backupNowSubtitle => 'تصدير جميع بياناتك كملف ZIP';

  @override
  String backupError(String error) {
    return 'خطأ في النسخ الاحتياطي: $error';
  }

  @override
  String get restoreFromBackup => 'استعادة من نسخة احتياطية';

  @override
  String get restoreFromBackupSubtitle => 'استعادة من ملف نسخة احتياطية محدد';

  @override
  String get restoreConfirmTitle => 'استعادة؟';

  @override
  String get restoreConfirmMessage =>
      'سيتم حذف بياناتك الحالية واستبدالها ببيانات النسخة الاحتياطية. سيتم إغلاق التطبيق بعد العملية.';

  @override
  String get restoreSuccessTitle => 'تمت الاستعادة بنجاح';

  @override
  String get restoreSuccessMessage =>
      'تمت استعادة بياناتك. يرجى إغلاق التطبيق وإعادة فتحه لتصبح التغييرات فعالة.';

  @override
  String get closeApp => 'إغلاق التطبيق';

  @override
  String restoreError(String error) {
    return 'خطأ في الاستعادة: $error';
  }

  @override
  String get calendarSync => 'مزامنة التقويم';

  @override
  String get enableSync => 'تفعيل المزامنة';

  @override
  String get enableSyncSubtitle => 'مشاركة الأحداث مع تقويم الجهاز';

  @override
  String get selectTargetCalendar => 'اختر التقويم المستهدف';

  @override
  String get noCalendarFound => 'لم يتم العثور على تقويم أو تم رفض الإذن.';

  @override
  String get unnamedCalendar => 'تقويم بدون اسم';

  @override
  String get syncAllOldRecords => 'مزامنة جميع السجلات القديمة';

  @override
  String eventsSynced(int count) {
    return 'تمت مزامنة $count أحداث.';
  }

  @override
  String get noEventsToSync => 'لا توجد أحداث جديدة للمزامنة.';

  @override
  String get resetToDefaults => 'إعادة التعيين إلى الافتراضي';

  @override
  String get resetConfirmTitle => 'إعادة التعيين إلى الافتراضي';

  @override
  String get resetConfirmMessage =>
      'سيتم إعادة تعيين جميع إعدادات الذكاء الاصطناعي إلى القيم الافتراضية. هل تريد المتابعة؟';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get settingsResetSuccess =>
      'تمت إعادة تعيين الإعدادات إلى القيم الافتراضية';

  @override
  String get connectionSuccess => 'اتصال ناجح! ✓';

  @override
  String get connectionFailed => 'فشل الاتصال. يرجى التحقق من الإعدادات.';

  @override
  String get testConnection => 'اختبار الاتصال';

  @override
  String get testing => 'جاري الاختبار...';

  @override
  String get apiEndpoint => 'عنوان API';

  @override
  String get apiEndpointHint => 'عنوان نقطة نهاية API لخدمة الذكاء الاصطناعي';

  @override
  String get apiKey => 'مفتاح API';

  @override
  String get apiKeySecureHint => 'يتم تخزين مفتاح API الخاص بك بشكل آمن';

  @override
  String get model => 'النموذج';

  @override
  String get temperature => 'درجة الحرارة';

  @override
  String get temperatureHint =>
      'القيم المنخفضة أكثر اتساقاً، القيم العالية أكثر إبداعاً';

  @override
  String get maxTokens => 'الحد الأقصى للرموز';

  @override
  String get maxTokensHint => 'أقصى طول للاستجابة (أعلى = استجابات أطول)';

  @override
  String get apiKeySecureInfo =>
      'يتم تشفير مفتاح API الخاص بك وتخزينه بشكل آمن على جهازك. لن يتم إرساله أبداً إلى أي خادم.';

  @override
  String get reminder => 'تذكير';

  @override
  String get reminderTime => 'وقت التذكير';

  @override
  String get notSelected => 'غير محدد';

  @override
  String minutesBefore(int minutes) {
    return 'قبل $minutes دقائق';
  }

  @override
  String get onTime => 'في الوقت المحدد';

  @override
  String get howManyMinutesBefore => 'كم دقيقة قبل؟';

  @override
  String get editEvent => 'تعديل الحدث';

  @override
  String get title => 'العنوان';

  @override
  String nearFuture(int count) {
    return 'المستقبل القريب ($count سجلات)';
  }

  @override
  String get nearFutureSchedule => 'جدول المستقبل القريب';

  @override
  String get profileInfo => 'معلومات الملف الشخصي';

  @override
  String get profileInfoSubtitle =>
      'احفظ معلوماتك للتحقق من نسخك الاحتياطية على أجهزة مختلفة.';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get infoUpdated => 'تم تحديث المعلومات';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get aboutAppTitle => 'حول Personality.ai';

  @override
  String get version => 'الإصدار';

  @override
  String get developer => 'المطور';

  @override
  String get privacyPolicyContent =>
      'يخزن هذا التطبيق بياناتك الشخصية بشكل آمن على جهازك. لا يتم إرسال أي بيانات إلى الخوادم. عند استخدام ميزات الذكاء الاصطناعي، يتم إرسال البيانات فقط إلى API الذي قمت بتكوينه.';

  @override
  String get newTaskTitle => 'إضافة مهمة جديدة';

  @override
  String get urgentTask => 'مهمة عاجلة';

  @override
  String get reminderActive => 'التذكير مفعل';

  @override
  String get recurrenceInterval => 'فترة التكرار';

  @override
  String get whichDays => 'أي الأيام؟';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get routineTime => 'وقت الروتين';

  @override
  String get endDateOptional => 'تاريخ الانتهاء (اختياري)';

  @override
  String get pleaseEnterTitle => 'يرجى إدخال عنوان';

  @override
  String get selectEndDateFirst => 'يرجى تحديد تاريخ الانتهاء أولاً';

  @override
  String get recurring => 'متكرر';

  @override
  String get daily => 'يومي';

  @override
  String get weekly => 'أسبوعي';

  @override
  String get selectEnd => 'اختر الانتهاء';

  @override
  String get endNone => 'غير محدد';

  @override
  String get analyzing => 'جاري التحليل...';

  @override
  String get archiveTasks => 'أرشيف المهام';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get themeSettings => 'إعدادات السمة';

  @override
  String get appPermissions => 'أذونات التطبيق';

  @override
  String get managePermissions =>
      'إدارة أذونات الكاميرا وجهات الاتصال والميكروفون';

  @override
  String get openSystemSettings => 'فتح إعدادات النظام';

  @override
  String get appNotes => 'ملاحظات التطبيق';

  @override
  String get deleteAttachment => 'حذف المرفق';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختر من المعرض';

  @override
  String get chooseFile => 'اختر ملف';

  @override
  String get chooseAudioFile => 'اختر ملف صوتي';

  @override
  String get chooseVideo => 'تسجيل/اختيار فيديو';

  @override
  String get otherFiles => 'ملفات أخرى';

  @override
  String get attachmentAdded => 'تمت إضافة المرفق بنجاح';

  @override
  String get addFile => 'إضافة ملف';

  @override
  String get deleteMedia => 'حذف الوسائط';

  @override
  String get search => 'البحث';

  @override
  String searchError(String error) {
    return 'خطأ في البحث: $error';
  }

  @override
  String get deleteTransaction => 'حذف العملية؟';

  @override
  String get deleteTransactionConfirm =>
      'سيتم حذف هذه العملية المالية بشكل دائم.';

  @override
  String get microphonePermissionRequired => 'مطلوب إذن الميكروفون!';

  @override
  String transcriptionError(int code) {
    return 'خطأ في النسخ: $code';
  }

  @override
  String get aiTranscribing => 'الذكاء الاصطناعي يحول الكلام إلى نص...';

  @override
  String errorGeneric(String msg) {
    return 'خطأ: $msg';
  }

  @override
  String errorOccurred(String msg) {
    return 'حدث خطأ: $msg';
  }

  @override
  String errLoadSettings(String error) {
    return 'خطأ في تحميل الإعدادات: $error';
  }

  @override
  String get alwaysUseLocalAudio => 'استخدام التحليل الصوتي المحلي دائماً';

  @override
  String get testBackupConnection => 'اختبار اتصال النسخ الاحتياطي';

  @override
  String get testVisionConnection => 'اختبار اتصال الرؤية';

  @override
  String get aiGuide => 'دليل الذكاء الاصطناعي';

  @override
  String get understood => 'فهمت';

  @override
  String savedSuccessCount(int tasks, int notes, int events) {
    return 'تم حفظ $tasks مهام، $notes ملاحظات، $events أحداث بنجاح!';
  }

  @override
  String saveError(String error) {
    return 'خطأ في الحفظ: $error';
  }

  @override
  String get imageFileNotFound => 'لم يتم العثور على ملف الصورة.';

  @override
  String contactSaveError(String error) {
    return 'خطأ في حفظ جهة الاتصال: $error';
  }

  @override
  String get newScan => 'مسح جديد';

  @override
  String saveItems(int count) {
    return 'حفظ المختار ($count)';
  }

  @override
  String get selectItems => 'اختر العناصر';

  @override
  String get saveContactsHint =>
      'احفظ جهات الاتصال في دفتر العناوين باستخدام الأزرار على اليمين.';

  @override
  String get drawAreaHint => 'اختياري: ارسم لتحديد المنطقة المراد تحليلها.';

  @override
  String get analyzeAll => 'تحليل الكل';

  @override
  String get selectedArea => 'المنطقة المحددة';

  @override
  String get scannedText => 'النص الممسوح';

  @override
  String get showOriginalImage => 'عرض الصورة الأصلية';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get deselectAll => 'إلغاء تحديد الكل';

  @override
  String get contacts => 'جهات الاتصال';

  @override
  String get saveToContacts => 'حفظ في جهات الاتصال';

  @override
  String get contactSaved => 'تم حفظ جهة الاتصال في دفتر العناوين';

  @override
  String get contactPermissionRequired => 'مطلوب إذن جهات الاتصال';

  @override
  String get eventDeleted => 'تم حذف الحدث';

  @override
  String get eventUpdated => 'تم تحديث الحدث';

  @override
  String get back => 'رجوع';

  @override
  String get onboardingComplete => 'لنبدأ';

  @override
  String get apiKeyNotSet =>
      'لم يتم تعيين مفتاح API. انتقل إلى الإعدادات > إعدادات الذكاء الاصطناعي لإدخال مفتاح API الخاص بك.';

  @override
  String get apiQuotaExceeded =>
      'تم تجاوز حصة API. يرجى الانتظار دقيقة واحدة والمحاولة مرة أخرى.';

  @override
  String get apiParseError => 'تعذر تحليل استجابة الذكاء الاصطناعي.';

  @override
  String apiError(int code) {
    return 'خطأ API ($code)';
  }

  @override
  String analysisError(String error) {
    return 'خطأ في التحليل: $error';
  }
}
