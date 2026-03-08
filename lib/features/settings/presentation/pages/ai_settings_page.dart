// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/ai_config_provider.dart';

class AISettingsPage extends ConsumerStatefulWidget {
  const AISettingsPage({super.key});

  @override
  ConsumerState<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends ConsumerState<AISettingsPage> {
  final _endpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _endpointBackupController = TextEditingController();
  final _apiKeyBackupController = TextEditingController();
  final _modelBackupController = TextEditingController();
  final _visionEndpointController = TextEditingController();
  final _visionApiKeyController = TextEditingController();
  final _visionModelController = TextEditingController();
  final _visionEndpointBackupController = TextEditingController();
  final _visionApiKeyBackupController = TextEditingController();
  final _visionModelBackupController = TextEditingController();
  bool _isLoading = true;
  bool _isTesting = false;
  bool _obscureApiKey = true;
  bool _alwaysUseLocalSTT = false;

  final List<String> _availableModels = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final service = ref.read(aiConfigServiceProvider);
      _endpointController.text = await service.getEndpoint();
      _apiKeyController.text = await service.getApiKey() ?? '';
      _modelController.text = await service.getModel();

      _endpointBackupController.text = await service.getEndpointBackup();
      final apiKeyBackup = await service.getApiKeyBackup();
      _apiKeyBackupController.text = apiKeyBackup ?? '';
      _modelBackupController.text = await service.getModelBackup();

      _visionEndpointController.text = await service.getVisionEndpoint();
      _visionApiKeyController.text = await service.getVisionApiKey() ?? '';
      _visionModelController.text = await service.getVisionModel();

      _visionEndpointBackupController.text = await service
          .getVisionEndpointBackup();
      _visionApiKeyBackupController.text =
          await service.getVisionApiKeyBackup() ?? '';
      _visionModelBackupController.text = await service.getVisionModelBackup();
      _alwaysUseLocalSTT = await service.getAlwaysUseLocalSTT();
    } catch (e) {
      debugPrint('Error loading AI settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errLoadSettings(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    final service = ref.read(aiConfigServiceProvider);
    await service.setEndpoint(_endpointController.text);
    await service.setApiKey(_apiKeyController.text);
    await service.setModel(_modelController.text);

    await service.setEndpointBackup(_endpointBackupController.text);
    await service.setApiKeyBackup(_apiKeyBackupController.text);
    await service.setModelBackup(_modelBackupController.text);

    await service.setVisionEndpoint(_visionEndpointController.text);
    await service.setVisionApiKey(_visionApiKeyController.text);
    await service.setVisionModel(_visionModelController.text);

    await service.setVisionEndpointBackup(_visionEndpointBackupController.text);
    await service.setVisionApiKeyBackup(_visionApiKeyBackupController.text);
    await service.setVisionModelBackup(_visionModelBackupController.text);
    await service.setAlwaysUseLocalSTT(_alwaysUseLocalSTT);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.save),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testConnection({
    bool isBackup = false,
    bool isVision = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isTesting = true);
    final service = ref.read(aiConfigServiceProvider);

    await _saveSettings();

    final (success, errorMessage) = await service.testConnection(
      isBackup: isBackup,
      isVision: isVision,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? l10n.connectionSuccess
                : (errorMessage ?? l10n.connectionFailed),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _resetToDefaults() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetConfirmTitle),
        content: Text(l10n.resetConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              l10n.reset,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(aiConfigServiceProvider);
      await service.resetToDefaults();
      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsResetSuccess),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _endpointBackupController.dispose();
    _apiKeyBackupController.dispose();
    _modelBackupController.dispose();
    _visionEndpointController.dispose();
    _visionApiKeyController.dispose();
    _visionModelController.dispose();
    _visionEndpointBackupController.dispose();
    _visionApiKeyBackupController.dispose();
    _visionModelBackupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiConfiguration),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showAIHelpDialog(context),
            tooltip: 'Yapay Zeka Yardımı',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
            tooltip: l10n.save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // AI Setup Wizard Card
                GestureDetector(
                  onTap: () => context.push('/settings/ai-wizard'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.blue.shade400],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_fix_high_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const Gap(14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Kurulum Sihirbazı',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              Gap(4),
                              Text(
                                'Adım adım yönlendirme ile kolayca yapılandırın',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(24),

                _buildSectionTitle(l10n.apiEndpoint),
                TextField(
                  controller: _endpointController,
                  decoration: InputDecoration(
                    hintText:
                        'https://generativelanguage.googleapis.com/v1beta/openai/v1',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.link),
                    helperText: l10n.apiEndpointHint,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const Gap(24),

                _buildSectionTitle(l10n.apiKey),
                TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    hintText: 'API Anahtarı',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscureApiKey = !_obscureApiKey);
                      },
                    ),
                    helperText: l10n.apiKeySecureHint,
                  ),
                  obscureText: _obscureApiKey,
                ),
                const Gap(24),

