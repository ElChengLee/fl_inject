import 'dart:io';
import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:fl_inject/src/base/base_generate.dart';
import 'package:fl_inject/src/base/base_generate_model.dart';
import 'package:path/path.dart' as p;

/// =============================================================
/// CONFIG
/// =============================================================

const _entryAnno = 'MiniAppScreenEntry';
const _anchorAnno = 'MiniAppScreenInjectable';

/// Output function template is kept the same as your generator.
const _generatedHeader = '''// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_import
''';

/// =============================================================
/// MODELS
/// =============================================================

class ScreenEntry {
  final String fullAppCode;
  final String importUri;
  final String className;

  ScreenEntry({
    required this.fullAppCode,
    required this.importUri,
    required this.className,
  });

  @override
  String toString() {
    return 'ScreenEntry{fullAppCode: $fullAppCode, importUri: $importUri, className: $className}';
  }
}

class EntryHit extends BaseGenerateModel {
  final String appCode;
  final String subAppCode;

  EntryHit(super.filePath, super.className,
      {required this.appCode, required this.subAppCode,});

  String get fullAppCode =>
      subAppCode.isNotEmpty ? '$appCode-$subAppCode' : appCode;

  @override
  String toString() {
    return '_EntryHit{filePath: $filePath, className: $className, appCode: $appCode, subAppCode: $subAppCode}';
  }
}

/// =============================================================
/// ANNOTATION NAME HELPERS (supports prefix)
/// =============================================================

String? _annotationSimpleName(Annotation a) {
  final name = a.name;
  if (name is SimpleIdentifier) return name.name;
  if (name is PrefixedIdentifier) return name.identifier.name;
  return null;
}

class MiniAppScreenGenerate extends BaseGenerate<EntryHit> {

  MiniAppScreenGenerate();


  @override
  RecursiveAstVisitor<List<EntryHit>> getEntryRecursive({required String filePath}) {
    return EntryVisitor(filePath: filePath);
  }

  @override
  RecursiveAstVisitor<String> getAnchorVisitor({required String filePath}) {
    return AnchorVisitor(filePath: filePath);
  }

  @override
  bool writeGenerateFile(List? data, String? anchor) {
    print('Writing MiniAppScreenEntry . . .');

    if (data == null) {
      print('Data is null. Writing fail');
      return false;
    }

    // Build ScreenEntry
    final mapScreenEntry = <String, ScreenEntry>{};

    for (final hit in data) {
      if (hit is! EntryHit) {
        print('Data is not valid. Writing fail');
        return false;
      }

      final key = hit.fullAppCode;
      if (key.isEmpty || hit.className.isEmpty) continue;

      if (mapScreenEntry.containsKey(key)) {
        final old = mapScreenEntry[key]!;
        stderr.writeln(
          '[MiniAppScreenEntry] Duplicate fullAppCode="$key"\n'
              '  - old: ${old.importUri} -> ${old.className}\n'
              '  - new: ${hit.pathImportUri} -> ${hit.className}\n'
              '  => keep old, skip new',
        );
        continue;
      }

      mapScreenEntry[key] = ScreenEntry(
        fullAppCode: key,
        importUri: hit.pathImportUri ?? "",
        className: hit.className,
      );
    }

    return _writeOutput(anchorFile: anchor!, entries: mapScreenEntry.values.toList());
  }

}

/// =============================================================
/// VISITORS
/// =============================================================

/// Finds @MiniAppScreenInjectable() anywhere in a compilation unit.
/// (You can tighten this to ClassDeclaration metadata if you want.)
class AnchorVisitor extends RecursiveAstVisitor<String> {

  final String filePath;

  String? targetPath;

  AnchorVisitor({
    required this.filePath,
  });

  @override
  String? visitAnnotation(Annotation node) {
    if (_annotationSimpleName(node) == _anchorAnno) {
      targetPath = filePath;
    }
    super.visitAnnotation(node);
    return targetPath;
  }

  @override
  String? visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    return targetPath;
  }
}

