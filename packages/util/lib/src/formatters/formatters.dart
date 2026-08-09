/// Formatting helpers for PareFood display conventions (PF-DOC-16 §3.3/§3.10).
///
/// Pure functions over primitives — no `Money` dependency so `pare_util` stays
/// free of domain knowledge (PF-DOC-10 §3.2).
library;

/// Formats a whole-rupiah [amount] as Indonesian IDR: `Rp 85.000`
/// (thousands separator, no decimals — PF-DOC-16 §3.3).
String formatIdr(BigInt amount) {
  final negative = amount.isNegative;
  final digits = amount.abs().toString();
  final buffer = StringBuffer(negative ? 'Rp -' : 'Rp ');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Formats a whole-rupiah integer amount as IDR. Convenience wrapper.
String formatIdrInt(int amount) => formatIdr(BigInt.from(amount));

/// Short relative time in Indonesian, e.g. `5 mnt lalu` (PF-DOC-16 §3.10).
String relativeTimeIndonesian(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(time);

  if (difference.inMinutes < 1) return 'baru saja';
  if (difference.inMinutes < 60) return '${difference.inMinutes} mnt lalu';
  if (difference.inHours < 24) return '${difference.inHours} jam lalu';
  if (difference.inDays < 7) return '${difference.inDays} hari lalu';
  return formatDateIndonesian(time);
}

/// Formats a [DateTime] as `dd MMM yyyy`, e.g. `06 Agu 2026`.
String formatDateIndonesian(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

/// Formats a [DateTime] as 24-hour `HH:mm`, e.g. `19:05`.
String formatTime24(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

/// Formats a [DateTime] as an ETA estimate, e.g. `±25 mnt` (PF-DOC-16 §3.3).
String formatEta(Duration duration) {
  final minutes = duration.inMinutes;
  return '±$minutes mnt';
}
