import 'package:fl_inject/fl_inject.dart';

void main() {
  generateInjectAnnotation(
    listGen: [MiniAppScreenGenerate(), MiniAppMergedDiGenerate()],
  );
  // generateFile();
}
