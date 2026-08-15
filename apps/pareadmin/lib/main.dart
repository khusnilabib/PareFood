/// app_pareadmin — web admin console composition root (MO-R06, PF-DOC-06).
///
/// Boots Supabase through `pare_data` (DEP-R06), then mounts the Sprint 1
/// admin surface — sign-in and a placeholder dashboard — behind an auth +
/// admin-role-guarded router. The composition root is the only place that
/// wires concrete repositories into the feature providers (FL-R04).
library;

import 'package:auth_feature/auth_feature.dart';
import 'package:finance_feature/finance_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_data/pare_data.dart';

import 'src/app.dart';
import 'src/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize(resolveAppConfig());
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(SupabaseAuthRepository()),
        financeRepositoryProvider.overrideWithValue(
          SupabaseFinanceRepository(),
        ),
        ordersRepositoryProvider.overrideWithValue(SupabaseOrdersRepository()),
      ],
      child: const PareAdminApp(),
    ),
  );
}
