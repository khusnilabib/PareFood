/// S2 multi-role tests: AuthSession roles, canSwitchRole, value equality,
/// and the RoleSwitcherChip/Dialog widget (FR-AUTH-006).
library;

import 'package:auth_feature/auth_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession multi-role (FR-AUTH-006)', () {
    test('defaults roles to [role] when not specified', () {
      final s = AuthSession(userId: 'u1', email: 'a@b.c', role: 'customer');
      expect(s.roles, ['customer']);
      expect(s.canSwitchRole, isFalse);
    });

    test('canSwitchRole is true when more than one role is held', () {
      final s = AuthSession(
        userId: 'u1',
        email: 'a@b.c',
        role: 'customer',
        roles: ['customer', 'driver'],
      );
      expect(s.canSwitchRole, isTrue);
      expect(s.hasRole('driver'), isFalse); // active is customer
      expect(s.hasRole('customer'), isTrue);
    });

    test('copyWith preserves identity and updates role/roles', () {
      final s = AuthSession(
        userId: 'u1',
        email: 'a@b.c',
        role: 'customer',
        roles: ['customer', 'driver'],
      );
      final switched = s.copyWith(role: 'driver');
      expect(switched.userId, 'u1');
      expect(switched.role, 'driver');
      expect(switched.roles, ['customer', 'driver']);
      expect(switched.hasRole('driver'), isTrue);
    });

    test('equality is order-insensitive for roles', () {
      final a = AuthSession(
        userId: 'u1',
        email: 'a@b.c',
        role: 'customer',
        roles: ['customer', 'driver'],
      );
      final b = AuthSession(
        userId: 'u1',
        email: 'a@b.c',
        role: 'customer',
        roles: ['driver', 'customer'],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when roles differ', () {
      final a = AuthSession(
        userId: 'u1',
        email: 'a@b.c',
        role: 'customer',
        roles: ['customer', 'driver'],
      );
      final b = AuthSession(
        userId: 'u1',
        email: 'a@b.c',
        role: 'customer',
        roles: ['customer'],
      );
      expect(a == b, isFalse);
    });
  });

  group('roleLabel / roleIcon', () {
    test('roleLabel maps all known roles to Indonesian', () {
      expect(roleLabel('customer'), 'Pelanggan');
      expect(roleLabel('business'), 'Merchant');
      expect(roleLabel('driver'), 'Driver');
      expect(roleLabel('admin'), 'Admin');
      expect(roleLabel('unknown'), 'unknown');
    });

    test('roleIcon returns a sensible icon per role', () {
      for (final r in ['customer', 'business', 'driver', 'admin', 'x']) {
        expect(roleIcon(r), isA<IconData>());
      }
    });
  });

  group('RoleSwitcherChip', () {
    testWidgets('hidden when signed out', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith((ref) => const Stream.empty()),
            authRepositoryProvider.overrideWithValue(_NoRoleRepo()),
          ],
          child: const MaterialApp(home: Scaffold(body: RoleSwitcherChip())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RoleSwitcherChip), findsOneWidget);
      expect(find.text('Pelanggan'), findsNothing);
    });

    testWidgets('shows active role label for single-role user', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(
                const AuthSession(
                  userId: 'u1',
                  email: 'a@b.c',
                  role: 'customer',
                ),
              ),
            ),
            authRepositoryProvider.overrideWithValue(_SingleRoleRepo()),
          ],
          child: const MaterialApp(home: Scaffold(body: RoleSwitcherChip())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pelanggan'), findsOneWidget);
      // No swap icon for single-role.
      expect(find.byIcon(Icons.swap_horiz), findsNothing);
    });

    testWidgets('shows swap icon for multi-role user', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(
                const AuthSession(
                  userId: 'u1',
                  email: 'a@b.c',
                  role: 'customer',
                  roles: ['customer', 'driver'],
                ),
              ),
            ),
            authRepositoryProvider.overrideWithValue(_MultiRoleRepo()),
          ],
          child: const MaterialApp(home: Scaffold(body: RoleSwitcherChip())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pelanggan'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    });
  });
}

class _NoRoleRepo implements AuthRepository {
  @override
  Stream<AuthSession?> watchSession() => const Stream.empty();
  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<AuthOutcome> signUpWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<void> sendPhoneOtp(String phone) => throw UnimplementedError();
  @override
  Future<AuthSession> verifyPhoneOtp({
    required String phone,
    required String token,
  }) => throw UnimplementedError();
  @override
  Future<void> requestPasswordReset(String email) => throw UnimplementedError();
  @override
  Future<List<String>> fetchRoles() async => [];
  @override
  Future<void> switchRole(String role) async {}
  @override
  Future<void> signOut() async {}
}

class _SingleRoleRepo extends _NoRoleRepo {
  @override
  Future<List<String>> fetchRoles() async => ['customer'];
}

class _MultiRoleRepo extends _NoRoleRepo {
  @override
  Future<List<String>> fetchRoles() async => ['customer', 'driver'];
  @override
  Future<void> switchRole(String role) async {}
}
