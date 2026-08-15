/// Admin navigation shell: side rail for web, bottom nav for mobile.
/// Sections: Dashboard, Pesanan, Finance, Audit. Navigation via GoRouter paths.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Admin console sections.
enum AdminSection { dashboard, orders, finance, audit }

/// Hosts the admin console with a navigation rail (web) / bottom bar (mobile).
class AdminShell extends StatelessWidget {
  const AdminShell({required this.section, required this.child, super.key});

  final AdminSection section;
  final Widget child;

  static const _destinations = <(AdminSection, String, IconData, IconData)>[
    (
      AdminSection.dashboard,
      'Dashboard',
      Icons.dashboard_outlined,
      Icons.dashboard,
    ),
    (
      AdminSection.orders,
      'Pesanan',
      Icons.receipt_long_outlined,
      Icons.receipt_long,
    ),
    (
      AdminSection.finance,
      'Finance',
      Icons.account_balance_outlined,
      Icons.account_balance,
    ),
    (AdminSection.audit, 'Audit', Icons.history_outlined, Icons.history),
  ];

  static String _pathFor(AdminSection s) => switch (s) {
    AdminSection.dashboard => '/',
    AdminSection.orders => '/orders',
    AdminSection.finance => '/finance',
    AdminSection.audit => '/audit',
  };

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _destinations.indexWhere((d) => d.$1 == section);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (i) =>
                      GoRouter.of(context).go(_pathFor(_destinations[i].$1)),
                  extended: constraints.maxWidth > 1100,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.$3),
                        selectedIcon: Icon(d.$4),
                        label: Text(d.$2),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: child),
              NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (i) =>
                    GoRouter.of(context).go(_pathFor(_destinations[i].$1)),
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(
                      icon: Icon(d.$3),
                      selectedIcon: Icon(d.$4),
                      label: d.$2,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
