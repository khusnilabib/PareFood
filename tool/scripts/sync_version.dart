import 'dart:io';

import 'package:yaml/yaml.dart';

/// `melos version` post-hook (PF-DOC-30 §3).
///
/// Enforces release lockstep: every workspace package must share the SAME
/// `version:` as the root `pubspec.yaml`. A divergent version means a package
/// would ship independently of the app — a release safety error.
void main() {
  final root = Directory.current;
  final rootPubspec = File('${root.path}/pubspec.yaml');
  if (!rootPubspec.existsSync()) {
    stderr.writeln('Run from the workspace root (no pubspec.yaml found).');
    exit(1);
  }

  final rootConfig = loadYaml(rootPubspec.readAsStringSync()) as YamlMap;
  final rootVersion = rootConfig['version']?.toString();
  final workspace = (rootConfig['workspace'] as List?)?.cast<String>() ?? <String>[];

  final found = <String, String>{};
  for (final dir in _packageDirs(root, workspace)) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    final cfg = loadYaml(pubspec.readAsStringSync()) as YamlMap;
    final name = cfg['name']?.toString();
    final version = cfg['version']?.toString();
    if (name == null || version == null) {
      continue;
    }
    found[name] = version;
  }

  final violations = <String>[
    for (final entry in found.entries)
      if (entry.value != rootVersion) '  ${entry.key}: ${entry.value}',
  ];

  if (violations.isNotEmpty || rootVersion == null) {
    stderr.writeln('Version lockstep violation (root: $rootVersion):');
    for (final violation in violations) {
      stderr.writeln(violation);
    }
    stderr.writeln('All packages must share the root version before release.');
    exit(1);
  }

  stdout.writeln('Version lockstep OK — ${found.length} packages at $rootVersion.');
}

/// Expands `packages/*`-style workspace globs into package directories.
///
/// Only single-level `/*` globs are expanded; anything else is skipped.
Iterable<Directory> _packageDirs(Directory root, List<String> workspace) sync* {
  for (final pattern in workspace) {
    if (!pattern.endsWith('/*')) {
      continue;
    }
    final parent = Directory(
      '${root.path}/${pattern.substring(0, pattern.length - 2)}',
    );
    if (!parent.existsSync()) {
      continue;
    }
    for (final entry in parent.listSync(followLinks: false)) {
      if (entry is Directory && File('${entry.path}/pubspec.yaml').existsSync()) {
        yield entry;
      }
    }
  }
}
