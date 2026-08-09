/// Sprint 1 driver shell: account/profile only. Sprint 2 replaces this with
/// the delivery workspace (order feed, active delivery, earnings).
library;

import 'package:flutter/material.dart';
import 'package:profile_feature/profile_feature.dart';

/// Hosts the signed-in driver experience.
class DriverShell extends StatelessWidget {
  const DriverShell({super.key});

  @override
  Widget build(BuildContext context) => const ProfilePage();
}
