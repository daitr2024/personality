// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/ai_config_provider.dart';

class AISetupWizardPage extends ConsumerStatefulWidget {
  const AISetupWizardPage({super.key});

  @override
  ConsumerState<AISetupWizardPage> createState() => _AISetupWizardPageState();
}

class _AISetupWizardPageState extends ConsumerState<AISetupWizardPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Form state
  final _apiKeyController = TextEditingController();
  String _selectedModel = 'gemini-2.0-flash';
  bool _obscureApiKey = true;
  bool _isTesting = false;
  bool _testPassed = false;
  String? _testError;

  // Clipboard tracking
  bool _waitingForClipboard = false;
  bool _clipboardKeyDetected = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _checkController;

  final List<String> _availableModels = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadExistingKey();
  }

  Future<void> _loadExistingKey() async {
    final service = ref.read(aiConfigServiceProvider);
    final existingKey = await service.getApiKey();
    final existingModel = await service.getModel();
    if (existingKey != null && existingKey.isNotEmpty) {
      _apiKeyController.text = existingKey;
    }
    _selectedModel = existingModel;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _apiKeyController.dispose();
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  // ─── App Lifecycle: Clipboard monitoring ───────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForClipboard) {
      _checkClipboardForApiKey();
    }
  }

  Future<void> _checkClipboardForApiKey() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text?.trim() ?? '';

      // Check if it looks like a Google API key (AIza prefix, ~39 chars)
      if (text.startsWith('AIza') && text.length >= 30 && text.length <= 50) {
        // Only show if it's different from what's already entered
        if (text != _apiKeyController.text.trim()) {
          if (mounted) {
            setState(() {
              _clipboardKeyDetected = true;
              _waitingForClipboard = false;
            });
            // Show the detection dialog
            _showClipboardDetectedDialog(text);
          }
        } else {
          setState(() => _waitingForClipboard = false);
        }
      } else {
        setState(() => _waitingForClipboard = false);
      }
    } catch (_) {
      if (mounted) setState(() => _waitingForClipboard = false);
    }
  }

  void _showClipboardDetectedDialog(String key) {
    HapticFeedback.mediumImpact();
    final maskedKey =
        '${key.substring(0, 8)}...${key.substring(key.length - 4)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.green,
            size: 32,
          ),
        ),
        title: const Text('API Anahtarı Algılandı! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Panoda bir Google API anahtarı tespit ettik. Bu anahtarı kullanmak ister misiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.key_rounded, size: 18),
                  const Gap(8),
                  Text(
                    maskedKey,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hayır'),
          ),
          FilledButton.icon(
            onPressed: () {
              _apiKeyController.text = key;
              setState(() {
                _clipboardKeyDetected = false;
              });
              Navigator.pop(ctx);

              // If we're on the info page, auto-navigate to API key page
              if (_currentPage == 1) {
                _nextPage();
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('API anahtarı başarıyla yapıştırıldı! ✓'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Kullan'),
          ),
        ],
      ),
    );
  }
  // ─── Scan API Key from Image (OCR) ─────────────────────────────

  Future<void> _scanApiKeyFromImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Görsel taranıyor...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      try {
        final RecognizedText recognizedText = await textRecognizer.processImage(
          inputImage,
        );

        // Search for API key pattern in all text blocks
        String? foundKey;
        for (final block in recognizedText.blocks) {
          for (final line in block.lines) {
            final lineText = line.text.trim();
            // Look for Google API key pattern
            if (lineText.startsWith('AIza') &&
                lineText.length >= 30 &&
                lineText.length <= 50) {
              // Clean the key — remove any spaces or special chars
              foundKey = lineText.replaceAll(RegExp(r'\s'), '');
              break;
            }
            // Also check within text (key might be part of a longer string)
            final keyMatch = RegExp(
              r'AIza[A-Za-z0-9_-]{25,45}',
            ).firstMatch(lineText);
            if (keyMatch != null) {
              foundKey = keyMatch.group(0);
              break;
            }
          }
          if (foundKey != null) break;
        }

        // Dismiss loading snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        if (foundKey != null && mounted) {
          _apiKeyController.text = foundKey;
          setState(() {});
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'API anahtarı bulundu ve yapıştırıldı! ✓ (${foundKey.substring(0, 8)}...)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Görselde API anahtarı bulunamadı. '
                'Lütfen "AIza..." ile başlayan anahtarın net göründüğünden emin olun.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } finally {
        textRecognizer.close();
        // Delete temp file
        try {
          final tempFile = File(pickedFile.path);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('OCR error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görsel tarama hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Open AI Studio in-app ─────────────────────────────────────

  Future<void> _openAIStudio() async {
    setState(() => _waitingForClipboard = true);

    final uri = Uri.parse('https://aistudio.google.com/apikey');

    // Try in-app browser first (Chrome Custom Tabs on Android)
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
      );
      if (!launched) {
        // Fallback to external browser
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Navigation & Logic ────────────────────────────────────────

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishWizard();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return true;
      case 1:
        return true;
      case 2:
        return _apiKeyController.text.trim().isNotEmpty;
      case 3:
        return true;
      default:
        return true;
    }
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) return;

    setState(() {
      _isTesting = true;
      _testPassed = false;
      _testError = null;
    });

    final service = ref.read(aiConfigServiceProvider);

    await service.setApiKey(_apiKeyController.text.trim());
    await service.setModel(_selectedModel);
    final defaultEndpoint =
        'https://generativelanguage.googleapis.com/v1beta/openai/v1';
    await service.setEndpoint(defaultEndpoint);

    final (success, errorMessage) = await service.testConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testPassed = success;
        _testError = success ? null : errorMessage;
      });

      if (success) {
        _checkController.forward(from: 0);
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> _finishWizard() async {
    final service = ref.read(aiConfigServiceProvider);
    await service.setApiKey(_apiKeyController.text.trim());
    await service.setModel(_selectedModel);

    if (mounted) {
      await service.setApiKeyBackup(_apiKeyController.text.trim());
      await service.setModelBackup(_selectedModel);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI yapılandırması tamamlandı! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Kapat',
                  ),
                  const Gap(8),
                  Expanded(child: _buildProgressBar(cs)),
                  const Gap(16),
                  Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Gap(8),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(cs),
                  _buildInfoPage(cs),
                  _buildApiKeyPage(cs),
                  _buildTestPage(cs),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Geri'),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  if (_currentPage != 3 ||
                      (_currentPage == 3 &&
                          (_testPassed ||
                              _apiKeyController.text.trim().isNotEmpty)))
                    FilledButton(
                      onPressed: _canProceed ? _nextPage : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _totalPages - 1
                                ? 'Tamamla'
                                : 'Devam',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(8),
                          Icon(
                            _currentPage == _totalPages - 1
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Progress Bar ──────────────────────────────────────────────

  Widget _buildProgressBar(ColorScheme cs) {
    return Row(
      children: List.generate(_totalPages, (i) {
        final isCompleted = i < _currentPage;
        final isCurrent = i == _currentPage;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isCurrent ? 6 : 4,
            margin: EdgeInsets.only(right: i < _totalPages - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  // ─── Page Layout ───────────────────────────────────────────────

  Widget _buildPageLayout({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const Gap(20),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const Gap(8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
          const Gap(28),
          child,
        ],
      ),
    );
  }

  // ─── Step 1: Welcome ──────────────────────────────────────────

  Widget _buildWelcomePage(ColorScheme cs) {
    return _buildPageLayout(
      icon: Icons.auto_awesome_rounded,
      iconColor: Colors.purple,
      title: 'AI Kurulum Sihirbazı',
      subtitle:
          'Sesli görev ekleme, akıllı analiz ve görüntü tarama gibi yapay zeka özelliklerini kullanabilmek için API yapılandırması gerekir.\n\nBu sihirbaz sizi adım adım yönlendirecek.',
      child: Column(
        children: [
          _buildFeatureCard(
            icon: Icons.mic_rounded,
            color: Colors.blue,
            title: 'Sesli Görev Ekleme',
            description: 'Konuşarak otomatik görev, etkinlik ve not oluşturun.',
          ),
          const Gap(12),
          _buildFeatureCard(
            icon: Icons.document_scanner_rounded,
            color: Colors.orange,
            title: 'Akıllı Görüntü Tarama',
            description: 'Fişleri, belgeleri ve görselleri analiz edin.',
          ),
          const Gap(12),
          _buildFeatureCard(
            icon: Icons.psychology_rounded,
            color: Colors.green,
            title: 'Yapay Zeka Analizi',
            description:
                'Metni otomatik sınıflandırın ve akıllı öneriler alın.',
          ),
          const Gap(24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Tamamen ücretsiz! Google Gemini API günlük 1500 istek hakkı sunar.',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Gap(4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: How to get API Key ────────────────────────────────

  Widget _buildInfoPage(ColorScheme cs) {
    return _buildPageLayout(
      icon: Icons.key_rounded,
      iconColor: Colors.blue,
      title: 'API Anahtarı Nasıl Alınır?',
      subtitle:
          'Google AI Studio\'dan ücretsiz bir API anahtarı almanız gerekiyor. Aşağıdaki adımları takip edin:',
      child: Column(
        children: [
          _buildStepCard(
            number: '1',
            title: 'Aşağıdaki butona tıklayın',
            description: 'Google AI Studio doğrudan uygulama içinde açılacak.',
            color: Colors.blue,
          ),
          const Gap(12),
          _buildStepCard(
            number: '2',
            title: 'Google hesabınızla giriş yapın',
            description: 'Gmail hesabınızla giriş yapmanız yeterli.',
            color: Colors.green,
          ),
          const Gap(12),
          _buildStepCard(
            number: '3',
            title: '"Create API Key" butonuna tıklayın',
            description:
                '"Create API key in new project" seçeneğiyle yeni anahtar oluşturun.',
            color: Colors.orange,
          ),
          const Gap(12),
          _buildStepCard(
            number: '4',
            title: 'Anahtarı kopyalayın ve geri dönün',
            description:
                'Oluşan anahtarı "Copy" ile kopyalayın. Uygulamaya döndüğünüzde otomatik algılanacak!',
            color: Colors.purple,
            highlight: true,
          ),
          const Gap(24),

          // Main CTA: Open AI Studio in-app
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openAIStudio,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(18),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(
                Icons.open_in_browser_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'Google AI Studio\'yu Aç',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Gap(12),

          // Clipboard monitoring status
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _waitingForClipboard
                  ? Colors.blue.withValues(alpha: 0.06)
                  : _clipboardKeyDetected
                  ? Colors.green.withValues(alpha: 0.06)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: _waitingForClipboard
                  ? Border.all(color: Colors.blue.withValues(alpha: 0.2))
                  : _clipboardKeyDetected
                  ? Border.all(color: Colors.green.withValues(alpha: 0.2))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  _waitingForClipboard
                      ? Icons.content_paste_search_rounded
                      : _clipboardKeyDetected
                      ? Icons.check_circle_rounded
                      : Icons.content_paste_go_rounded,
                  color: _waitingForClipboard
                      ? Colors.blue
                      : _clipboardKeyDetected
                      ? Colors.green
                      : cs.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    _waitingForClipboard
                        ? 'Pano izleniyor... API anahtarını kopyalayıp geri dönün.'
                        : _clipboardKeyDetected
                        ? 'API anahtarı algılandı ve yapıştırıldı!'
                        : 'API anahtarını kopyaladığınızda otomatik algılanır.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _waitingForClipboard
                          ? Colors.blue.shade700
                          : _clipboardKeyDetected
                          ? Colors.green.shade700
                          : cs.onSurface.withValues(alpha: 0.5),
                      fontWeight: _waitingForClipboard
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (_waitingForClipboard)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
          const Gap(12),

          // Security note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: cs.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'API anahtarınız yalnızca cihazınızda şifreli olarak saklanır. Sunuculara gönderilmez.',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required Color color,
    bool highlight = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.06)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: color.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Gap(4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (highlight) Icon(Icons.auto_awesome, size: 16, color: color),
        ],
      ),
    );
  }

  // ─── Step 3: API Key Input ────────────────────────────────────

  Widget _buildApiKeyPage(ColorScheme cs) {
    return _buildPageLayout(
      icon: Icons.vpn_key_rounded,
      iconColor: Colors.deepPurple,
      title: 'API Anahtarını Girin',
      subtitle:
          'Google AI Studio\'dan aldığınız API anahtarını aşağıya yapıştırın.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick paste from clipboard button
          if (_apiKeyController.text.trim().isEmpty) ...[
            Row(
              children: [
                // Paste from clipboard
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      final text = data?.text?.trim() ?? '';
                      if (text.startsWith('AIza') && text.length >= 30) {
                        _apiKeyController.text = text;
                        setState(() {});
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Panodan yapıştırıldı! ✓'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      } else if (text.isNotEmpty) {
                        _apiKeyController.text = text;
                        setState(() {});
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Panoda API anahtarı bulunamadı. Lütfen önce kopyalayın.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      side: BorderSide(
                        color: cs.primary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(Icons.content_paste_rounded, color: cs.primary),
                    label: Text(
                      'Yapıştır',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                // Camera OCR
                OutlinedButton.icon(
                  onPressed: () => _scanApiKeyFromImage(ImageSource.camera),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.teal,
                  ),
                  label: const Text(
                    'Kamera',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const Gap(8),
                // Gallery OCR
                OutlinedButton.icon(
                  onPressed: () => _scanApiKeyFromImage(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    side: BorderSide(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.orange,
                  ),
                  label: const Text(
                    'Galeri',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
          ],

          // API Key input
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'AIzaSy... ile başlayan anahtarınız',
              helperText:
                  'Google AI Studio\'dan kopyaladığınız anahtarı yapıştırın',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureApiKey
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _obscureApiKey = !_obscureApiKey),
                  ),
                  if (_apiKeyController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      tooltip: 'Temizle',
                      onPressed: () {
                        _apiKeyController.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),

          // Validation indicator
          if (_apiKeyController.text.trim().isNotEmpty) ...[
            const Gap(12),
            _buildKeyValidationIndicator(),
          ],

          const Gap(24),

          // Didn't get key yet? Link back
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Henüz anahtarınız yok mu?',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openAIStudio,
                  child: const Text(
                    'AI Studio\'yu Aç',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const Gap(24),

          // Model selection
          Text(
            'AI Model Seçimi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Gap(8),
          Text(
            'Önerilen: gemini-2.0-flash (hızlı, doğru ve ücretsiz)',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Gap(12),
          ...(_availableModels.map((model) {
            final isSelected = _selectedModel == model;
            final isRecommended = model == 'gemini-2.0-flash';
            return GestureDetector(
              onTap: () => setState(() => _selectedModel = model),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.08)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology_rounded,
                      color: isSelected
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.4),
                      size: 22,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                model,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (isRecommended) ...[
                                const Gap(8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Önerilen',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const Gap(2),
                          Text(
                            _getModelDescription(model),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: cs.primary,
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildKeyValidationIndicator() {
    final key = _apiKeyController.text.trim();
    final isValidFormat = key.startsWith('AIza') && key.length >= 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isValidFormat
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isValidFormat
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            size: 16,
            color: isValidFormat ? Colors.green : Colors.orange,
          ),
          const Gap(8),
          Text(
            isValidFormat
                ? 'Geçerli format (AIza... ${key.length} karakter)'
                : 'Beklenmeyen format — yine de devam edebilirsiniz',
            style: TextStyle(
              fontSize: 12,
              color: isValidFormat
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getModelDescription(String model) {
    switch (model) {
      case 'gemini-2.0-flash':
        return 'En hızlı ve en dengeli model. Günlük kullanım için ideal.';
      case 'gemini-2.0-flash-lite':
        return 'Daha hafif versiyon. Çok hızlı ama daha az detaylı.';
      case 'gemini-2.5-flash':
        return 'Yeni nesil Flash. Daha akıllı ama biraz daha yavaş.';
      case 'gemini-2.5-pro':
        return 'En güçlü model. Karmaşık analizler için. Sınırlı kota.';
      default:
        return '';
    }
  }

  // ─── Step 4: Test & Complete ───────────────────────────────────

  Widget _buildTestPage(ColorScheme cs) {
    return _buildPageLayout(
      icon: _testPassed
          ? Icons.check_circle_rounded
          : Icons.wifi_tethering_rounded,
      iconColor: _testPassed ? Colors.green : Colors.blue,
      title: _testPassed ? 'Bağlantı Başarılı! 🎉' : 'Bağlantıyı Test Edin',
      subtitle: _testPassed
          ? 'API anahtarınız doğru ve çalışıyor. Artık tüm AI özelliklerini kullanabilirsiniz!'
          : 'API anahtarınızın doğru çalıştığından emin olmak için bağlantıyı test edin.',
      child: Column(
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  icon: Icons.link_rounded,
                  label: 'Endpoint',
                  value: 'Google Gemini (Varsayılan)',
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  icon: Icons.key_rounded,
                  label: 'API Key',
                  value: _apiKeyController.text.isNotEmpty
                      ? '${_apiKeyController.text.substring(0, _apiKeyController.text.length > 8 ? 8 : _apiKeyController.text.length)}...${_apiKeyController.text.length > 4 ? _apiKeyController.text.substring(_apiKeyController.text.length - 4) : ''}'
                      : 'Ayarlanmadı',
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  icon: Icons.psychology_rounded,
                  label: 'Model',
                  value: _selectedModel,
                ),
              ],
            ),
          ),
          const Gap(24),

          // Test button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(18),
                backgroundColor: _testPassed
                    ? Colors.green
                    : _testError != null
                    ? Colors.red
                    : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _testPassed
                          ? Icons.check_circle_rounded
                          : _testError != null
                          ? Icons.error_rounded
                          : Icons.wifi_tethering_rounded,
                      color: Colors.white,
                    ),
              label: Text(
                _isTesting
                    ? 'Test ediliyor...'
                    : _testPassed
                    ? 'Bağlantı Başarılı ✓'
                    : _testError != null
                    ? 'Tekrar Dene'
                    : 'Bağlantıyı Test Et',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Error message
          if (_testError != null) ...[
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      Gap(8),
                      Text(
                        'Bağlantı Hatası',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    _testError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const Gap(12),
                  const Text(
                    'Çözüm önerileri:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const Gap(4),
                  Text(
                    '• API anahtarının doğru kopyalandığından emin olun\n'
                    '• İnternet bağlantınızı kontrol edin\n'
                    '• API anahtarının aktif olduğundan emin olun\n'
                    '• Birkaç dakika bekleyip tekrar deneyin',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Success message
          if (_testPassed) ...[
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    color: Colors.green,
                    size: 22,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'Her şey hazır! "Tamamla" butonuna basarak kurulumu bitirebilirsiniz.',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!_testPassed && _testError == null && !_isTesting) ...[
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'Test isteğe bağlıdır. Tamamla butonuna basarak kaydedebilirsiniz.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const Gap(12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
