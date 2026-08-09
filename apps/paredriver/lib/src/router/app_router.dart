/// App router (PF-DOC-17, NV-R02): one GoRouter owned by the composition
/// root. Guards read the auth session; a [ChangeNotifier] re-runs redirects
/// whenever the session changes.
library;

import 'package:auth_feature/auth_feature.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shell/driver_shell.dart';

const _loginPath = '/login';
const _registerPath = '/register';

/// [ChangeNotifier] with a public hook so the router can be notified from
/// outside the class (`notifyListeners` itself is protected).
final class _SessionChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Notifies the router whenever the auth session emits (NV-R02).
final authRefreshProvider = Provider<ChangeNotifier>((ref) {
  final notifier = _SessionChangeNotifier();
  ref.listen(authSessionProvider, (_, _) => notifier.notify());
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// The driver app router: signed-in shell plus public auth screens.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: ref.watch(authRefreshProvider),
    redirect: (context, state) {
      final session = ref.read(authSessionProvider).value;
      final signedIn = session?.isSignedIn ?? false;
      final isAuthRoute =
          state.matchedLocation == _loginPath ||
          state.matchedLocation == _registerPath;
      if (!signedIn) return isAuthRoute ? null : _loginPath;
      if (isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const DriverShell()),
      GoRoute(path: _loginPath, builder: (_, _) => const SignInPage()),
      GoRoute(path: _registerPath, builder: (_, _) => const RegisterPage()),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('Tidak ditemukan')),
      body: Center(child: Text('Alamat ${state.uri.path} tidak dikenal.')),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
