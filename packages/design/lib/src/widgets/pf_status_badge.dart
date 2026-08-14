/// Status pill showing colour + icon + text together (PF-DOC-16 §3.2 DS-R03).
/// Optimized to cache theme access and avoid unnecessary rebuilds.
library;

import 'package:flutter/material.dart';

import '../tokens/pf_colors.dart';
import '../tokens/tokens.dart';

/// Semantic statuses mapped to brand tokens and companion icons (NFR-030).
enum PfStatus {
  active(PfColors.tertiaryLight, Icons.circle),
  pending(PfColors.secondaryLight, Icons.schedule),
  error(PfColors.errorLight, Icons.close),
  cancelled(PfColors.onSurfaceVariantLight, Icons.block);

  const PfStatus(this.color, this.icon);

  /// Semantic colour (light-mode token).
  final Color color;

  /// Companion icon — always rendered with the colour (DS-R03).
  final IconData icon;
}

/// A compact pill conveying status with colour, icon and text together so it is
/// perceivable beyond colour alone (NFR-029/030).
/// Optimized to cache theme data to avoid repeated Theme.of() calls.
class PfStatusBadge extends StatelessWidget {
  const PfStatusBadge({
    required this.status,
    required this.label,
    this.compact = false,
    super.key,
  });

  /// Semantic status driving colour + icon.
  final PfStatus status;

  /// Localised status text.
  final String label;

  /// Smaller pill for dense rows/tables.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Cache theme access to avoid multiple Theme.of() calls
    final textTheme = Theme.of(context).textTheme;
    final textStyle = textTheme.labelMedium?.copyWith(
      color: status.color,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? PfSpacing.xs : PfSpacing.sm,
        vertical: compact ? 2 : PfSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(PfRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 12 : 14, color: status.color),
          const SizedBox(width: 4),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}
