/// Profile page covering all four states (FL-R07, PF-DOC-11 §3.5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

import '../../application/profile_providers.dart';
import '../widgets/profile_header.dart';
import 'edit_profile_page.dart';

/// The signed-in user's profile.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profile.when(
        data: (user) => ListView(
          children: [
            ProfileHeader(profile: user),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit profil'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditProfilePage(profile: user),
                  ),
                );
              },
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Bantuan & Dukungan'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => PfErrorState(
          onRetry: () => ref.invalidate(profileProvider),
          error: error is PareException ? error : null,
          title: 'Gagal memuat profil.',
        ),
      ),
    );
  }
}
