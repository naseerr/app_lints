# app_lints

A collection of custom lint rules for Flutter projects that enforce consistent usage of `flutter_screenutil`, color constants, text styles, localization, and safe GetX patterns.

Rules are enforced as **errors** — they show up inline in your IDE and fail `dart run custom_lint`.

---

## Requirements

- Dart SDK `>=3.0.0`
- Flutter project with [`flutter_screenutil`](https://pub.dev/packages/flutter_screenutil)
- [`custom_lint`](https://pub.dev/packages/custom_lint) `^0.8.1`

---

## Installation

**1. Add to `pubspec.yaml`:**

```yaml
dev_dependencies:
  custom_lint: ^0.8.1
  app_lints:
    git:
      url: https://github.com/naseerr/app_lints.git
      ref: main
```

**2. Enable the plugin in `analysis_options.yaml`:**

```yaml
analyzer:
  plugins:
    - custom_lint
```

**3. Get dependencies:**

```bash
flutter pub get
```

**4. Restart the Dart Analysis Server** in your IDE (VS Code: `Cmd+Shift+P` → "Restart Analysis Server"). The rules will appear as errors inline.

---

## Running from the command line

```bash
dart run custom_lint
```

---

## Rules

### `prefer_screenutil`

Flags any raw numeric literal in a sizing context that doesn't use a `flutter_screenutil` extension.

**Severity:** ERROR

**Supported extensions:** `.w` (width), `.h` (height), `.sp` (font size), `.r` (radius), `.sw` (screen width), `.sh` (screen height)

**Bad:**
```dart
SizedBox(width: 100, height: 50)
EdgeInsets.all(16)
EdgeInsets.symmetric(horizontal: 24, vertical: 12)
Text('Hello', style: TextStyle(fontSize: 14))
Icon(Icons.add, size: 24)
BorderRadius.circular(8)
```

**Good:**
```dart
SizedBox(width: 100.w, height: 50.h)
EdgeInsets.all(16.r)
EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h)
Text('Hello', style: TextStyle(fontSize: 14.sp))
Icon(Icons.add, size: 24.r)
BorderRadius.circular(8.r)
```

**Excluded values:** `0`, `1`, `-1`, `double.infinity` — these have no screen-relative meaning and are always allowed.

**Excluded contexts:** `designSize: Size(390, 844)` inside `ScreenUtilInit` — this is the reference canvas, not a widget size.

#### Covered named parameters

`width`, `height`, `size`, `extent`, `minWidth`, `maxWidth`, `minHeight`, `maxHeight`, `spacing`, `runSpacing`, `gap`, `fontSize`, `letterSpacing`, `wordSpacing`, `lineHeight`, `radius`, `borderRadius`, `blurRadius`, `spreadRadius`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, `padding`, `margin`, `iconSize`, `elevation`, `strokeWidth`, `borderWidth`, `flex`, `dx`, `dy`

#### Covered positional constructors

`SizedBox`, `EdgeInsets`, `EdgeInsetsDirectional`, `BorderRadius`, `Radius`, `Offset`, `Size`, `Padding`, `Icon`, `Divider`, `VerticalDivider`, `Gap`

---

## Planned rules

- `prefer_app_colors` — flag hardcoded `Color(0xFF...)` or `Colors.red` instead of app color constants
- `prefer_text_styles` — flag raw `TextStyle(...)` instead of using the app style manager
- `no_get_context_force_unwrap` — flag `Get.context!` force-unwrap (crash source in background/async contexts)
- `prefer_localization` — flag hardcoded string literals in widget trees that should go through `AppLocalizations`

---

## Ignoring a specific line

To suppress a rule on a single line, use a standard `// ignore` comment:

```dart
SizedBox(width: 1.0) // ignore: prefer_screenutil
```

---

## License

MIT
