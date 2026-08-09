/// Empty and error state views for the four-state convention (FL-R07,
/// PF-DOC-11 §3.5).
library;

import 'package:flutter/material.dart';
import 'package:pare_core/pare_core.dart';

import '../tokens/tokens.dart';
import 'pf_button.dart';

/// Empty state: icon + message + optional CTA.
class PfEmptyState extends StatelessWidget {
  const PfEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PfSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: PfSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: PfSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: PfSpacing.lg),
              PfButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: PfButtonVariant.outline,
                size: PfButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state: typed [PareException] mapped to a message with an optional
/// retry action. Errors are logged upstream (Sentry), never here.
class PfErrorState extends StatelessWidget {
  const PfErrorState({
    required this.onRetry,
    this.error,
    this.title,
    super.key,
  });

  /// Retry handler; pass `null` to hide the retry button.
  final VoidCallback? onRetry;

  /// Typed error driving the message (PF-DOC-11 §3.5). Falls back to [title].
  final PareException? error;

  /// Explicit title used when [error] is absent.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = error?.message ?? title ?? 'Something went wrong.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PfSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: PfSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: PfSpacing.lg),
              PfButton(
                label: 'Coba lagi',
                onPressed: onRetry,
                variant: PfButtonVariant.outline,
                size: PfButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
