import 'package:meta/meta_meta.dart' show Target, TargetKind;

@Target({TargetKind.function, TargetKind.method})
class MiniAppDISetup {
  /// default constructor 
  const MiniAppDISetup();
}

@Target({TargetKind.classType, TargetKind.function})
class MergedMiniAppDI {
  const MergedMiniAppDI();
}

@Target({TargetKind.classType})
class MiniAppScreenEntry {
  final String appCode;
  final String? subAppCode;

  const MiniAppScreenEntry({required this.appCode, this.subAppCode});
}

@Target({TargetKind.classType, TargetKind.function})
class MiniAppScreenInjectable {
  const MiniAppScreenInjectable();
}
