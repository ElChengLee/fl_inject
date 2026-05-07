import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:fl_inject/src/base/base_generate.dart';
import 'package:fl_inject/src/base/library_model.dart';
import 'package:fl_inject/src/util/mini_app_scanner_helper.dart';

import 'base/base_generate_model.dart';

void generateInjectAnnotation<T>({
  String? pathRoot,
  required List<BaseGenerate> listGen,
}) async {
  print('🚀 Starting the generation process...');

  // === Scan Only Once ===
  final repoRoot = pathRoot ?? findRepoRoot(Directory.current.path);
  final allPackage = await scanAllPackages(repoRoot);

  // ==================== Scan all file in project ====================
  print('Scanning . . .');
  // Create AnalysisContextCollection
  final collection = AnalysisContextCollection(
    includedPaths: allPackage.map((LibraryModel e) => e.path).toList(),
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  Map<BaseGenerate, String?> listAnchorPathMap = {};
  Map<BaseGenerate, List<BaseGenerateModel>> listEntryMap = {};
  for (var e in listGen) {
    listAnchorPathMap[e] = null;
    listEntryMap[e] = [];
  }

  var scanned = 0;

  // Build ScreenEntry
  for (final ctx in collection.contexts) {
    final session = ctx.currentSession;

    for (final file in ctx.contextRoot.analyzedFiles()) {
      if (!file.endsWith('.dart') ||
          file.endsWith('.g.dart') ||
          file.endsWith('.gen.dart') ||
          file.endsWith('.freezed.dart') ||
          file.endsWith('.gr.dart')) {
        continue;
      }

      scanned++;

      try {
        final parsed = session.getParsedUnit(file);
        if (parsed is! ParsedUnitResult) return null;

        for (var element in listGen) {
          // scan @Anchor
          var anchorVisitor = element.getAnchorVisitor(filePath: file);
          if (anchorVisitor == null) {
            listAnchorPathMap[element] = null;
          } else {
            var anchor = parsed.unit.accept(anchorVisitor);
            if (anchor?.isNotEmpty == true) {
              listAnchorPathMap[element] = file;
            }
          }

          // scan @Entry
          var entryVisitorList = parsed.unit
              .accept(element.getEntryRecursive(filePath: file))
              ?.toList();
          if (entryVisitorList?.isNotEmpty == true) {
            var list = listEntryMap[element] ?? [];
            list.addAll(
              entryVisitorList!.map((e) {
                var library = allPackage.firstWhere(
                  (element) => element.path == ctx.contextRoot.root.path,
                );
                e.libraryRootModel = library;
                return e;
              }),
            );
            listEntryMap[element] = list;
          }
        }
      } catch (e) {
        print('⚠️ Cannot parse file: $file');
      }
    }
  }

  print('Scanned dart files: $scanned');

  for (var element in listGen) {
    var anchor = listAnchorPathMap[element] ?? "$repoRoot/lib/gen/${element.runtimeType.toString()}.dart".replaceAll('\\', '/');
    File file = File(anchor);
    if (file.existsSync()) {
      file.deleteSync();
    }
    // Resolve import URIs for entries
    var list = listEntryMap[element]?.map((e) {
      e.pathImportUri = toPackageImportUri(anchorPath: anchor, model: e);
      return e;
    }).toList();
    if (list?.isNotEmpty == true) {
      var isWriteSuccess = element.writeGenerateFile(list, anchor);
      if (!isWriteSuccess) {
        print('⚠️ No destination folder: $anchor');
      }
    }
  }

  print('✅ Generation complete!');
}
