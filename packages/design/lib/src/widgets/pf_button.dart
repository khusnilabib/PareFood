/// Brand button component (PF-DOC-16 §3.7).
/// Optimized to cache theme and color scheme access.
library;

import 'package:flutter/material.dart';

import '../tokens/pf_colors.dart';
import '../tokens/tokens.dart';

/// Visual variants of [PfButton].
enum PfButtonVariant { primary, secondary, outline, text }

/// Size variants of [PfButton].
enum PfButtonSize { medium, large }

/// The shared action button used across all PareFood apps. Colours derive from
/// the active [ColorScheme] (DS-R01); labels are always localised at call site.
/// Optimized to cache color scheme access to reduce Theme.of() calls.
class PfButton extends StatelessWidget {
  const PfButton({
    required this.label,
    required this.onPressed,
    this.variant = PfButtonVariant.primary,
    this.size = PfButtonSize.large,
    this.isLoading = false,
    this.expandWidth = true,
    this.icon,
    super.key,
  });

  /// Button text (localised ARB string, DS-R05).
  final String label;

  /// Tap handler; `null` disables the button.
  final VoidCallback? onPressed;

  /// Styling variant.
  final PfButtonVariant variant;

  /// Sizing variant.
  final PfButtonSize size;

  /// Shows a loading indicator and disables the button.
  final bool isLoading;

  /// Whether the button stretches to fill its parent width.
  final bool expandWidth;

  /// Optional leading icon.
  final IconData? icon;

  /// Extracts the foreground color based on variant and color scheme.
  Color _foreground(ColorScheme scheme) => switch (variant) {
    PfButtonVariant.primary => scheme.onPrimary,
    PfButtonVariant.secondary => PfColors.secondaryLight,
    PfButtonVariant.outline => scheme.primary,
    PfButtonVariant.text => scheme.primary,
  };

  @override
  Widget build(BuildContext context) {
    // Cache theme access to avoid multiple Theme.of() calls
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final height = size == PfButtonSize.large ? 52.0 : 44.0;
    final foregroundColor = _foreground(scheme);

    final Widget child = Row(
      mainAxisSize: expandWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: PfSpacing.xs),
        ],
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          )
        else
          Flexible(
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    switch (variant) {
      case PfButtonVariant.primary:
        return FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            minimumSize: Size(expandWidth ? double.infinity : 0, height),
            padding: const EdgeInsets.symmetric(horizontal: PfSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PfRadius.md),
            ),
          ),
          child: child,
        );
      case PfButtonVariant.secondary:
        return FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: PfColors.secondaryLight.withValues(alpha: 0.14),
            foregroundColor: PfColors.secondaryLight,
            minimumSize: Size(expandWidth ? double.infinity : 0, height),
            padding: const EdgeInsets.symmetric(horizontal: PfSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PfRadius.md),
            ),
          ),
          child: child,
        );
      case PfButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.primary,
            side: BorderSide(color: scheme.outline),
            minimumSize: Size(expandWidth ? double.infinity : 0, height),
            padding: const EdgeInsets.symmetric(horizontal: PfSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PfRadius.md),
            ),
          ),
          child: child,
        );
      case PfButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            minimumSize: Size(expandWidth ? double.infinity : 0, height),
            padding: const EdgeInsets.symmetric(horizontal: PfSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PfRadius.md),
            ),
          ),
          child: child,
        );
    }
  }
}
