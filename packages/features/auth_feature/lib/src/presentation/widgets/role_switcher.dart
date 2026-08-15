/// Role switcher dialog (FR-AUTH-006: multi-role accounts).
///
/// Shown when a signed-in user holds more than one role. Selecting a role
/// calls `switchRole` (Edge RPC `switch_active_role`); the session re-emits
/// with the new active role, and the app router re-evaluates guards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

import '../../application/auth_providers.dart';

/// Human-readable Indonesian label for a role id.
String roleLabel(String role) {
  return switch (role) {
    'customer' => 'Pelanggan',
    'business' => 'Merchant',
    'driver' => 'Driver',
    'admin' => 'Admin',
    _ => role,
  };
}

/// Icon for a role id.
IconData roleIcon(String role) {
  return switch (role) {
    'customer' => Icons.person_outline,
    'business' => Icons.store_outlined,
    'driver' => Icons.local_shipping_outlined,
    'admin' => Icons.admin_panel_settings_outlined,
    _ => Icons.badge_outlined,
  };
}

/// A compact chip the app shell can place in the AppBar / drawer. Tapping it
/// opens the [RoleSwitcherDialog] when the user holds >1 role; otherwise it
/// just shows the active role.
class RoleSwitcherChip extends ConsumerWidget {
  const RoleSwitcherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).value;
    if (session == null || !session.isSignedIn) return const SizedBox.shrink();
    return FutureBuilder(
      future: ref.watch(userRolesProvider.future),
      builder: (context, snapshot) {
        final roles = snapshot.data ?? [session.role];
        if (roles.length <= 1) {
          return _chip(context, session.role, null);
        }
        return _chip(context, session.role, () {
          showDialog<void>(
            context: context,
            builder: (_) =>
                RoleSwitcherDialog(activeRole: session.role, roles: roles),
          );
        });
      },
    );
  }

  Widget _chip(BuildContext context, String role, VoidCallback? onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PfRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PfSpacing.sm,
          vertical: PfSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(PfRadius.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              roleIcon(role),
              size: 16,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: PfSpacing.xxs),
            Text(
              roleLabel(role),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.swap_horiz,
                size: 14,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen dialog listing the user's roles with a switch action.
class RoleSwitcherDialog extends ConsumerStatefulWidget {
  const RoleSwitcherDialog({
    required this.activeRole,
    required this.roles,
    super.key,
  });

  final String activeRole;
  final List<String> roles;

  @override
  ConsumerState<RoleSwitcherDialog> createState() => _RoleSwitcherDialogState();
}

class _RoleSwitcherDialogState extends ConsumerState<RoleSwitcherDialog> {
  bool _switching = false;

  Future<void> _switch(String role) async {
    if (role == widget.activeRole) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _switching = true);
    try {
      await ref.read(switchRoleUseCaseProvider).call(role);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Peran aktif: ${roleLabel(role)}')),
      );
    } on PareException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ganti peran'),
      content: RadioGroup<String>(
        groupValue: widget.activeRole,
        onChanged: (value) {
          if (_switching || value == null) return;
          _switch(value);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final role in widget.roles)
              RadioListTile<String>(
                value: role,
                title: Text(roleLabel(role)),
                secondary: Icon(roleIcon(role)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _switching ? null : () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
