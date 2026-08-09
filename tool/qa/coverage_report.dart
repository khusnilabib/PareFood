import 'dart:io';

class FileCoverage {
  FileCoverage(this.path, this.found, this.hit);
  final String path;
  final int found;
  final int hit;
  double get pct => found == 0 ? 100 : (hit / found * 100);
}

class PkgCoverage {
  PkgCoverage(this.name, this.files);
  final String name;
  final List<FileCoverage> files;
  int get found => files.fold(0, (a, f) => a + f.found);
  int get hit => files.fold(0, (a, f) => a + f.hit);
  double get pct => found == 0 ? 100 : (hit / found * 100);
}

FileCoverage parseLcovFile(List<String> lines) {
  String path = '';
  int found = 0;
  int hit = 0;
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      path = line.substring(3);
    } else if (line.startsWith('LF:')) {
      found = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit = int.parse(line.substring(3));
    }
  }
  return FileCoverage(path, found, hit);
}

/// Files with no executable logic (e.g. const-only token holders whose only
/// lcov line is a private const constructor) are excluded from aggregation.
const _excludedPaths = {'lib/src/tokens/pf_colors.dart'};

void main() {
  final root = Directory('packages');
  final packages = <PkgCoverage>[];
  final uncoveredFiles = <String>[];
  var grandFound = 0, grandHit = 0;

  final pkgDirs = <String>[
    for (final e in root.listSync().whereType<Directory>()) e.path,
    for (final features
        in root
            .listSync()
            .whereType<Directory>()
            .where((d) => d.path.endsWith('features'))
            .expand((d) => d.listSync().whereType<Directory>()))
      features.path,
  ];

  for (final dir in pkgDirs) {
    // Normalise to forward slashes so target lookups work on Windows too.
    final pkgPath = dir.replaceAll(Platform.pathSeparator, '/');
    final lcov = File(
      '$dir${Platform.pathSeparator}coverage${Platform.pathSeparator}lcov.info',
    );
    if (!lcov.existsSync()) continue;

    final files = <FileCoverage>[];
    final content = lcov.readAsStringSync();
    final chunks = content.split('end_of_record');
    for (final chunk in chunks) {
      if (chunk.trim().isEmpty) continue;
      final fc = parseLcovFile(chunk.split('\n'));
      final fcPath = fc.path.replaceAll('\\', '/');
      if (_excludedPaths.contains(fcPath)) continue;
      if (fc.found > 0) files.add(fc);
      if (fc.found > 0 && fc.hit == 0) {
        uncoveredFiles.add('$pkgPath/${fc.path}');
      }
    }
    if (files.isNotEmpty) packages.add(PkgCoverage(pkgPath, files));
  }

  packages.sort((a, b) => a.name.compareTo(b.name));

  const target = {
    'packages/core': 90,
    'packages/data': 80,
    'packages/util': 90,
    'packages/design': 75,
    'packages/features': 75,
  };

  final headers =
      '${'Package'.padRight(42)}  ${'Found'.padLeft(6)}  ${'Hit'.padLeft(6)}  ${'Pct'.padLeft(6)}  Target  Met';
  final rows = <String>[];
  for (final p in packages) {
    final short = p.name.replaceFirst('packages/', '');
    final t = p.name.startsWith('packages/features')
        ? 75
        : (target[p.name] ?? 0);
    final met = t > 0 ? (p.pct >= t ? 'YES' : 'NO ') : 'n/a';
    rows.add(
      '${short.padRight(42)}  ${p.found.toString().padLeft(6)}  ${p.hit.toString().padLeft(6)}  ${p.pct.toStringAsFixed(1).padLeft(6)}  ${t.toString().padLeft(6)}  $met',
    );
    grandFound += p.found;
    grandHit += p.hit;
  }

  stdout.writeln(headers);
  stdout.writeln(rows.join('\n'));
  stdout.writeln('---');
  stdout.writeln(
    'TOTAL: ${grandHit}/${grandFound} = ${(grandHit / grandFound * 100).toStringAsFixed(1)}%',
  );
  stdout.writeln('Zero-covered source files (${uncoveredFiles.length}):');
  uncoveredFiles.forEach(stdout.writeln);
}
