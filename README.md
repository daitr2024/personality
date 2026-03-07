<p align="center">
  <img src="assets/app_icon.png" width="120" alt="Personality.ai Logo"/>
</p>

<h1 align="center">Personality.ai</h1>

<p align="center">
  <strong>Your AI-Powered Personal Productivity Assistant</strong><br/>
  Tasks · Notes · Calendar · Finance — All Enhanced with Artificial Intelligence
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-blue?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" alt="Android"/>
  <img src="https://img.shields.io/badge/AI-Gemini%20%7C%20OpenAI-purple" alt="AI"/>
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License"/>
</p>

---

## 📖 Overview

**Personality.ai** is a feature-rich, AI-powered personal assistant built with Flutter. It combines task management, note-taking, calendar synchronization, and financial tracking into a single, cohesive application. What sets it apart is its deep integration with AI — users can create tasks, events, and notes using natural language (text or voice), scan documents with OCR, and have the AI automatically categorize and schedule everything.

The app is designed with a **privacy-first** approach: all data is stored locally on the device using SQLite, and AI features communicate only with the API endpoint configured by the user.

---

## ✨ Key Features

### 🤖 AI-Powered Smart Input
- **Natural Language Processing** — Type or speak naturally (e.g., *"Meeting with Ali tomorrow at 3pm"*) and the AI automatically creates the correct task, event, or note with proper date/time parsing
- **Multilingual NLP** — Full support for Turkish, English, and Arabic temporal expressions and natural language understanding
- **AI Failover System** — Primary and backup API endpoints with automatic failover when the primary API fails or reaches quota limits

### 📝 Task Management
- Create, edit, and organize tasks with due dates, urgency flags, and reminders
- **Recurring Tasks** — Daily, weekly, monthly, or custom recurrence patterns with configurable end dates
- **Smart Notifications** — AI-powered notification scheduling that considers task priority and deadlines
- **Overdue Task Tracking** — Automatic detection and dedicated dialog for managing overdue items
- **Tag System** — Categorize tasks with customizable tags
- **Archive** — Soft-delete with archival support for completed/deleted tasks

### 📒 Notes & Voice Recording
- Rich text notes with audio recording capability
- **Speech-to-Text** — Record voice notes with automatic transcription (local STT or AI-powered)
- **Audio Analysis** — AI analyzes transcribed audio and automatically extracts tasks, events, and notes
- File attachments (images, audio, documents) linked to any note

### 🗓 Calendar
- **Two-Week Calendar Bar** — Scrollable calendar strip with daily agenda view
- **Device Calendar Sync** — Bidirectional synchronization with the device's native calendar
- **Daily Timeline** — Visual timeline showing the day's tasks, events, and notes in chronological order
- Event creation with start/end times and configurable reminders

### 💰 Finance Tracking
- Income and expense tracking with category classification
- **Receipt Scanning** — Point your camera at a receipt and the AI auto-extracts amount, description, and category
- **Installment Tracking** — Track purchases with installment plans
- **Recurring Transactions** — Automatic recurring income/expense entries
- Balance overview with visual charts (powered by fl_chart)

### 📸 Image Scanning & OCR
- **ML Kit Text Recognition** — On-device OCR for extracting text from images
- **Custom Area Selection** — Draw to select specific areas of an image for targeted analysis
- **AI Vision Analysis** — Send images to AI Vision API for intelligent extraction of tasks, events, notes, and contacts
- **Contact Extraction** — Scan business cards or contact info and save directly to phonebook

### 📊 Statistics & Insights
- Productivity analytics with visual charts
- Task completion rates and trends
- Financial summaries and category breakdowns

### 📱 Android Integration
- **Home Screen Widgets** — Quick-view widget showing upcoming tasks and an input widget for rapid entry
- **Quick Note Tile** — Android Quick Settings tile for instant voice note recording
- **Smart Notifications** — Context-aware reminders with proper timezone handling

### 🌍 Internationalization
- Full localization in **Turkish** (primary), **English**, and **Arabic**
- RTL layout support for Arabic
- Locale-aware date/time formatting

### 🎨 Theming
- Light and Dark mode with smooth transitions
- Customizable theme settings
- Material 3 design language

---

## 🏗 Architecture

### Design Pattern: Feature-First Clean Architecture

The project follows a **feature-first architecture** with clear separation of concerns. Each feature module is self-contained with its own data, presentation, and provider layers.

