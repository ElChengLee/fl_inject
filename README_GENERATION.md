# Mini App Generators (Screen Registry + Merged DI)

1) **Mini App Screen Registry Generator**: Generates a router mapping from `appCode-subAppCode` → Screen entry.
2) **Mini Apps Merged DI Generator**: Generates the `initMiniAppMergedDI()` function to initialize DI for all mini apps/packages.

---

## 1) Mini App Screen Registry Generator

### Purpose

- Automates **route/screen mapping** for multiple mini apps within a shell app (no need to manually write `getScreenMiniApp()`).
- Standardizes screen declarations using the `@MiniAppScreenEntry(...)` annotation.
- Reduces errors when adding new screens: just annotate correctly → the generator automatically collects and generates the code.
- Centralizes navigation management in the **Shell App**: requires only 1 anchor file to generate the registry alongside it.

### How it works

- Scans the entire repository to find classes annotated with:
    - `@MiniAppScreenEntry(appCode: "...", subAppCode: "...")`
- When it finds an **anchor file** containing `@MiniAppScreenInjectable()`, it generates the registry file next to the anchor.

### Annotations

#### 1) Entry Annotation (Attached to the screen)

```dart
@MiniAppScreenEntry(appCode: "home-app", subAppCode: "sub-home-app")
class HomeApp2Screen extends BaseMiniAppScreen {}
```

- `appCode` (**required**): The unique identifier for the mini app to route to the correct entry screen.
- `subAppCode` (optional): Used when multiple entry screens share the same `appCode`.

#### 2) Anchor Marker (Output destination)

```dart
@MiniAppScreenInjectable()
class MiniAppRegistryAnchor {}
```

### Generated Output

Anchor:
```
lib/shell_app_di_screen.dart
```

Output:
```
lib/shell_app_di_screen.mini_screen.g.dart
```

---

## 2) Mini Apps Merged DI Generator

### Purpose

- Automates **DI initialization for the entire mini app / package ecosystem**.
- Avoids manual importing and DI calling in the shell app.
- Ensures there is only **1 single DI entrypoint**.

### How it works

- Scans the entire repository to find:
    - Functions / methods annotated with `@MiniAppDISetup()`
- When it finds an **anchor** containing `@MergedMiniAppDI()`:
    - Generates a `.g.dart` file containing the `initMergedMiniAppDI()` function.

> The generator uses **AST Scanning (Dart Analyzer)**, avoiding the heavy `build_runner`.

### Annotations

#### 1) DI Setup Annotation

```dart
@MiniAppDISetup()
void initAuthenticateDI() {}
```

#### 2) Anchor Marker

```dart
@MergedMiniAppDI()
class Injector {}
```

### Generated Output

Anchor:
```
lib/src/di/injection.dart
```

Output:
```
lib/src/di/injection.g.dart
```

Example output content:

```dart
void initMiniAppMergedDI() {
  _i1.initAuthenticateDI();
}
```

---

## 3) How to run the generator

Create a `main` example script and run `generateInjectAnnotation()`:

```dart
import 'package:fl_inject/fl_inject.dart';

void main() {
  generateInjectAnnotation(
    listGen: [MiniAppScreenGenerate(), MiniAppMergedDiGenerate()],
  );
}
```
*(Tip: If you use `melos`, add this script to your `melos.yaml` hooks to run automatically!)*