                _buildSectionTitle(l10n.model),
                TextField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    hintText: 'gemini-1.5-flash',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.psychology),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (String value) {
                        _modelController.text = value;
                        _saveSettings();
                      },
                      itemBuilder: (BuildContext context) {
                        return _availableModels.map((String model) {
                          return PopupMenuItem<String>(
                            value: model,
                            child: Text(model),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                const Gap(24),

                _buildBackupSection(),
                const Gap(32),
                _buildVisionSection(),
                const Gap(32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
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
                        : const Icon(Icons.wifi_tethering, color: Colors.white),
                    label: Text(
                      _isTesting ? l10n.testing : l10n.testConnection,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const Gap(12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetToDefaults,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(color: Colors.orange.shade700),
                    ),
                    icon: Icon(Icons.restore, color: Colors.orange.shade700),
                    label: Text(
                      l10n.resetToDefaults,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ),
                const Gap(24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          l10n.apiKeySecureInfo,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context)!.alwaysUseLocalAudio,
                  ),
                  subtitle: const Text(
                    'İnternet olmasa dahi cihaz içi yöntemlerle sesi metne dönüştürür.',
                  ),
                  value: _alwaysUseLocalSTT,
                  onChanged: (value) {
                    setState(() => _alwaysUseLocalSTT = value);
                    _saveSettings();
                  },
                  secondary: const Icon(Icons.mic_external_off),
                ),
                const Gap(24),
              ],
            ),
    );
  }

  Widget _buildBackupSection() {
    return ExpansionTile(
      title: const Text(
        'Yedek API Yapılandırması (Failover)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Failover Sistemi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Gap(8),
              const Text(
                'Eğer ana API hata verirse otomatik olarak bu konfigürasyon kullanılacaktır.',
                style: TextStyle(fontSize: 12),
              ),
              const Gap(16),
              const Text(
                'Yedek Endpoint',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Gap(8),
              TextField(
                controller: _endpointBackupController,
                decoration: const InputDecoration(
                  hintText: 'Endpoint',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const Gap(16),
              const Text(
                'Yedek API Key',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Gap(8),
              TextField(
                controller: _apiKeyBackupController,
                obscureText: _obscureApiKey,
                decoration: const InputDecoration(
                  hintText: 'API Key',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              const Gap(16),
              const Text(
                'Yedek Model',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Gap(8),
              TextField(
                controller: _modelBackupController,
                decoration: InputDecoration(
                  hintText: 'gemini-1.5-flash',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.psychology),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (String value) {
                      _modelBackupController.text = value;
                      _saveSettings();
                    },
                    itemBuilder: (BuildContext context) {
                      return _availableModels.map((String model) {
                        return PopupMenuItem<String>(
                          value: model,
                          child: Text(model),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _testConnection(isBackup: true),
                  icon: const Icon(Icons.wifi_tethering),
                  label: Text(
                    AppLocalizations.of(context)!.testBackupConnection,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisionSection() {
    return ExpansionTile(
      title: const Text(
        'Görsel Analiz Yapılandırması (Vision)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vision Sistemi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const Gap(8),
              const Text(
                'Makbuz ve fiş tarama işlemleri için görsel destekli API ayarları.',
                style: TextStyle(fontSize: 12),
              ),
              const Gap(16),
              const Text(
                'Vision Endpoint',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Gap(8),
              TextField(
                controller: _visionEndpointController,
                decoration: const InputDecoration(
                  hintText: 'Endpoint',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const Gap(16),
              const Text(
                'Vision API Key',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Gap(8),
              TextField(
                controller: _visionApiKeyController,
                obscureText: _obscureApiKey,
                decoration: const InputDecoration(
                  hintText: 'API Key',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              const Gap(16),
              const Text(
                'Vision Model',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Gap(8),
              TextField(
                controller: _visionModelController,
                decoration: InputDecoration(
                  hintText: 'gemini-1.5-flash',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.camera_alt),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (String value) {
                      _visionModelController.text = value;
                      _saveSettings();
                    },
                    itemBuilder: (BuildContext context) {
                      return _availableModels.map((String model) {
                        return PopupMenuItem<String>(
                          value: model,
                          child: Text(model),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _testConnection(isVision: true),
                  icon: const Icon(Icons.wifi_tethering),
                  label: Text(
                    AppLocalizations.of(context)!.testVisionConnection,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAIHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.blue),
            const Gap(12),
            Text(AppLocalizations.of(context)!.aiGuide),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpSection(
                  'Google Gemini (Önerilir)',
                  'Günlük 1500 isteğe kadar ücretsiz.',
                  [
                    '1. aistudio.google.com adresinden Key alın.',
                    '2. Endpoint: https://generativelanguage.googleapis.com/v1beta/openai',
                    '3. Model: gemini-1.5-flash',
                  ],
                  Colors.blue,
                ),
                const Gap(16),
                _buildHelpSection('Önemli', '', [
                  '• "Hata 401": API anahtarınız yanlıştır.',
                  '• "Hata 404": Endpoint yanlış girilmiştir.',
                ], Colors.grey),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.understood),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
    String title,
    String subtitle,
    List<String> steps,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 15,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const Gap(4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
          const Gap(8),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(step, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
