import 'dart:io';

/// `melos bootstrap:check` helper (FL-R06).
///
/// After `melos run codegen` regenerates Freezed / json_serializable output,
/// the working tree must be clean: generated files are committed, and any diff
/// means generation is stale or missing.
void main() {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run from the workspace root (no pubspec.yaml found).');
    exit(1);
  }

  final result = Process.runSync('git', <String>['status', '--porcelain']);
  if (result.exitCode != 0) {
    stderr.writeln('git status failed: ${result.stderr}');
    exit(result.exitCode);
  }

  final lines = (result.stdout as String)
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .toList();

  if (lines.isEmpty) {
    stdout.writeln('Working tree clean — generated code is up to date.');
    return;
  }

  stderr.writeln('Working tree is NOT clean after codegen:');
  for (final line in lines) {
    stderr.writeln('  $line');
  }
  stderr.writeln('Commit the generated output or re-run `melos run codegen`.');
  exit(1);
}
