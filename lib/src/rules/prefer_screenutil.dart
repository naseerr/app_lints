import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lint rule that enforces flutter_screenutil usage for all numeric size values.
///
/// Flags any raw numeric literal (int or double) that is not a screenutil
/// extension call (.w, .h, .sp, .r, .sw, .sh) when used as a sizing value.
///
/// Excluded values: 0, -1, double.infinity (these have no screen-relative meaning).
///
/// Optional path exclusions in analysis_options.yaml.
/// NOTE: exclude must be a sibling key, NOT nested under prefer_screenutil.
/// ```yaml
/// custom_lint:
///   rules:
///     - prefer_screenutil: true
///       exclude:
///         - lib/data/**
///         - lib/core/services/**
/// ```
class PreferScreenUtil extends DartLintRule {
  const PreferScreenUtil({this.excludeGlobs = const []})
      : super(code: _code);

  /// Constructs the rule from [CustomLintConfigs], reading the exclude list.
  factory PreferScreenUtil.fromConfigs(CustomLintConfigs configs) {
    final options = configs.rules['prefer_screenutil'];
    final exclude = options?.json['exclude'];
    final globs = exclude is List
        ? exclude.whereType<String>().toList()
        : const <String>[];
    return PreferScreenUtil(excludeGlobs: globs);
  }

  /// Glob patterns for paths to skip (e.g. 'lib/data/providers/**').
  final List<String> excludeGlobs;

