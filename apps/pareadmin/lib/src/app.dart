/// App widget: PareAdmin theming + router host (MO-R06 keeps it tiny).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';

import 'router/app_router.dart';

/// Root widget: Material 3 theming from pare_design, hosted by GoRouter.
class PareAdminApp extends ConsumerWidget {
  const PareAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PareAdmin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
