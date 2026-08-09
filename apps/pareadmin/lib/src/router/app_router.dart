/// App router (PF-DOC-17, NV-R02): one GoRouter owned by the composition
/// root. Guards require a signed-in session AND the `admin` role
/// (PF-DOC-12 §3.2); a [ChangeNotifier] re-runs redirects whenever the
/// session changes.
library;

import 'package:auth_feature/auth_feature.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/access_denied_page.dart';
import '../presentation/admin_dashboard_page.dart';

const _loginPath = '/login';
const _accessDeniedPath = '/access-denied';

/// Role required to use this console (mirrors `profiles.role`,
/// PF-DOC-12 §3.2).
const requiredRole = 'admin';

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

/// The admin console router: sign-in plus the admin-only dashboard. The web
/// console has no self-serve registration — admin accounts are provisioned
/// server-side (PF-DOC-12 §3.2).
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: ref.watch(authRefreshProvider),
    redirect: (context, state) {
      final session = ref.read(authSessionProvider).value;
      final signedIn = session?.isSignedIn ?? false;
      final location = state.matchedLocation;
      final isAuthRoute = location == _loginPath;
      final isOpenRoute = location == _accessDeniedPath;
      if (!signedIn) return isAuthRoute ? null : _loginPath;
      if (isAuthRoute) return '/';
      if (!isOpenRoute && !session!.hasRole(requiredRole)) {
        return _accessDeniedPath;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const AdminDashboardPage()),
      GoRoute(path: _loginPath, builder: (_, _) => const SignInPage()),
      GoRoute(
        path: _accessDeniedPath,
        builder: (_, _) => const AccessDeniedPage(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('Tidak ditemukan')),
      body: Center(child: Text('Alamat ${state.uri.path} tidak dikenal.')),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