```
lib/
├── main.dart                    # App entry point, Firebase & timezone init
├── config/
│   ├── routes/
│   │   └── app_router.dart      # GoRouter with StatefulShellRoute (tab navigation)
│   └── theme/
│       ├── app_theme.dart       # Material 3 theme definitions
│       └── theme_provider.dart  # Riverpod theme state management
│
├── core/                        # Shared infrastructure
│   ├── database/
│   │   ├── app_database.dart    # Drift ORM schema (9 tables)
│   │   └── app_database.g.dart  # Generated database code
│   ├── services/                # 15 domain services
│   │   ├── ai_config_service.dart          # API key management (secure storage)
│   │   ├── audio_analysis_service.dart     # Voice → AI text analysis pipeline
│   │   ├── image_analysis_service.dart     # Vision AI + OCR pipeline
│   │   ├── receipt_scanner_service.dart    # Receipt OCR → finance entry
│   │   ├── notification_service.dart       # Local notification scheduling
│   │   ├── smart_notification_service.dart # AI-driven smart reminders
│   │   ├── recurring_task_service.dart     # Recurrence pattern engine
│   │   ├── reminder_scheduler.dart         # Task/event reminder logic
│   │   ├── home_widget_service.dart        # Android home widget data
│   │   ├── backup_service.dart             # ZIP backup & restore
│   │   ├── search_service.dart             # Full-text search across entities
│   │   ├── statistics_service.dart         # Productivity analytics engine
│   │   ├── attachment_service.dart         # File management for attachments
│   │   ├── local_speech_service.dart       # On-device speech-to-text
│   │   └── quick_access_service.dart       # Quick Settings tile handler
│   ├── utils/
│   │   ├── date_utils.dart                 # Timezone-aware date helpers
│   │   └── turkish_nlp_utils.dart          # Turkish NLP text processing
│   └── widgets/                 # Shared UI components
│       ├── attachment_manager.dart
│       ├── media_preview.dart
│       ├── task_countdown.dart
│       └── unified_agenda_item.dart
│
├── features/                    # Feature modules (12 modules)
│   ├── home/                    # Main dashboard
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── home_page.dart           # Main screen with pull-to-refresh
│   │       │   └── main_wrapper_page.dart   # Bottom navigation shell
│   │       ├── providers/
│   │       │   └── dashboard_providers.dart
│   │       └── widgets/
│   │           ├── smart_input_bar.dart     # AI-powered input (text + voice)
│   │           ├── two_week_calendar_bar.dart
│   │           ├── daily_dashboard.dart     # Day view with tasks/events/notes
│   │           ├── daily_timeline.dart      # Visual chronological timeline
│   │           ├── home_header.dart
│   │           ├── overdue_tasks_dialog.dart
│   │           └── quick_action_buttons.dart
│   │
│   ├── tasks/                   # Task management
│   │   ├── data/repositories/
│   │   │   └── tasks_repository.dart
│   │   └── presentation/
│   │       ├── pages/           # New task, task list, archive
│   │       ├── providers/       # Riverpod state management
│   │       └── widgets/
│   │
│   ├── notes/                   # Notes with audio
│   │   ├── data/repositories/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── providers/
│   │       └── widgets/         # Audio recorder, player, analysis dialog
│   │
│   ├── calendar/                # Calendar & events
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   └── services/        # Calendar sync service
│   │   └── presentation/
│   │
│   ├── finance/                 # Financial tracking
│   │   ├── data/repositories/
│   │   └── presentation/
│   │
│   ├── image_scan/              # OCR & Vision AI
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── image_scan_page.dart   # Main scan interface
│   │       │   └── custom_crop_page.dart  # Area selection for OCR
│   │       └── providers/
│   │
│   ├── search/                  # Global search
│   ├── statistics/              # Analytics & charts
│   ├── settings/                # App configuration
│   │   └── presentation/
│   │       ├── pages/           # AI settings, profile, theme, about, permissions
│   │       └── providers/       # Config, backup, locale, currency providers
│   │
│   ├── voice/                   # Voice recording
│   ├── notifications/           # Smart notification scheduling
│   └── onboarding/              # First-launch experience
│
└── l10n/                        # Localization
    ├── app_tr.arb               # Turkish (primary)
    ├── app_en.arb               # English
    ├── app_ar.arb               # Arabic
    └── generated/               # Auto-generated localization classes
```

### State Management: Riverpod

The entire app uses **Riverpod** for reactive state management:

- **Database Provider** — Singleton `AppDatabase` instance shared across the app
- **Repository Providers** — Feature-specific data access (tasks, notes, calendar, finance)
- **UI State Providers** — Locale, theme, AI config, and permission states
- **Async Providers** — Data fetching with loading/error states for lists and analytics

### Database: Drift (SQLite ORM)

The local database uses **Drift** with 9 tables:

