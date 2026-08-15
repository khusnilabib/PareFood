/// Admin finance page: tabbed settlements + payouts + reconciliation.
library;

import 'package:finance_feature/finance_feature.dart';
import 'package:flutter/material.dart';

import 'admin_shell.dart';

/// Admin finance section with 3 tabs: Settlements, Payouts, Reconciliation.
class AdminFinancePage extends StatelessWidget {
  const AdminFinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      section: AdminSection.finance,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Finance'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Settlement'),
                Tab(text: 'Payout Driver'),
                Tab(text: 'Rekonsiliasi'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [SettlementsPage(), PayoutsPage(), ReconciliationPage()],
          ),
        ),
      ),
    );
  }
}
