// mini_app_scanner_helper.dart
import 'dart:convert';
import 'dart:io';

import 'package:fl_inject/src/base/base_generate_model.dart';
import 'package:fl_inject/src/base/library_model.dart';
import 'package:path/path.dart' as p;

export 'mini_app_scanner_helper.dart';

String findRepoRoot(String start) {
  var dir = Directory(start);
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync() &&
        Directory(p.join(dir.path, 'packages')).existsSync()) {
      return dir.path;
    }
    if (dir.parent.path == dir.path) {
      throw Exception('❌ Cannot find repo root from $start');
    }
    dir = dir.parent;
  }
}

String? readPubspecName(File pubspec) {
  if (!pubspec.existsSync()) return null;
  for (final line in pubspec.readAsLinesSync()) {
    final t = line.trim();
    if (t.startsWith('name:')) {
      return t.substring(5).trim().replaceAll('"', '').replaceAll("'", '');
    }
  }
  return null;
}

String toPackageImportUri({
  required BaseGenerateModel model,
  required String? anchorPath,
}) {
  if (model.libraryRootModel?.isRoot == true) {
    return p
        .normalize(
          p.relative(model.filePath, from: anchorPath?.replaceAll('\\', '/')),
        )
        .replaceAll('\\', '/');
  }
  final optimizePath = model.filePath.replaceAll(r'\', '/');
  List<String> pathLibs = optimizePath.split("/lib/");
  return p
      .normalize('package:${model.libraryRootModel?.name}/${pathLibs.last}')
      .replaceAll(r'\', '/');
}

// Scan all dependencies from package_config.json
Future<List<LibraryModel>> scanAllPackages(String repoRoot) async {
  // Use a Set to avoid duplicating local modules and pubspec dependencies
  final Set<LibraryModel> listLibrary = {};

  // 1. Main package
  final mainPubspec = File(p.join(repoRoot, 'pubspec.yaml'));
  final mainName = readPubspecName(mainPubspec);
  if (mainName != null) {
    listLibrary.add(
      LibraryModel(path: p.normalize(repoRoot), name: mainName, isRoot: true),
    );
  }

  // 2. Load everything from package_config.json (pub.dev + git + local paths)
  final pathPackageConfig = p.join(repoRoot, '.dart_tool');
  final packageConfigFile = File(
    p.join(pathPackageConfig, 'package_config.json'),
  );
  if (packageConfigFile.existsSync()) {
    final config = json.decode(await packageConfigFile.readAsString());
    for (var pkg in config['packages']) {
      final rootUri = Uri.parse(pkg['rootUri']);
      final rootPath = p.normalize(
        p.join(pathPackageConfig, rootUri.toFilePath()),
      );

      if (!listLibrary.any((element) => element.path == rootPath)) {
        final pubspec = File(p.join(rootPath, 'pubspec.yaml'));
        final name = readPubspecName(pubspec);
        if (name != null) {
          listLibrary.add(LibraryModel(name: name, path: rootPath));
        }
      }
    }
  }

  print('📊 Total number of library modules to scan: ${listLibrary.length}');
  return listLibrary.toList();
}
