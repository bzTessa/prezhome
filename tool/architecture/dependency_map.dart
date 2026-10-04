import 'dart:io';

void main(List<String> args) {
  final options = _Options.fromArgs(args);
  final repositoryRoot = Directory.current.path;
  final libDirectory = Directory('$repositoryRoot/lib');
  final outputFile = File(
    '$repositoryRoot/docs/architecture/dependency-map.md',
  );

  if (!libDirectory.existsSync()) {
    stderr.writeln('No existe el directorio lib/.');
    exitCode = 1;
    return;
  }

  final graph = _DependencyGraph.build(libDirectory.path);
  final markdown = graph.toMarkdown();

  if (options.checkOnly) {
    if (!outputFile.existsSync()) {
      stderr.writeln(
        'Falta ${outputFile.path}. Ejecuta: dart run tool/architecture/dependency_map.dart',
      );
      exitCode = 1;
      return;
    }
    final current = outputFile.readAsStringSync();
    if (current != markdown) {
      stderr.writeln(
        'El mapa de dependencias está desactualizado. Regenera con: dart run tool/architecture/dependency_map.dart',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('dependency-map.md está actualizado.');
    return;
  }

  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(markdown);
  stdout.writeln('Mapa generado en: ${outputFile.path}');
}

class _Options {
  const _Options({required this.checkOnly});

  final bool checkOnly;

  factory _Options.fromArgs(List<String> args) {
    return _Options(checkOnly: args.contains('--check'));
  }
}

class _DependencyGraph {
  _DependencyGraph({
    required this.moduleFileCounts,
    required this.moduleDependencies,
    required this.crossModuleImportCounts,
  });

  final Map<String, int> moduleFileCounts;
  final Map<String, Set<String>> moduleDependencies;
  final Map<_ModulePair, int> crossModuleImportCounts;

  factory _DependencyGraph.build(String libPath) {
    final fileCounts = <String, int>{};
    final dependencies = <String, Set<String>>{};
    final crossImports = <_ModulePair, int>{};
    final libAbsolute = Directory(libPath).absolute.path;

    final files =
        Directory(libAbsolute)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final relative = _relativeToLib(libAbsolute, file.path);
      final sourceModule = _moduleFromRelativePath(relative);
      fileCounts.update(sourceModule, (value) => value + 1, ifAbsent: () => 1);
      dependencies.putIfAbsent(sourceModule, () => <String>{});

      for (final importPath in _readImportPaths(file)) {
        final targetRelative = _resolveToLibRelative(
          sourceRelativePath: relative,
          importPath: importPath,
        );
        if (targetRelative == null) {
          continue;
        }
        final targetModule = _moduleFromRelativePath(targetRelative);
        dependencies[sourceModule]!.add(targetModule);
        if (sourceModule != targetModule) {
          final key = _ModulePair(sourceModule, targetModule);
          crossImports.update(key, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }

    for (final module in fileCounts.keys) {
      dependencies.putIfAbsent(module, () => <String>{});
    }

    return _DependencyGraph(
      moduleFileCounts: fileCounts,
      moduleDependencies: dependencies,
      crossModuleImportCounts: crossImports,
    );
  }

  String toMarkdown() {
    final modules = moduleFileCounts.keys.toList()..sort();
    final buffer = StringBuffer()
      ..writeln('# Mapa de dependencias de módulos')
      ..writeln()
      ..writeln(
        'Archivo generado por `dart run tool/architecture/dependency_map.dart`.',
      )
      ..writeln()
      ..writeln('## Resumen de módulos')
      ..writeln()
      ..writeln('| Módulo | Ficheros Dart |')
      ..writeln('| --- | ---: |');

    for (final module in modules) {
      buffer.writeln('| `$module` | ${moduleFileCounts[module]} |');
    }

    buffer
      ..writeln()
      ..writeln('## Dependencias entre módulos')
      ..writeln();

    for (final module in modules) {
      final targets = (moduleDependencies[module] ?? <String>{}).toList()
        ..sort();
      final printable = targets.isEmpty
          ? '(sin dependencias internas)'
          : targets.map((target) => '`$target`').join(', ');
      buffer.writeln('- `$module` -> $printable');
    }

    buffer
      ..writeln()
      ..writeln('## Importaciones cruzadas (conteo por módulo origen/destino)')
      ..writeln();

    final sortedCrossImports = crossModuleImportCounts.entries.toList()
      ..sort((a, b) {
        final countDiff = b.value.compareTo(a.value);
        if (countDiff != 0) {
          return countDiff;
        }
        final sourceDiff = a.key.source.compareTo(b.key.source);
        if (sourceDiff != 0) {
          return sourceDiff;
        }
        return a.key.target.compareTo(b.key.target);
      });

    if (sortedCrossImports.isEmpty) {
      buffer.writeln('- No hay importaciones cruzadas.');
    } else {
      for (final entry in sortedCrossImports) {
        buffer.writeln(
          '- `${entry.key.source}` -> `${entry.key.target}`: ${entry.value}',
        );
      }
    }

    final cycles = _findCycles(modules, moduleDependencies);
    buffer
      ..writeln()
      ..writeln('## Ciclos detectados')
      ..writeln();
    if (cycles.isEmpty) {
      buffer.writeln('- No se han detectado ciclos entre módulos.');
    } else {
      for (final cycle in cycles) {
        buffer.writeln('- ${cycle.map((item) => '`$item`').join(' -> ')}');
      }
    }

    return buffer.toString();
  }
}

class _ModulePair {
  const _ModulePair(this.source, this.target);

  final String source;
  final String target;

  @override
  bool operator ==(Object other) {
    return other is _ModulePair &&
        other.source == source &&
        other.target == target;
  }

  @override
  int get hashCode => Object.hash(source, target);
}

List<String> _readImportPaths(File file) {
  final regex = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');
  final imports = <String>[];
  for (final line in file.readAsLinesSync()) {
    final match = regex.firstMatch(line);
    if (match != null) {
      imports.add(match.group(1)!);
    }
  }
  return imports;
}

String _relativeToLib(String libAbsolutePath, String filePath) {
  var normalizedLib = libAbsolutePath.replaceAll('\\', '/');
  if (!normalizedLib.endsWith('/')) {
    normalizedLib = '$normalizedLib/';
  }
  final normalizedFile = filePath.replaceAll('\\', '/');
  return normalizedFile.substring(normalizedLib.length);
}

String _moduleFromRelativePath(String relativePath) {
  final normalized = relativePath.replaceAll('\\', '/');
  if (!normalized.contains('/')) {
    return 'screens';
  }
  return normalized.split('/').first;
}

String? _resolveToLibRelative({
  required String sourceRelativePath,
  required String importPath,
}) {
  if (importPath.startsWith('dart:')) {
    return null;
  }

  if (importPath.startsWith('package:prezhome/')) {
    return importPath.replaceFirst('package:prezhome/', '');
  }

  if (importPath.startsWith('package:')) {
    return null;
  }

  if (importPath.startsWith('/')) {
    return null;
  }

  final sourceSegments = sourceRelativePath.split('/')..removeLast();
  final importSegments = importPath.split('/');
  final resolved = <String>[...sourceSegments];

  for (final segment in importSegments) {
    if (segment.isEmpty || segment == '.') {
      continue;
    }
    if (segment == '..') {
      if (resolved.isEmpty) {
        return null;
      }
      resolved.removeLast();
      continue;
    }
    resolved.add(segment);
  }

  if (resolved.isEmpty) {
    return null;
  }
  final normalized = resolved.join('/');
  return normalized.endsWith('.dart') ? normalized : null;
}

List<List<String>> _findCycles(
  List<String> modules,
  Map<String, Set<String>> dependencies,
) {
  final moduleSet = modules.toSet();
  final visited = <String>{};
  final stack = <String>[];
  final onStack = <String>{};
  final canonicalCycles = <String>{};

  void dfs(String module) {
    visited.add(module);
    stack.add(module);
    onStack.add(module);

    final targets = (dependencies[module] ?? <String>{}).toList()..sort();
    for (final target in targets) {
      if (!moduleSet.contains(target)) {
        continue;
      }
      if (!visited.contains(target)) {
        dfs(target);
      } else if (onStack.contains(target)) {
        final startIndex = stack.indexOf(target);
        if (startIndex >= 0) {
          final cycle = [...stack.sublist(startIndex), target];
          final canonical = _canonicalCycle(cycle);
          canonicalCycles.add(canonical.join('->'));
        }
      }
    }

    stack.removeLast();
    onStack.remove(module);
  }

  for (final module in modules) {
    if (!visited.contains(module)) {
      dfs(module);
    }
  }

  final cycles = canonicalCycles.map((cycle) => cycle.split('->')).toList()
    ..sort((a, b) => a.join(',').compareTo(b.join(',')));
  return cycles;
}

List<String> _canonicalCycle(List<String> cycle) {
  final ring = cycle.take(cycle.length - 1).toList();
  if (ring.isEmpty) {
    return cycle;
  }
  var best = <String>[];

  for (var i = 0; i < ring.length; i++) {
    final rotated = [...ring.sublist(i), ...ring.sublist(0, i), ring[i]];
    if (best.isEmpty || _isLexicographicallySmaller(rotated, best)) {
      best = rotated;
    }
  }
  return best;
}

bool _isLexicographicallySmaller(List<String> left, List<String> right) {
  for (var i = 0; i < left.length && i < right.length; i++) {
    final comparison = left[i].compareTo(right[i]);
    if (comparison < 0) {
      return true;
    }
    if (comparison > 0) {
      return false;
    }
  }
  return left.length < right.length;
}
