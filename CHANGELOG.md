## 1.0.0

- Initial version.

## Planned Rules (TODO)

- `prefer_app_colors` — flag hardcoded `Color(0xFF...)` or `Colors.red` instead of app color constants
- `prefer_text_styles` — flag raw `TextStyle(...)` instead of using the app style manager
- `no_get_context_force_unwrap` — flag `Get.context!` force-unwrap (crash source in background/async contexts)
- `prefer_localization` — flag hardcoded string literals in widget trees that should go through `AppLocalizations`
