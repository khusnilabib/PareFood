/// Profile header row with avatar and contact summary (PF-DOC-16 §3.3).
library;

import 'package:flutter/material.dart';
import 'package:pare_design/pare_design.dart';

import '../../domain/user_profile.dart';

/// Header for [ProfilePage].
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = profile.avatarUrl;
    return Padding(
      padding: const EdgeInsets.all(PfSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
            child: Text(profile.name.characters.first.toUpperCase()),
          ),
          const SizedBox(width: PfSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (profile.email != null) ...[
                  const SizedBox(height: PfSpacing.xxs),
                  Text(
                    profile.email!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
