import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:fl_inject/src/base/base_generate.dart';
import 'package:fl_inject/src/base/base_generate_model.dart';

// ====================== MODELS ======================
class DiSetupCall {
  final String importUri;
  final String functionName;

  DiSetupCall({
    required this.importUri,
    required this.functionName,
  });
}

class FoundDiMethod extends BaseGenerateModel {

  FoundDiMethod(super.filePath, super.className);
}

class MiniAppMergedDiGenerate extends BaseGenerate<FoundDiMethod> {

  MiniAppMergedDiGenerate();


  @override
  RecursiveAstVisitor<List<FoundDiMethod>> getEntryRecursive({required String filePath}) {
    return MiniAppDiVisitor(filePath);
  }

  @override
  RecursiveAstVisitor<String> getAnchorVisitor({required String filePath}) {
    return AnchorMergedDiVisitor(filePath);
  }

  @override
  bool writeGenerateFile(List? data, String? anchor) {
    print('Writing MiniAppMergedDiGenerate . . .');
    if (data == null) {
      print('Data is null. Writing fail');
      return false;
    }

    final calls = <DiSetupCall>[];
    for (final f in data) {
      if (f is! FoundDiMethod) {
        print('Data is not valid. Writing fail');
        return false;
      }

      calls.add(DiSetupCall(
        importUri: f.pathImportUri ?? "",
        functionName: f.className,
      ));
    }

    // Deduplicate
    final unique = <String, DiSetupCall>{};
    for (final c in calls) {
      final key = '${c.importUri}::${c.functionName}';
      unique[key] = c;
    }

    final dedupedCalls = unique.values.toList()
      ..sort((a, b) => a.importUri.compareTo(b.importUri));

   return _generateMergedDiGFile(
      target: anchor,
      calls: dedupedCalls,
    );
  }

}

// ====================== VISITORS ======================
class MiniAppDiVisitor extends RecursiveAstVisitor<List<FoundDiMethod>> {
  final String file;
  String? _currentClass;
  List<FoundDiMethod> listFoundDi = List.empty(growable: true);

  MiniAppDiVisitor(this.file);

  @override
  List<FoundDiMethod> visitClassDeclaration(ClassDeclaration node) {
    final prev = _currentClass;
    _currentClass = node.name.lexeme;
    listFoundDi.addAll(super.visitClassDeclaration(node)?.toList() ?? []);
    _currentClass = prev;
    return listFoundDi;
  }

  @override
  List<FoundDiMethod> visitFunctionDeclaration(FunctionDeclaration node) {
    for (final meta in node.metadata) {
      if (isMiniAppDiSetup(meta)) {
        listFoundDi.add(FoundDiMethod(
          file,
          node.name.lexeme,
        ));
      }
    }
    super.visitFunctionDeclaration(node);
    return listFoundDi;
  }

  @override
  List<FoundDiMethod> visitMethodDeclaration(MethodDeclaration node) {
    for (final meta in node.metadata) {
      if (isMiniAppDiSetup(meta)) {
        listFoundDi.add(FoundDiMethod(
          file,
          node.name.lexeme,
        )) ;
      }
    }
    super.visitMethodDeclaration(node);
    return listFoundDi;
  }

  @override
  List<FoundDiMethod> visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    return listFoundDi;
  }
}

class AnchorMergedDiVisitor extends RecursiveAstVisitor<String> {
  final String file;
  String? targetPath;

  AnchorMergedDiVisitor(this.file);

  @override
  String? visitClassDeclaration(ClassDeclaration node) {
    for (final meta in node.metadata) {
      if (isMergedDiMiniApps(meta)) {
        targetPath = file;
      }
    }
    super.visitClassDeclaration(node);
    return targetPath;
  }

  @override
  String? visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    return targetPath;
  }
}

// ====================== GENERATION ======================
bool _generateMergedDiGFile({
  String? target,
  required List<DiSetupCall> calls,
}) {
  final outputPath = target?.replaceFirst('.dart', '.g.dart') ?? "";

  final buf = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// ignore_for_file: unused_import, discarded_futures')
    ..writeln('');

  final imports = <String, String>{};
  var counter = 0;

  for (final call in calls) {
    imports.putIfAbsent(call.importUri, () {
      counter++;
      return '_i$counter';
    });
  }

  for (final entry in imports.entries) {
    buf.writeln("import '${entry.key}' as ${entry.value};");
  }

  buf
    ..writeln('')
    ..writeln('void initMergedMiniAppDI() {');

  for (final call in calls) {
    final alias = imports[call.importUri]!;
    buf.writeln('  $alias.${call.functionName}();');
  }

  buf.writeln('}');

  try {
    File(outputPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(buf.toString());

    print('✅ Generated merged DI: $outputPath');
    return true;
  } catch (e) {
    stdout.writeln('Write file fail');
    return false;
  }
}

// ====================== ANNOTATION HELPERS ======================
bool isMiniAppDiSetup(Annotation meta) {
  final name = meta.name;
  if (name is SimpleIdentifier) return name.name == 'MiniAppDISetup';
  if (name is PrefixedIdentifier) return name.identifier.name == 'MiniAppDISetup';
  return false;
}

bool isMergedDiMiniApps(Annotation meta) {
  final name = meta.name;
  if (name is SimpleIdentifier) return name.name == 'MergedMiniAppDI';
  if (name is PrefixedIdentifier) return name.identifier.name == 'MergedMiniAppDI';
  return false;
}