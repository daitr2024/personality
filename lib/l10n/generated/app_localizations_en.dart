// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Personality.ai';

  @override
  String get homeTitle => 'To-do';

  @override
  String get tasksTitle => 'My Tasks';

  @override
  String get addTaskLabel => 'Add New Task';

  @override
  String get noTasksMessage => 'No tasks yet.';

  @override
  String get calendar => 'Calendar';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get financeTitle => 'Finance';

  @override
  String get notesTitle => 'Notes';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get today => 'Today';

  @override
  String get tasks => 'Tasks';

  @override
  String get noTasksToday => 'No tasks for this date.';

  @override
  String get events => 'Events';

  @override
  String get noEventsToday => 'No events for this date.';

  @override
  String get notes => 'Notes';

  @override
  String get noNotesToday => 'No notes for this date.';

  @override
  String get editTask => 'Edit Task';

  @override
  String get taskTitleHint => 'Task title...';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get unnamedEvent => 'Unnamed Event';

  @override
  String get editingSoon => 'Editing coming soon';

  @override
  String totalUncompletedTasks(int count) {
    return '$count uncompleted tasks in total';
  }

  @override
  String uncompletedTasks(int count) {
    return '$count uncompleted tasks';
  }

  @override
  String overdueTasksTitle(int count) {
    return '$count Overdue Tasks';
  }

  @override
  String get overdueTasksDesc => 'Uncompleted tasks from past dates.';

  @override
  String get noOverdueTasks => 'Great! No overdue tasks.';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get close => 'Close';

  @override
  String get newEvent => 'Add New Event';

  @override
  String get eventName => 'Event Name';

  @override
  String get eventNameHint => 'e.g. Meeting';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get sync => 'Sync';

  @override
  String get syncDesc => 'Adds to system calendar';

  @override
  String noRecordsFound(String date) {
    return 'No records found for $date.';
  }

  @override
  String get externalEvent => 'System Calendar';

  @override
  String get event => 'Event';

  @override
  String get task => 'Task';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get noTransactions => 'No transactions yet.';

  @override
  String get addNewTransaction => 'Add New Transaction';

  @override
  String get addIncome => 'Add Income';

  @override
  String amountWithCurrency(String currency) {
    return 'Amount ($currency)';
  }

  @override
  String get add => 'Add';

  @override
  String get incomeAdded => 'Income added';

  @override
  String get cameraPermissionRequired => 'Camera permission required';

  @override
  String get receiptScanned => 'Receipt scanned and info filled';

  @override
  String get pleaseEnterValidValues => 'Please enter valid values';

  @override
  String get receiptAdded => 'Receipt Added (Tap to change)';

  @override
  String get scanReceipt => 'Scan Receipt (Auto-fill)';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Auto-filled from receipt or manual (Max 40)';

  @override
  String get amount => 'Amount';

  @override
  String get category => 'Category';

  @override
  String get categoryMarket => 'Market';

  @override
  String get categoryRent => 'Rent';

  @override
  String get categoryBill => 'Bill';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryOther => 'Other';

  @override
  String get incomeAddition => 'Income Addition';

  @override
  String get aiAnalysisTitle => 'AI Analysis';

  @override
  String get analysingContent => 'Analyzing content...';

  @override
  String get analysisFailedOrEmpty => 'Analysis failed or content is empty.';

  @override
  String get saveSelected => 'Save Selected';

  @override
  String get unknownError => 'Unknown error';

  @override
  String itemsSavedCount(int count) {
    return '$count items saved!';
  }

  @override
  String get updatedAndClassified => 'Updated and classified';

  @override
  String get noDateSelectedNoteHint => 'No date selected (Saved as note)';

  @override
  String get pickDate => 'Pick Date';

  @override
  String get editItemTip =>
      'TIP: Choosing a date saves it as a TASK, otherwise as a NOTE.';

  @override
  String get alreadyExists => 'Already exists';

  @override
  String get noDate => 'No date';

  @override
  String get editNote => 'Edit Note';

  @override
  String get addNewNote => 'Add New Note';

  @override
  String get noteHint => 'Write your note here...';

  @override
  String get quickAudioNote => 'Quick Audio Note';

  @override
  String get tapToRecord => 'Tap microphone to record.';

  @override
  String get audioNoteAddedNoText => 'Audio note added! (No text for analysis)';

  @override
  String get listening => 'Listening...';

  @override
  String get smartInputHint => 'Smart Add (Meeting, Task, Note...)';

  @override
  String get voiceNote => 'Voice Note';

  @override
  String get note => 'Note';

  @override
  String get complete => 'Complete';

  @override
  String get undo => 'Undo';

  @override
  String get dataRefreshed => 'Data refreshed';

  @override
  String get aiConfiguration => 'AI Configuration';

  @override
  String get aiConfigSubtitle => 'API settings and model selection';

  @override
  String get accountInfo => 'Account Info';

  @override
  String get accountInfoSubtitle =>
      'Edit profile information and email settings';

  @override
  String get clearReceiptImages => 'Clear Receipt Images';

  @override
  String get clearReceiptsTitle => 'Clear Receipts';

  @override
  String get clearReceiptsConfirm =>
      'All receipt images stored on this device will be deleted. This action cannot be undone.';

  @override
  String get allImagesCleared => 'All images cleared';

  @override
  String get tagManagement => 'Tag Management';

  @override
  String get tagManagementSubtitle => 'Tags used to categorize tasks';

  @override
  String get backupAndRestore => 'Backup and Restore';

  @override
  String get backupAndRestoreSubtitle =>
      'Save or restore your database and media files';

  @override
  String get aboutApp => 'About';

  @override
  String get backupAndRestoreTitle => 'Backup and Restore';

  @override
  String get backupNow => 'Backup Now';

  @override
  String get backupNowSubtitle => 'Export all your data as a ZIP file';

  @override
  String backupError(String error) {
    return 'Backup error: $error';
  }

  @override
  String get restoreFromBackup => 'Restore from Backup';

  @override
  String get restoreFromBackupSubtitle => 'Restore from a selected backup file';

  @override
  String get restoreConfirmTitle => 'Restore?';

  @override
  String get restoreConfirmMessage =>
      'Your current data will be deleted and replaced with backup data. The app will close after the process.';

  @override
  String get restoreSuccessTitle => 'Restore Successful';

  @override
  String get restoreSuccessMessage =>
      'Your data has been restored. Please close and reopen the app for changes to take effect.';

  @override
  String get closeApp => 'Close App';

  @override
  String restoreError(String error) {
    return 'Restore error: $error';
  }

  @override
  String get calendarSync => 'Calendar Sync';

  @override
  String get enableSync => 'Enable Sync';

  @override
  String get enableSyncSubtitle => 'Shares events with device calendar';

  @override
  String get selectTargetCalendar => 'Select Target Calendar';

  @override
  String get noCalendarFound => 'No calendar found or permission denied.';

  @override
  String get unnamedCalendar => 'Unnamed Calendar';

  @override
  String get syncAllOldRecords => 'Sync All Old Records';

  @override
  String eventsSynced(int count) {
    return '$count events synced.';
  }

  @override
  String get noEventsToSync => 'No new events to sync.';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get resetConfirmTitle => 'Reset to Defaults';

  @override
  String get resetConfirmMessage =>
      'All AI settings will be reset to default values. Do you want to continue?';

  @override
  String get reset => 'Reset';

  @override
  String get settingsResetSuccess => 'Settings reset to default values';

  @override
  String get connectionSuccess => 'Connection successful! ✓';

  @override
  String get connectionFailed => 'Connection failed. Please check settings.';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get testing => 'Testing...';

  @override
  String get apiEndpoint => 'API Endpoint / IP';

  @override
  String get apiEndpointHint => 'API endpoint address of the AI service';

  @override
  String get apiKey => 'API Key';

  @override
  String get apiKeySecureHint => 'Your API key is stored securely';

  @override
  String get model => 'Model';

  @override
  String get temperature => 'Temperature';

  @override
  String get temperatureHint =>
      'Lower values are more consistent, higher values are more creative';

  @override
  String get maxTokens => 'Max Tokens';

  @override
  String get maxTokensHint =>
      'Maximum response length (higher = longer responses)';

  @override
  String get apiKeySecureInfo =>
      'Your API key is encrypted and stored securely on your device. It is never sent to any server.';

  @override
  String get reminder => 'Reminder';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get notSelected => 'Not selected';

  @override
  String minutesBefore(int minutes) {
    return '$minutes minutes before';
  }

  @override
  String get onTime => 'On time';

  @override
  String get howManyMinutesBefore => 'How many minutes before?';

  @override
  String get editEvent => 'Edit Event';

  @override
  String get title => 'Title';

  @override
  String nearFuture(int count) {
    return 'Near Future ($count Records)';
  }

  @override
  String get nearFutureSchedule => 'Near Future Schedule';

  @override
  String get profileInfo => 'Profile Info';

  @override
  String get profileInfoSubtitle =>
      'Save your information to verify your backups on different devices.';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get infoUpdated => 'Info updated';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get aboutAppTitle => 'About Personality.ai';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Developer';

  @override
  String get privacyPolicyContent =>
      'This app stores your personal data securely on your device. No data is sent to servers. When using AI features, data is only sent to the API you have configured.';

  @override
  String get newTaskTitle => 'Add New Task';

  @override
  String get urgentTask => 'Urgent Task';

  @override
  String get reminderActive => 'Reminder Active';

  @override
  String get recurrenceInterval => 'Recurrence Interval';

  @override
  String get whichDays => 'Which Days?';

  @override
  String get startDate => 'Start Date';

  @override
  String get routineTime => 'Routine Time';

  @override
  String get endDateOptional => 'End Date (Optional)';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get selectEndDateFirst => 'Please select an end date first';

  @override
  String get recurring => 'Recurring';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get selectEnd => 'Select End';

  @override
  String get endNone => 'Indefinite';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get archiveTasks => 'Archive Tasks';

  @override
  String get statistics => 'Statistics';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get appPermissions => 'App Permissions';

  @override
  String get managePermissions =>
      'Manage Camera, Contacts, Microphone permissions';

  @override
  String get openSystemSettings => 'Open System Settings';

  @override
  String get appNotes => 'App Notes';

  @override
  String get deleteAttachment => 'Delete Attachment';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get chooseFile => 'Choose File';

  @override
  String get chooseAudioFile => 'Choose Audio File';

  @override
  String get chooseVideo => 'Record/Choose Video';

  @override
  String get otherFiles => 'Other Files';

  @override
  String get attachmentAdded => 'Attachment added successfully';

  @override
  String get addFile => 'Add File';

  @override
  String get deleteMedia => 'Delete Media';

  @override
  String get search => 'Search';

  @override
  String searchError(String error) {
    return 'Search error: $error';
  }

  @override
  String get deleteTransaction => 'Delete Transaction?';

  @override
  String get deleteTransactionConfirm =>
      'This financial transaction will be permanently deleted.';

  @override
  String get microphonePermissionRequired => 'Microphone permission required!';

  @override
  String transcriptionError(int code) {
    return 'Transcription error: $code';
  }

  @override
  String get aiTranscribing => 'AI is converting speech to text...';

  @override
  String errorGeneric(String msg) {
    return 'Error: $msg';
  }

  @override
  String errorOccurred(String msg) {
    return 'An error occurred: $msg';
  }

  @override
  String errLoadSettings(String error) {
    return 'Error loading settings: $error';
  }

  @override
  String get alwaysUseLocalAudio => 'Always Use Local Audio Analysis';

  @override
  String get testBackupConnection => 'Test Backup Connection';

  @override
  String get testVisionConnection => 'Test Vision Connection';

  @override
  String get aiGuide => 'AI Guide';

  @override
  String get understood => 'Got it';

  @override
  String savedSuccessCount(int tasks, int notes, int events) {
    return '$tasks tasks, $notes notes, $events events saved successfully!';
  }

  @override
  String saveError(String error) {
    return 'Save error: $error';
  }

  @override
  String get imageFileNotFound => 'Image file not found.';

  @override
  String contactSaveError(String error) {
    return 'Contact save error: $error';
  }

  @override
  String get newScan => 'New Scan';

  @override
  String saveItems(int count) {
    return 'Save Selected ($count)';
  }

  @override
  String get selectItems => 'Select Items';

  @override
  String get saveContactsHint =>
      'Save contacts to phonebook using the buttons on the right.';

  @override
  String get drawAreaHint => 'Optional: Draw to select the area to analyze.';

  @override
  String get analyzeAll => 'ANALYZE ALL';

  @override
  String get selectedArea => 'SELECTED AREA';

  @override
  String get scannedText => 'Scanned Text';

  @override
  String get showOriginalImage => 'Show Original Image';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get contacts => 'Contacts';

  @override
  String get saveToContacts => 'Save to Contacts';

  @override
  String get contactSaved => 'Contact saved to phonebook';

  @override
  String get contactPermissionRequired => 'Contacts permission required';

  @override
  String get eventDeleted => 'Event deleted';

  @override
  String get eventUpdated => 'Event updated';

  @override
  String get back => 'Back';

  @override
  String get onboardingComplete => 'Let\'s Start';

  @override
  String get apiKeyNotSet =>
      'API key not set. Go to Settings > AI Settings to enter your API key.';

  @override
  String get apiQuotaExceeded =>
      'API quota exceeded. Please wait 1 minute and try again.';

  @override
  String get apiParseError => 'Could not parse AI response.';

  @override
  String apiError(int code) {
    return 'API Error ($code)';
  }

  @override
  String analysisError(String error) {
    return 'Analysis error: $error';
  }

  @override
  String mediaFilesCount(int count) {
    return 'Media Files ($count)';
  }

  @override
  String get addMedia => 'Add Media';

  @override
  String get noMediaYet => 'No media attached yet';

  @override
  String get fileAddedSuccess => 'File added successfully';

  @override
  String get fileNotFound => 'File not found';

  @override
  String fileOpenFail(String msg) {
    return 'Cannot open file: $msg';
  }

  @override
  String get openFile => 'Open';

  @override
  String imageLabel(String name) {
    return 'Image: $name';
  }

  @override
  String audioFileLabel(String name) {
    return 'Audio: $name';
  }

  @override
  String fileLabel(String name) {
    return 'File: $name';
  }

  @override
  String get deleteAttachmentSemantic => 'Delete attachment';

  @override
  String get audioAttachment => 'Audio attachment';

  @override
  String get imageAttachment => 'Image attachment';

  @override
  String get fileAttachment => 'File attachment';

  @override
  String attachmentCount(int count) {
    return '$count attachments';
  }

  @override
  String get statusCompleted => 'completed';

  @override
  String get statusUrgent => 'urgent';

  @override
  String dateLabelFmt(String date) {
    return 'Date: $date';
  }

  @override
  String timeLabelFmt(String time) {
    return 'Time: $time';
  }

  @override
  String deleteConfirmFile(String name) {
    return 'Do you want to delete \"$name\"?';
  }

  @override
  String get deleteConfirmTitle => 'Are you sure you want to delete?';

  @override
  String get deleteConfirmMessage => 'This action cannot be undone.';

  @override
  String get emptyTasksCta => 'Add your first task';

  @override
  String get emptyEventsCta => 'Create a new event';

  @override
  String get emptyNotesCta => 'Write a note';
}