  static const _code = LintCode(
    name: 'prefer_screenutil',
    problemMessage:
        'Use flutter_screenutil for sizing. Replace with .w, .h, .sp, or .r extension.',
    correctionMessage:
        'Example: 16 → 16.w (width), 16 → 16.h (height), 14 → 14.sp (font), 8 → 8.r (radius).',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (_isExcluded(resolver.path)) return;

    context.registry.addIntegerLiteral((node) {
      if (_shouldFlag(node)) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addDoubleLiteral((node) {
      if (_shouldFlagDouble(node)) {
        reporter.atNode(node, _code);
      }
    });
  }

  /// Returns true if [filePath] matches any of the [excludeGlobs].
  bool _isExcluded(String filePath) {
    if (excludeGlobs.isEmpty) return false;
    final normalized = filePath.replaceAll(r'\', '/');
    for (final glob in excludeGlobs) {
      if (_matchesGlob(normalized, glob)) return true;
    }
    return false;
  }

  /// Matches [path] against a glob pattern supporting * and ** wildcards.
  bool _matchesGlob(String path, String glob) {
    final normalizedGlob = glob.replaceAll(r'\', '/');
    final regexStr = normalizedGlob.splitMapJoin(
      RegExp(r'\*\*|\*|\?|[.+^${}()|[\]\\]'),
      onMatch: (m) {
        switch (m.group(0)) {
          case '**':
            return '.*';
          case '*':
            return '[^/]*';
          case '?':
            return '[^/]';
          default:
            return RegExp.escape(m.group(0)!);
        }
      },
      onNonMatch: (s) => s,
    );
    final regex = RegExp('$regexStr\$');
    // Match against full path or the lib-relative suffix.
    final libIndex = path.indexOf('/lib/');
    final relativePath = libIndex >= 0 ? path.substring(libIndex + 1) : path;
    return regex.hasMatch(path) || regex.hasMatch(relativePath);
  }

  /// Whether this integer literal should be flagged.
  bool _shouldFlag(IntegerLiteral node) {
    final value = node.value;
    if (value == null || value == 0 || value == 1) return false;

    final parent = node.parent;
    if (parent is PrefixExpression && parent.operator.lexeme == '-') {
      final grandParent = parent.parent;
      if (value == 1) return false;
      if (!_isScreenUtilCall(grandParent)) {
        return _isInSizingContext(parent);
      }
      return false;
    }

    if (_isScreenUtilCall(parent)) return false;
    return _isInSizingContext(node);
  }

  /// Whether this double literal should be flagged.
  bool _shouldFlagDouble(DoubleLiteral node) {
    final value = node.value;
    if (value == 0.0 ||
        value == double.infinity ||
        value == double.negativeInfinity) {
      return false;
    }

    final parent = node.parent;
    if (_isScreenUtilCall(parent)) return false;
    return _isInSizingContext(node);
  }

  /// Returns true if [node] is the receiver of a screenutil extension method.
  bool _isScreenUtilCall(AstNode? node) {
    if (node is! MethodInvocation && node is! PropertyAccess) return false;

    if (node is PropertyAccess) {
      return _screenUtilExtensions.contains(node.propertyName.name);
    }
    if (node is MethodInvocation) {
      return _screenUtilExtensions.contains(node.methodName.name);
    }
    return false;
  }

  static const _screenUtilExtensions = {
    'w', 'h', 'sp', 'r', 'sw', 'sh', 'dm',
  };

  /// Returns true if [node] is in a sizing context.
  bool _isInSizingContext(AstNode node) {
    AstNode? current = node.parent;

    if (current is PrefixExpression) {
      current = current.parent;
    }

    if (current is NamedExpression) {
      final name = current.name.label.name;
      return _sizingParameterNames.contains(name);
    }

    if (current is ArgumentList) {
      final grandParent = current.parent;
      if (grandParent is InstanceCreationExpression) {
        final typeName = grandParent.constructorName.type.name.lexeme;
        if (!_sizingConstructors.contains(typeName)) return false;
        final constructorParent = grandParent.parent;
        if (constructorParent is NamedExpression) {
          if (_excludedParameterNames
              .contains(constructorParent.name.label.name)) {
            return false;
          }
        }
        return true;
      }
    }

    if (current is ArgumentList) {
      final grandParent = current.parent;
      if (grandParent is MethodInvocation) {
        final target = grandParent.target;
        if (target is SimpleIdentifier) {
          return _sizingConstructors.contains(target.name);
        }
        return _sizingConstructors.contains(grandParent.methodName.name);
      }
    }

    if (current is ListLiteral || current is SetOrMapLiteral) {
      return _isInSizingContext(current!);
    }

    if (current is VariableDeclaration) {
      return true;
    }

    return false;
  }

  static const _excludedParameterNames = {
    'designSize',
  };

  static const _sizingParameterNames = {
    'width', 'height', 'size', 'extent',
    'minWidth', 'maxWidth', 'minHeight', 'maxHeight',
    'minExtent', 'maxExtent',
    'spacing', 'runSpacing', 'gap',
    'fontSize', 'letterSpacing', 'wordSpacing', 'lineHeight',
    'radius', 'borderRadius', 'blurRadius', 'spreadRadius',
    'topLeft', 'topRight', 'bottomLeft', 'bottomRight',
    'padding', 'margin',
    'iconSize',
    'elevation', 'blurStyle',
    'strokeWidth', 'borderWidth',
    'flex',
    'dx', 'dy',
  };

  static const _sizingConstructors = {
    'SizedBox', 'SizedBox.expand', 'SizedBox.shrink',
    'EdgeInsets', 'EdgeInsets.all', 'EdgeInsets.symmetric',
    'EdgeInsets.only', 'EdgeInsets.fromLTRB',
    'EdgeInsetsDirectional', 'EdgeInsetsDirectional.all',
    'EdgeInsetsDirectional.only', 'EdgeInsetsDirectional.fromSTEB',
    'BorderRadius', 'BorderRadius.all', 'BorderRadius.circular',
    'BorderRadius.only', 'BorderRadius.vertical', 'BorderRadius.horizontal',
    'Radius', 'Radius.circular', 'Radius.elliptical',
    'Offset',
    'Size',
    'Padding',
    'Icon',
    'Divider',
    'VerticalDivider',
    'Gap',
  };
}
