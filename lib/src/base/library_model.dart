class LibraryModel {
  final String name;
  final String path;
  final bool isRoot;

  LibraryModel({required this.name,required  this.path, this.isRoot = false});

  @override
  String toString() {
    return 'LibraryModel{name: $name, path: $path, isRoot: $isRoot}';
  }
}