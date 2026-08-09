import 'dart:io';

import 'package:yaml/yaml.dart';

/// Package-boundary enforcement (MO-R02, PF-DOC-10 §3.2).
///
/// Runs in CI (`melos run deps-check`) and fails when a package crosses a
/// boundary:
///
///   MO-R02a  `dio` and `supabase_flutter` are allowed ONLY in `pare_data`.
///   MO-R02b  `pare_core` must not import `package:flutter/*` (web-safe, pure).
///   MO-R02c  `pare_util` must not depend on `pare_core`.
///   MO-R02d  a feature package must not depend on another feature package.
///   MO-R02e  an app must not depend on another app.
void main() {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run from the workspace root (no pubspec.yaml found).');
    exit(1);
  }

  final violations = <String>[];

  for (final base in const <String>['packages', 'apps']) {
    final dir = Directory('${root.path}/$base');
    if (!dir.existsSync()) {
      continue;
    }
    for (final entry in dir.listSync(followLinks: false)) {
      if (entry is! Directory) {
        continue;
      }
      final pubspec = File('${entry.path}/pubspec.yaml');
      if (!pubspec.existsSync()) {
        continue;
      }
      final relative = entry.path.substring(root.path.length + 1);
      final cfg = loadYaml(pubspec.readAsStringSync()) as YamlMap;
      final name = cfg['name']?.toString() ?? '';
      final dependencies = _dependencyNames(cfg);

      if (name != 'pare_data') {
        for (final banned in const <String>['dio', 'supabase_flutter']) {
          if (dependencies.contains(banned)) {
            violations.add('$name ($relative) depends on $banned (MO-R02a).');
          }
        }
      }

      if (name == 'pare_util' && dependencies.contains('pare_core')) {
        violations.add('pare_util depends on pare_core (MO-R02c).');
      }

      if (relative.startsWith('packages${Platform.pathSeparator}features')) {
        final featureDeps = dependencies
            .where((dep) => dep.startsWith('pare_'))
            .where((dep) => !const <String>[
                  'pare_core',
                  'pare_util',
                  'pare_data',
                  'pare_design',
                ].contains(dep));
        for (final dep in featureDeps) {
          violations.add('$name ($relative) depends on feature package $dep (MO-R02d).');
        }
      }

      if (relative.startsWith('apps${Platform.pathSeparator}')) {
        for (final dep in dependencies) {
          if (dep.startsWith('app_') && dep != name) {
            violations.add('$name ($relative) depends on another app $dep (MO-R02e).');
          }
        }
      }

      final lib = Directory('${entry.path}/lib');
      if (name == 'pare_core' && lib.existsSync()) {
        for (final file in _dartFiles(lib)) {
          for (final line in file.readAsLinesSync()) {
            if (line.contains("import 'package:flutter/") ||
                line.contains("export 'package:flutter/")) {
              violations.add('pare_core imports Flutter in ${_rel(root, file)} (MO-R02b).');
              break;
            }
          }
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Package boundary violations:');
    for (final violation in violations) {
      stderr.writeln('  - $violation');
    }
    exit(1);
  }

  stdout.writeln('Dependency boundaries OK.');
}

Set<String> _dependencyNames(YamlMap pubspec) {
  final names = <String>{};
  for (final key in const <String>['dependencies', 'dev_dependencies']) {
    final map = pubspec[key];
    if (map is YamlMap) {
      names.addAll(map.keys.map((k) => k.toString()));
    }
  }
  return names;
}

Iterable<File> _dartFiles(Directory dir) sync* {
  for (final entry in dir.listSync(recursive: true, followLinks: false)) {
    if (entry is File && entry.path.endsWith('.dart')) {
      yield entry;
    }
  }
}

String _rel(Directory root, File file) => file.path.substring(root.path.length + 1);
