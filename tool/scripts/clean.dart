import 'dart:io';

import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart';

/// `melos clean` pre-hook (PF-DOC-30 §2).
///
/// Fails fast when a package directory (a folder containing a `pubspec.yaml`)
/// under `packages/` or `apps/` is NOT covered by the root `workspace:` globs.
/// A package excluded from the workspace is invisible to melos (exec, version,
/// clean) — usually a mistake that silently breaks the monorepo.
void main() {
  final root = Directory.current;
  final rootPubspec = File('${root.path}/pubspec.yaml');
  if (!rootPubspec.existsSync()) {
    stderr.writeln('Run from the workspace root (no pubspec.yaml found).');
    exit(1);
  }

  final config = loadYaml(rootPubspec.readAsStringSync()) as YamlMap;
  final workspace = (config['workspace'] as List?)?.cast<String>() ?? <String>[];
  final globs = workspace.map(Glob.new).toList();

  final orphans = <String>[];
  for (final base in const <String>['packages', 'apps']) {
    final dir = Directory('${root.path}/$base');
    if (!dir.existsSync()) {
      continue;
    }
    for (final entry in dir.listSync(followLinks: false)) {
      if (entry is! Directory) {
        continue;
      }
      if (!File('${entry.path}/pubspec.yaml').existsSync()) {
        continue;
      }
      final relative = entry.path.substring(root.path.length + 1);
      final covered = globs.any((glob) => glob.matches(relative));
      if (!covered) {
        orphans.add(relative);
      }
    }
  }

  if (orphans.isNotEmpty) {
    stderr.writeln('Package(s) not covered by the root workspace globs:');
    for (final orphan in orphans) {
      stderr.writeln('  - $orphan');
    }
    stderr.writeln('Add the matching glob to `workspace:` in pubspec.yaml.');
    exit(1);
  }

  stdout.writeln('Workspace OK — every package is covered by the root globs.');
}
