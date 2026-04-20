import 'library_model.dart';

abstract class BaseGenerateModel {
  // info of root library include annotation
  LibraryModel? libraryRootModel;
  // import uri  include annotation
  String? pathImportUri;
  // file path of class include annotation
  final String filePath;
  // function/class include annotation
  final String className;

  BaseGenerateModel(this.filePath, this.className);
}