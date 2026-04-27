import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/prefer_screenutil.dart';

PluginBase createPlugin() => _AppLints();

class _AppLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        PreferScreenUtil.fromConfigs(configs),
      ];
}