| Table | Purpose |
|---|---|
| `Tasks` | Tasks with recurrence, urgency, reminders, soft-delete |
| `CalendarEvents` | Events with device calendar sync IDs |
| `Notes` | Text notes with optional audio paths |
| `Transactions` | Financial records with receipt images and installments |
| `Attachments` | Polymorphic file attachments (linked to tasks/notes/events/transactions) |
| `Tags` | User-defined categorization tags |
| `TaskTags` | Many-to-many relationship between tasks and tags |
| `ProductivityStats` | Daily productivity metrics |
| `Profiles` | User profile for backup verification |

### Navigation: GoRouter

- **StatefulShellRoute** with `IndexedStack` for bottom navigation (Home, Finance)
- Smooth **slide + fade** page transitions
- Deep linking support for quick actions and widget triggers
- Separate onboarding router for first-launch flow

### AI Integration Pipeline

```
User Input (Text/Voice/Image)
        │
        ▼
┌─────────────────┐
│  Input Layer     │  Smart Input Bar / Voice Recorder / Image Scanner
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  NLP Processing  │  Turkish NLP Utils → Text Cleaning → Date Extraction
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AI Service      │  Primary API → (failover) → Backup API
│                  │  Supports: Gemini, OpenAI, any compatible endpoint
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Result Parser   │  JSON extraction → Task/Event/Note/Contact objects
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Database        │  Drift ORM → SQLite (local storage)
└─────────────────┘
```

### Security

- **API keys** stored with `flutter_secure_storage` (Android Keystore / iOS Keychain)
- **No server-side data collection** — all user data stays on-device
- Firebase Crashlytics for anonymous crash reporting only
- Graceful Firebase initialization (app works fully without Firebase)

---

## 🛠 Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Framework** | Flutter 3.10+ | Cross-platform UI |
| **Language** | Dart 3.0+ | Application logic |
| **State Management** | Riverpod | Reactive state management |
| **Database** | Drift (SQLite) | Local persistent storage |
| **Navigation** | GoRouter | Declarative routing |
| **AI / NLP** | Gemini API / OpenAI-compatible | Text analysis, vision, classification |
| **OCR** | Google ML Kit | On-device text recognition |
| **Speech** | speech_to_text | On-device speech recognition |
| **Charts** | fl_chart | Financial and productivity charts |
| **Calendar** | table_calendar + device_calendar | UI calendar + native sync |
| **Notifications** | flutter_local_notifications | Scheduled local notifications |
| **Crash Reporting** | Firebase Crashlytics | Anonymous crash analytics |
| **Security** | flutter_secure_storage | Encrypted credential storage |
| **Backup** | archive (ZIP) + share_plus | Data export and sharing |
| **Typography** | Google Fonts | Custom font rendering |
| **Localization** | Flutter Intl (ARB) | Multi-language support |

---

## 📋 Requirements

- Flutter SDK `>=3.10.0`
- Dart SDK `>=3.0.0`
- Android SDK 21+ (Android 5.0 Lollipop)
- A Gemini or OpenAI-compatible API key (for AI features)

---

## 🚀 Getting Started

### 1. Clone & Install

```bash
git clone https://github.com/daitr2024/personality.ai.git
cd personality.ai
flutter pub get
```

### 2. Firebase Setup (Optional)

Firebase is used only for crash reporting. The app works fully without it.

```bash
# Download google-services.json from Firebase Console
# Place it at: android/app/google-services.json
```

### 3. Generate Database Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Generate Localization Files

```bash
flutter gen-l10n
```

### 5. Run

```bash
flutter run
```

### 6. Build Release APK

```bash
flutter build apk --release
```

---

## ⚙️ AI Configuration

The app supports any **OpenAI-compatible API endpoint**. Configure it in:

**Settings → AI Configuration**

| Setting | Description |
|---|---|
| API Endpoint | Base URL of the AI service (e.g., `https://generativelanguage.googleapis.com/v1beta`) |
| API Key | Your API key (stored encrypted on-device) |
| Model | Model name (e.g., `gemini-2.0-flash`) |
| Temperature | Creativity level (0.0 – 1.0) |
| Max Tokens | Maximum response length |

The app also supports:
- **Backup API** — Automatic failover endpoint
- **Vision API** — Separate endpoint for image analysis
- **Local STT** — Option to always use on-device speech recognition

---

## 🔒 Privacy

- All data is stored **locally on-device** (SQLite database)
- No personal data is collected or sent to any server
- AI features send data **only** to the user-configured API endpoint
- API keys are encrypted using platform-native secure storage
- Firebase Crashlytics collects only anonymous crash data
- [Full Privacy Policy](docs/index.html)

---

## 📬 Contact

For questions, suggestions, or feedback:

📧 **daitr2024@gmail.com**

---

<p align="center">
  Built with ❤️ using Flutter<br/>
  © 2026 Personality.ai — All rights reserved.
</p>
