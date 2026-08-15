/// Admin dashboard: analytics KPIs + quick links (S10 + S11).
library;

import 'package:finance_feature/finance_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_shell.dart';

/// The admin console root: analytics dashboard.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdminShell(
      section: AdminSection.dashboard,
      child: AnalyticsDashboardPage(),
    );
  }
}
