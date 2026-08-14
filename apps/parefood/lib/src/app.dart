/// App widget: PareFood theming + router host (MO-R06 keeps it tiny).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';

import 'router/app_router.dart';

/// Root widget: Material 3 theming from pare_design, hosted by GoRouter.
/// Uses cached theme providers to prevent unnecessary theme rebuilds.
class PareFoodApp extends ConsumerWidget {
  const PareFoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    return MaterialApp.router(
      title: 'PareFood',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
