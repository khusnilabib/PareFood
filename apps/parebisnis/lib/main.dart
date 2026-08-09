/// app_parebisnis — merchant app composition root (MO-R06, PF-DOC-06).
///
/// Boots Supabase through `pare_data` (DEP-R06), then mounts the Sprint 1
/// merchant experience — onboarding/status and menu management — behind an
/// auth + business-role-guarded router. The composition root is the only
/// place that wires concrete repositories into the feature providers
/// (FL-R04).
library;

import 'package:auth_feature/auth_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_feature/menu_feature.dart';
import 'package:merchant_feature/merchant_feature.dart';
import 'package:pare_data/pare_data.dart';
import 'package:profile_feature/profile_feature.dart';

import 'src/app.dart';
import 'src/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize(resolveAppConfig());
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(SupabaseAuthRepository()),
        menuRepositoryProvider.overrideWithValue(SupabaseMenuRepository()),
        profileRepositoryProvider.overrideWithValue(
          SupabaseProfileRepository(),
        ),
        restaurantRepositoryProvider.overrideWithValue(
          SupabaseRestaurantRepository(),
        ),
      ],
      child: const PareBisnisApp(),
    ),
  );
}
