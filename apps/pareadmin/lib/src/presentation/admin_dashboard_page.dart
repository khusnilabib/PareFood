/// Sprint 1 placeholder dashboard: the admin tooling (merchant moderation,
/// support, platform reports) ships in Sprint 4.
library;

import 'package:flutter/material.dart';
import 'package:pare_design/pare_design.dart';

/// Announces the upcoming console for signed-in admins.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PareAdmin')),
      body: const PfEmptyState(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Konsol admin — Sprint 4',
        subtitle:
            'Moderasi merchant, dukungan pelanggan, dan laporan platform '
            'akan hadir di Sprint 4.',
      ),
    );
  }
}
