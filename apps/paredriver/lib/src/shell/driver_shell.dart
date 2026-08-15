/// Signed-in driver shell: bottom navigation over Pekerjaan (job feed) and
/// Akun (profile). Accept/decline/pickup/deliver actions are wired to Edge
/// Functions via the composition root's callback overrides (FR-ORDER-004/005/006).
library;

import 'package:flutter/material.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:profile_feature/profile_feature.dart';

/// Hosts the signed-in driver experience.
class DriverShell extends StatelessWidget {
  const DriverShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: const TabBarView(children: [DriverJobsPage(), ProfilePage()]),
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Pekerjaan'),
            Tab(icon: Icon(Icons.person_outline), text: 'Akun'),
          ],
        ),
      ),
    );
  }
}
