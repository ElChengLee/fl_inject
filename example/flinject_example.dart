import 'package:fl_inject/fl_inject.dart';

void main() {
  generateInjectAnnotation(
    pathRoot: "C:\\Users\\binhnv8\\Desktop\\Project\\shellapp",
    listGen: [MiniAppScreenGenerate(), MiniAppMergedDiGenerate()],
  );
  // generateFile();
}
