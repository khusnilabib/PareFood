/// Loading skeleton used instead of spinners on full-page loads > 1 s
/// (PF-DOC-16 §3.6; FL-R07).
library;

import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// A pulsing placeholder block for shimmer/skeleton states.
class PfSkeleton extends StatelessWidget {
  const PfSkeleton({
    this.width = double.infinity,
    this.height = 16,
    this.radius = PfRadius.sm,
    super.key,
  });

  /// Block width.
  final double width;

  /// Block height.
  final double height;

  /// Corner radius.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: _Shimmer(baseColor: base),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.baseColor});

  final Color baseColor;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PfMotion.standard * 3,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final highlight = widget.baseColor.withValues(
          alpha: 0.35 + 0.35 * ((t * 4).abs() % 1.0),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.transparent, highlight, Colors.transparent],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
          child: child,
        );
      },
      child: const SizedBox.expand(),
    );
  }
}
