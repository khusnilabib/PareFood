/// String extensions used across PareFood packages.
library;

extension StringNormalizationX on String {
  /// Lowercases and collapses whitespace for display-agnostic comparisons.
  String get normalizedForComparison => trim().toLowerCase();

  /// Strips non-digit characters (e.g. `Rp 85.000` → `85000`).
  String get digitsOnly => replaceAll(RegExp(r'[^0-9]'), '');
}

/// Integer extensions for common rounding/clamping helpers.
extension IntX on int {
  /// Rounds up to the next multiple of [factor] (used for fare calculations).
  int ceilToMultiple(int factor) {
    if (factor <= 0) throw ArgumentError.value(factor, 'factor');
    final remainder = this % factor;
    if (remainder == 0) return this;
    return this + (factor - remainder);
  }

  /// Clamps into the inclusive [min]..[max] range.
  int clampTo(int min, int max) => this < min ? min : (this > max ? max : this);
}

/// Duration helpers for display.
extension DurationX on Duration {
  /// Whole minutes, rounded up (used for ETA display).
  int get inMinutesCeil => (inSeconds + 59) ~/ 60;
}
