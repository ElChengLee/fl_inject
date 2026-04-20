import 'package:analyzer/dart/ast/visitor.dart';

import 'base_generate_model.dart';

abstract class BaseGenerate<T extends BaseGenerateModel> {
  RecursiveAstVisitor<List<T>> getEntryRecursive({required String filePath});

  RecursiveAstVisitor<String>? getAnchorVisitor({required String filePath}) {
    return null;
  }

  bool writeGenerateFile(List<BaseGenerateModel>? data, String? anchor);
}
