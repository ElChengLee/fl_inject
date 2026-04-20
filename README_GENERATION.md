# Mini App Generators (Screen Registry + Merged DI)

1) **Mini App Screen Registry Generator**: sinh router để map `appCode-subAppCode` → Screen entry
2) **Mini Apps Merged DI Generator**: sinh hàm `initMiniAppMergedDI()` để khởi tạo DI cho tất cả mini app/package

---

## 1) Mini App Screen Registry Generator

### Công dụng

- Tự động hóa việc **map route/screen** cho nhiều mini app trong shell app (không cần viết tay `getScreenMiniApp()`).
- Chuẩn hóa cách khai báo màn hình qua annotation `@MiniAppScreenEntry(...)`.
- Giảm sai sót khi thêm màn mới: chỉ cần annotate đúng → generator tự thu thập và sinh code.
- Tập trung quản lý điều hướng ở **Shell App**: chỉ cần 1 file anchor để sinh registry cạnh đó.

### Cơ chế hoạt động

- Quét toàn repo để tìm các class được annotate bằng:
    - `@MiniAppScreenEntry(appCode: "...", subAppCode: "...")`
- Khi gặp **file anchor** có `@MiniAppScreenInjectable()` → sinh file registry nằm cạnh anchor.

### Annotations

#### 1) Entry annotation (gắn trên screen)

```dart
@MiniAppScreenEntry(appCode: "home-app", subAppCode: "sub-home-app")
class HomeApp2Screen extends BaseMiniAppScreen {}
```

- `appCode` (**bắt buộc**): mã định danh mini app để route tới đúng entry screen.
- `subAppCode` (tùy chọn): dùng khi cùng `appCode` nhưng khác entry screen.

#### 2) Anchor marker (nơi sinh output)

```dart
@MiniAppScreenInjectable()
class MiniAppRegistryAnchor {}
```

### Output được sinh ra

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

### Công dụng

- Tự động hóa việc **khởi tạo DI cho toàn bộ mini app / package**.
- Tránh việc import và gọi DI thủ công trong shell app.
- Đảm bảo chỉ có **1 entrypoint DI** duy nhất.

### Cơ chế hoạt động

- Quét toàn repo để tìm:
    - Function / method có `@MiniAppDISetup()`
- Khi gặp **anchor** có `@MergedMiniAppDI()`:
    - Sinh file `.g.dart` chứa hàm `initMergedMiniAppDI()`

> Generator sử dụng **AST Scan (Dart Analyzer)**, không dùng build_runner.

### Annotations

#### 1) DI setup annotation

```dart
@MiniAppDISetup()
void initAuthenticateDI() {}
```

#### 2) Anchor marker

```dart
@MergedMiniAppDI()
class Injector {}
```

### Output

Anchor:
```
lib/src/di/injection.dart
```

Output:
```
lib/src/di/injection.g.dart
```

Ví dụ:

```dart
void initMiniAppMergedDI() {
  _i1.initAuthenticateDI();
}
```

---

## 3) Cách chạy file gen :

tự tạo main example và run generateInjectAnnotation()

