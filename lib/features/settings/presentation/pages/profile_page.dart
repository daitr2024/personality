// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileProvider, (previous, next) {
      if (next.hasValue && next.value != null && _nameController.text.isEmpty) {
        _nameController.text = next.value!.name ?? '';
        _emailController.text = next.value!.email ?? '';
      }
    });

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountInfo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profileInfo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text(
              l10n.profileInfoSubtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Gap(24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const Gap(16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.email,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email_outlined),
                hintText: 'ornek@mail.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(profileRepositoryProvider)
                      .updateProfile(
                        name: _nameController.text,
                        email: _emailController.text,
                      );
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.infoUpdated)));
                  context.pop();
                },
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
