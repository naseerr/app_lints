## 1.0.0

- Initial version.

## Planned Rules (TODO)

- `prefer_app_colors` — flag hardcoded `Color(0xFF...)` or `Colors.red` instead of app color constants
- `prefer_text_styles` — flag raw `TextStyle(...)` instead of using the app style manager
- `no_get_context_force_unwrap` — flag `Get.context!` force-unwrap (crash source in background/async contexts)
- `prefer_localization` — flag hardcoded string literals in widget trees that should go through `AppLocalizations`

## Known Incompatibilities

- **`hive_generator`** — projects using `hive_generator` (any version up to 2.0.1) cannot add `app_lints` due to a hard `analyzer` version conflict. `hive_generator` requires `analyzer <7.0.0` while `custom_lint ^0.8.1` requires `analyzer ^8.0.0`. The `hive_generator` package is abandoned with no fix coming. Resolution: remove `hive_generator` and commit generated `.g.dart` files, or migrate to `hive_ce_generator ^1.9.5` which supports `analyzer ^8.0.0`.

## Planned Infrastructure (TODO)

- **Migrate from `custom_lint` to `analysis_server_plugin`** — the `custom_lint` repository was archived on Mar 24, 2026 and is no longer maintained. The official replacement is [`analysis_server_plugin`](https://pub.dev/packages/analysis_server_plugin), which is maintained by the Dart team. Migration should happen before `custom_lint` stops working with future Dart/analyzer versions.
