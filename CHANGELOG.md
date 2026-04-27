## 1.0.0

- Initial version.

## Planned Rules (TODO)

- `prefer_app_colors` — flag hardcoded `Color(0xFF...)` or `Colors.red` instead of app color constants
- `prefer_text_styles` — flag raw `TextStyle(...)` instead of using the app style manager
- `no_get_context_force_unwrap` — flag `Get.context!` force-unwrap (crash source in background/async contexts)
- `prefer_localization` — flag hardcoded string literals in widget trees that should go through `AppLocalizations`

## Planned Infrastructure (TODO)

- **Migrate from `custom_lint` to `analysis_server_plugin`** — the `custom_lint` repository was archived on Mar 24, 2026 and is no longer maintained. The official replacement is [`analysis_server_plugin`](https://pub.dev/packages/analysis_server_plugin), which is maintained by the Dart team. Migration should happen before `custom_lint` stops working with future Dart/analyzer versions.
