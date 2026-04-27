# app_lints

Custom Dart/Flutter lint rules enforcing `flutter_screenutil` usage for all sizing values.

## Rules

### `prefer_screenutil`

Flags any raw numeric literal used in a sizing context that doesn't use a `flutter_screenutil` extension (`.w`, `.h`, `.sp`, `.r`, `.sw`, `.sh`).

**Severity:** ERROR

**Bad:**
```dart
SizedBox(width: 100, height: 50)
EdgeInsets.all(16)
Text('Hi', style: TextStyle(fontSize: 14))
Icon(Icons.add, size: 24)
```

**Good:**
```dart
SizedBox(width: 100.w, height: 50.h)
EdgeInsets.all(16.r)
Text('Hi', style: TextStyle(fontSize: 14.sp))
Icon(Icons.add, size: 24.r)
```

**Excluded values:** `0`, `1`, `-1`, `double.infinity` — these have no screen-relative meaning.

## Installation

Add to your Flutter project's `pubspec.yaml`:

```yaml
dev_dependencies:
  custom_lint: ^0.8.1
  app_lints:
    git:
      url: https://github.com/YOUR_USERNAME/app_lints.git
```

Enable in `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

## Usage

Run from the command line:

```bash
dart run custom_lint
```

Or use your IDE — the rule will show as errors inline via the Dart Analysis Server.

## Covered sizing contexts

**Named parameters:** `width`, `height`, `size`, `fontSize`, `letterSpacing`, `spacing`, `runSpacing`, `radius`, `borderRadius`, `blurRadius`, `spreadRadius`, `elevation`, `strokeWidth`, `padding`, `margin`, `iconSize`, `dx`, `dy`, and more.

**Positional constructors:** `SizedBox`, `EdgeInsets`, `EdgeInsetsDirectional`, `BorderRadius`, `Radius`, `Offset`, `Size`, `Padding`, `Icon`, `Divider`, `VerticalDivider`, `Gap`.
