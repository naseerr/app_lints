import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/prefer_screenutil.dart';

/// Entry point for the app_lints plugin.
/// custom_lint discovers this via the createPlugin() function.
PluginBase createPlugin() => _AppLints();

class _AppLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const PreferScreenUtil(),
      ];
}
