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
  // Main config
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _endpointController = TextEditingController();

  // Backup config
  final _endpointBackupController = TextEditingController();
  final _apiKeyBackupController = TextEditingController();
  final _modelBackupController = TextEditingController();

  // Vision config
  final _visionEndpointController = TextEditingController();
  final _visionApiKeyController = TextEditingController();
  final _visionModelController = TextEditingController();
  final _visionEndpointBackupController = TextEditingController();
  final _visionApiKeyBackupController = TextEditingController();
  final _visionModelBackupController = TextEditingController();

  bool _isLoading = true;
  bool _isTesting = false;
  bool _obscureApiKey = true;

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
      _apiKeyBackupController.text = await service.getApiKeyBackup() ?? '';
      _modelBackupController.text = await service.getModelBackup();

      _visionEndpointController.text = await service.getVisionEndpoint();
      _visionApiKeyController.text = await service.getVisionApiKey() ?? '';
      _visionModelController.text = await service.getVisionModel();

      _visionEndpointBackupController.text = await service
          .getVisionEndpointBackup();
      _visionApiKeyBackupController.text =
          await service.getVisionApiKeyBackup() ?? '';
      _visionModelBackupController.text = await service.getVisionModelBackup();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final service = ref.read(aiConfigServiceProvider);

    // Main
    await service.setEndpoint(_endpointController.text);
    await service.setApiKey(_apiKeyController.text);
    await service.setModel(_modelController.text);

    // Backup
    await service.setEndpointBackup(_endpointBackupController.text);
    await service.setApiKeyBackup(_apiKeyBackupController.text);
    await service.setModelBackup(_modelBackupController.text);

    // Vision
    await service.setVisionEndpoint(_visionEndpointController.text);
    await service.setVisionApiKey(_visionApiKeyController.text);
    await service.setVisionModel(_visionModelController.text);

    // Vision Backup
    await service.setVisionEndpointBackup(_visionEndpointBackupController.text);
    await service.setVisionApiKeyBackup(_visionApiKeyBackupController.text);
    await service.setVisionModelBackup(_visionModelBackupController.text);

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

    if (mounted) setState(() => _isTesting = false);
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiConfiguration),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
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
                // ─── Wizard Card ──────────────────────────────
                _buildWizardCard(cs),
                const Gap(24),

                // ─── Main: API Key ────────────────────────────
                _buildSectionHeader(
                  icon: Icons.key_rounded,
                  color: cs.primary,
                  title: l10n.apiKey,
                  subtitle: 'Ses, görsel ve metin analizi için kullanılır',
                ),
                const Gap(12),
                TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureApiKey = !_obscureApiKey),
                    ),
                    helperText: l10n.apiKeySecureHint,
                  ),
                  obscureText: _obscureApiKey,
                ),
                const Gap(20),

                // ─── Main: Model ──────────────────────────────
                _buildSectionHeader(
                  icon: Icons.psychology_rounded,
                  color: Colors.purple,
                  title: l10n.model,
                  subtitle: 'AI yanıtlarının kalitesini ve hızını belirler',
                ),
                const Gap(12),
                TextField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    hintText: 'gemini-2.0-flash',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

                // ─── Test Connection ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                        : const Icon(Icons.wifi_tethering, color: Colors.white),
                    label: Text(
                      _isTesting ? l10n.testing : l10n.testConnection,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Gap(16),

                // ─── Security Info ────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security_rounded, color: cs.primary, size: 20),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          l10n.apiKeySecureInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),

                const Gap(32),

                // ─── Advanced Settings ────────────────────────
                _buildAdvancedSection(l10n, cs),

                const Gap(24),

                // ─── Reset Button ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetToDefaults,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      side: BorderSide(color: Colors.orange.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(Icons.restore, color: Colors.orange.shade700),
                    label: Text(
                      l10n.resetToDefaults,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ),
                const Gap(24),
              ],
            ),
    );
  }

  // ─── Wizard Card ────────────────────────────────────────────────

  Widget _buildWizardCard(ColorScheme cs) {
    return GestureDetector(
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
                    'İlk kez mi kuruyorsunuz? Adım adım rehber ile kolayca yapılandırın',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
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
    );
  }

  // ─── Section Header ─────────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Advanced Settings Section ──────────────────────────────────

  Widget _buildAdvancedSection(AppLocalizations l10n, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Icon(
          Icons.tune_rounded,
          color: cs.onSurface.withValues(alpha: 0.5),
        ),
        title: const Text(
          'Gelişmiş Ayarlar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          'Endpoint, yedek API, görsel analiz ayarları',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          const Gap(8),

          // ─── Custom Endpoint ───────────────────────
          _buildAdvancedLabel('API Endpoint', Icons.link_rounded),
          const Gap(8),
          TextField(
            controller: _endpointController,
            decoration: InputDecoration(
              hintText:
                  'https://generativelanguage.googleapis.com/v1beta/openai/v1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.link, size: 20),
              helperText: l10n.apiEndpointHint,
              isDense: true,
            ),
            keyboardType: TextInputType.url,
            style: const TextStyle(fontSize: 13),
          ),
          const Gap(20),

          // ─── Backup API ────────────────────────────
          _buildAdvancedGroupTitle(
            'Yedek API (Failover)',
            'Ana API hata verirse otomatik kullanılır',
            Colors.orange,
            Icons.swap_horiz_rounded,
          ),
          const Gap(12),
          _buildAdvancedLabel('Yedek Endpoint', Icons.link_rounded),
          const Gap(8),
          TextField(
            controller: _endpointBackupController,
            decoration: InputDecoration(
              hintText: 'Endpoint',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.link, size: 20),
              isDense: true,
            ),
            keyboardType: TextInputType.url,
            style: const TextStyle(fontSize: 13),
          ),
          const Gap(12),
          _buildAdvancedLabel('Yedek API Key', Icons.key_rounded),
          const Gap(8),
          TextField(
            controller: _apiKeyBackupController,
            obscureText: _obscureApiKey,
            decoration: InputDecoration(
              hintText: 'API Key',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.key, size: 20),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const Gap(12),
          _buildAdvancedLabel('Yedek Model', Icons.psychology_rounded),
          const Gap(8),
          _buildModelField(_modelBackupController),
          const Gap(8),
          _buildTestButton(
            l10n.testBackupConnection,
            () => _testConnection(isBackup: true),
          ),
          const Gap(20),

          // ─── Vision API ────────────────────────────
          _buildAdvancedGroupTitle(
            'Görsel Analiz (Vision)',
            'Boş bırakırsanız ana API key kullanılır',
            Colors.purple,
            Icons.camera_alt_rounded,
          ),
          const Gap(12),
          _buildAdvancedLabel('Vision Endpoint', Icons.link_rounded),
          const Gap(8),
          TextField(
            controller: _visionEndpointController,
            decoration: InputDecoration(
              hintText: 'Boş = Ana endpoint',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.link, size: 20),
              isDense: true,
            ),
            keyboardType: TextInputType.url,
            style: const TextStyle(fontSize: 13),
          ),
          const Gap(12),
          _buildAdvancedLabel('Vision API Key', Icons.key_rounded),
          const Gap(8),
          TextField(
            controller: _visionApiKeyController,
            obscureText: _obscureApiKey,
            decoration: InputDecoration(
              hintText: 'Boş = Ana API key',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.key, size: 20),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const Gap(12),
          _buildAdvancedLabel('Vision Model', Icons.psychology_rounded),
          const Gap(8),
          _buildModelField(_visionModelController),
          const Gap(8),
          _buildTestButton(
            l10n.testVisionConnection,
            () => _testConnection(isVision: true),
          ),
        ],
      ),
    );
  }

  // ─── Helper Widgets ─────────────────────────────────────────────

  Widget _buildAdvancedLabel(String text, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
        const Gap(8),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedGroupTitle(
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'gemini-2.0-flash',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.psychology, size: 20),
        isDense: true,
        suffixIcon: PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          onSelected: (String value) {
            controller.text = value;
            _saveSettings();
          },
          itemBuilder: (BuildContext context) {
            return _availableModels.map((String model) {
              return PopupMenuItem<String>(
                value: model,
                child: Text(model, style: const TextStyle(fontSize: 13)),
              );
            }).toList();
          },
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _isTesting ? null : onPressed,
        icon: const Icon(Icons.wifi_tethering, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
