/// Admin dashboard: order board with filters + force-cancel (FR-ORDER-010/011).
/// Replaces the Sprint-1 placeholder.
library;

import 'package:flutter/material.dart';
import 'package:orders_feature/orders_feature.dart';

/// The admin console root: an order board.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminOrderBoardPage();
  }
}
