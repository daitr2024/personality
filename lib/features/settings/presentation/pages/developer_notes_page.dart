import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/generated/app_localizations.dart';

class DeveloperNotesPage extends StatelessWidget {
  const DeveloperNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appNotes),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade700,
                  size: 32,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Gelecek Versiyonlarda Eklenecek Özellikler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Gap(24),

          // Feature List
          _buildFeatureSection(
            title: '📦 Arşivleme Sistemi',
            features: [
              'Not ve görevleri arşivleme',
              'Tamamlanan işleri notlar/görevler sayfasında kalabalık yapmamak için ayrı bir arşiv sayfasına aktar',
            ],
          ),

          const Gap(16),

          _buildFeatureSection(
            title: '⏰ Hatırlatma Sistemi',
            features: [
              'Görev ve takvim etkinliği zamanı gelmeden önce hatırlatma fonksiyonu',
              'Not, görev, takvim eklerken kolay bir hatırlatma fonksiyonu ekle',
            ],
          ),

          const Gap(16),

          _buildFeatureSection(
            title: '📸 Fiş Okuma İyileştirmesi',
            features: [
              'Fiş görüntüsünü daha iyi OCR edecek ve algılayacak bir çözüm önerisi buldur',
            ],
          ),

          const Gap(32),

          // Info Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Bu sayfa geliştirici notları içindir. Yeni özellikler eklemek için kodu düzenleyin.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection({
    required String title,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Gap(12),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