/// Collects classes annotated with @MiniAppScreenEntry(...)
/// and extracts named args: appCode, subAppCode (string literals).
class EntryVisitor extends RecursiveAstVisitor<List<EntryHit>> {
  final String filePath;
  List<EntryHit> entryHitList = List.empty(growable: true);

  EntryVisitor({
    required this.filePath,
  });

  @override
  List<EntryHit> visitClassDeclaration(ClassDeclaration node) {
    for (final meta in node.metadata) {
      if (_annotationSimpleName(meta) != _entryAnno) continue;

      final args = meta.arguments;
      final named = <String, Expression>{};

      if (args != null) {
        for (final a in args.arguments) {
          if (a is NamedExpression) {
            named[a.name.label.name] = a.expression;
          }
        }
      }

      final appCode = _stringValue(named['appCode']) ?? '';
      final subAppCode = _stringValue(named['subAppCode']) ?? '';

      if (appCode.isEmpty) continue;

      entryHitList.add(
          EntryHit(
              filePath,
              node.name.lexeme,
              appCode: appCode,
              subAppCode: subAppCode
          )
      );
    }
    super.visitClassDeclaration(node);

   return entryHitList;
  }

  @override
  List<EntryHit>? visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    return entryHitList;
  }
}

/// Gets a string literal value from an expression, if possible (parsed mode).
String? _stringValue(Expression? e) {
  if (e == null) return null;

  // Handles: "abc"
  if (e is SimpleStringLiteral) return e.value;

  // Handles: 'a' 'b' or "a" "b" (adjacent)
  if (e is AdjacentStrings) {
    final parts = e.strings;
    final buf = StringBuffer();
    for (final s in parts) {
      if (s is SimpleStringLiteral) buf.write(s.value);
      // If not literal, we can't resolve in parsed-only mode.
    }
    final v = buf.toString();
    return v.isEmpty ? null : v;
  }

  // If you need const evaluation (e.g. appCode: MyConsts.x),
  // you must upgrade to getResolvedUnit + constant evaluation.
  return null;
}

/// =============================================================
/// GENERATION
/// =============================================================

bool _writeOutput({
  required String anchorFile,
  required List<ScreenEntry> entries,
}) {
  final anchorDir = p.dirname(anchorFile);
  final anchorBase = p.basename(anchorFile);
  final outputPath = p.join(
    anchorDir,
    anchorBase.replaceFirst('.dart', '.mini_screen.g.dart'),
  );

  final sorted = entries.toList()
    ..sort((a, b) => a.fullAppCode.compareTo(b.fullAppCode));

  final imports = <String>{};
  final cases = <String>[];

  for (final e in sorted) {
    imports.add("import '${e.importUri}';");

    cases.add('''
    case "${e.fullAppCode}":
      return ${e.className}();
''');
  }

  final output = StringBuffer()
    ..writeln(_generatedHeader)
    ..writeln("import 'package:flutter/widgets.dart';")
    ..writeln("import 'package:mini_app_interface/mini_app_interface.dart';")
    ..writeln(imports.join('\n'))
    ..writeln('')
    ..writeln('Widget getScreenMiniAppEntries({')
    ..writeln('  required String appCode,')
    ..writeln('  String? subAppCode,')
    ..writeln('}) {')
    ..writeln('  final fullAppCode = (() {')
    ..writeln('    final buf = StringBuffer()..write(appCode);')
    ..writeln('    if (subAppCode?.isNotEmpty == true) {')
    ..writeln("      buf..write('-')..write(subAppCode);")
    ..writeln('    }')
    ..writeln('    return buf.toString();')
    ..writeln('  })();')
    ..writeln('')
    ..writeln('  switch (fullAppCode) {')
    ..writeln(cases.join('\n'))
    ..writeln('    default:')
    ..writeln('      return const SizedBox.shrink();')
    ..writeln('  }')
    ..writeln('}');

  try {
    File(outputPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(output.toString());

    stdout.writeln('✅ Generated: $outputPath');
    return true;
  } catch (e) {
    stdout.writeln('Write file fail');
    return false;
  }
}
