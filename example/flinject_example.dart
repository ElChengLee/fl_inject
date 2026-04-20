import 'package:fl_inject/fl_inject.dart';
import 'package:fl_inject/src/generators/mini_app_merged_di_gen.dart';
import 'package:fl_inject/src/generators/mini_app_screen_gen.dart';

void main() {
  generateInjectAnnotation(
    pathRoot: "C:\\Users\\binhnv8\\Desktop\\Project\\shellapp",
    listGen: [MiniAppScreenGenerate(), MiniAppMergedDiGenerate()],
  );
  // generateFile();
}
