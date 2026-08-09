/// Role-mismatch screen (PF-DOC-12 §3.2): shown when a signed-in account's
/// role is not `admin`. Signing out re-runs the router guards and lands the
/// user back on the sign-in page.
library;

import 'package:auth_feature/auth_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';

/// Explains the role mismatch and offers switching accounts.
class AccessDeniedPage extends ConsumerWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akses ditolak')),
      body: PfEmptyState(
        icon: Icons.block_outlined,
        title: 'Akun ini tidak memiliki akses',
        subtitle:
            'Konsol ini hanya untuk admin PareFood. Masuk dengan akun lain '
            'untuk melanjutkan.',
        actionLabel: 'Ganti akun',
        onAction: () => ref.read(signOutProvider)(),
      ),
    );
  }
}
