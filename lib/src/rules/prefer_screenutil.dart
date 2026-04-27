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
class PreferScreenUtil extends DartLintRule {
  const PreferScreenUtil() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_screenutil',
    problemMessage:
        'Use flutter_screenutil for sizing. Replace with .w, .h, .sp, or .r extension.',
    correctionMessage:
        'Example: 16 → 16.w (width), 16 → 16.h (height), 14 → 14.sp (font), 8 → 8.r (radius).',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
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

  /// Whether this integer literal should be flagged.
  bool _shouldFlag(IntegerLiteral node) {
    final value = node.value;
    // Exclude 0 and -1 — always valid as-is.
    if (value == null || value == 0 || value == 1) return false;

    // Exclude negative 1 (unary minus wrapping 1)
    final parent = node.parent;
    if (parent is PrefixExpression && parent.operator.lexeme == '-') {
      final grandParent = parent.parent;
      // -1 is fine, larger negatives should use screenutil
      final negVal = value;
      if (negVal == 1) {
        return false;
      }
      // For other negatives, still flag unless already a screenutil call
      if (!_isScreenUtilCall(grandParent)) {
        return _isInSizingContext(parent);
      }
      return false;
    }

    // If this number is already the receiver of a screenutil extension (.w, .h etc), skip.
    if (_isScreenUtilCall(parent)) return false;

    // Flag if used in a sizing context.
    return _isInSizingContext(node);
  }

  /// Whether this double literal should be flagged.
  bool _shouldFlagDouble(DoubleLiteral node) {
    final value = node.value;
    // Exclude 0.0, infinity, common ratios used as multipliers not sizes.
    if (value == 0.0 ||
        value == double.infinity ||
        value == double.negativeInfinity) {
      return false;
    }

    final parent = node.parent;

    // Already a screenutil call receiver.
    if (_isScreenUtilCall(parent)) return false;

    return _isInSizingContext(node);
  }

  /// Returns true if [node] is the receiver of a screenutil extension method
  /// (.w, .h, .sp, .r, .sw, .sh, .dm).
  bool _isScreenUtilCall(AstNode? node) {
    if (node is! MethodInvocation && node is! PropertyAccess) return false;

    if (node is PropertyAccess) {
      final name = node.propertyName.name;
      return _screenUtilExtensions.contains(name);
    }

    if (node is MethodInvocation) {
      final name = node.methodName.name;
      return _screenUtilExtensions.contains(name);
    }

    return false;
  }

  static const _screenUtilExtensions = {
    'w', 'h', 'sp', 'r', 'sw', 'sh', 'dm',
  };

  /// Returns true if [node] is used in a context that requires screen-relative sizing.
  /// This covers named parameters with sizing semantics AND positional arguments
  /// inside known sizing constructors.
  bool _isInSizingContext(AstNode node) {
    // Walk up to find the nearest meaningful parent.
    AstNode? current = node.parent;

    // Skip unary minus (negative values).
    if (current is PrefixExpression) {
      current = current.parent;
    }

    // Named argument: SizedBox(width: 100) → flag 100.
    if (current is NamedExpression) {
      final name = current.name.label.name;
      return _sizingParameterNames.contains(name);
    }

    // Positional argument inside a known sizing constructor/method.
    if (current is ArgumentList) {
      final grandParent = current.parent;
      if (grandParent is InstanceCreationExpression) {
        final typeName = grandParent.constructorName.type.name.lexeme;
        if (!_sizingConstructors.contains(typeName)) return false;
        // If the constructor itself is the value of an excluded named param
        // (e.g. designSize: Size(390, 844)) — skip it.
        final constructorParent = grandParent.parent;
        if (constructorParent is NamedExpression) {
          final paramName = constructorParent.name.label.name;
          if (_excludedParameterNames.contains(paramName)) return false;
        }
        return true;
      }
    }

    // EdgeInsets / BorderRadius positional values.
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

    // List/Set literals used as padding values etc.
    if (current is ListLiteral || current is SetOrMapLiteral) {
      return _isInSizingContext(current!);
    }

    // Variable declaration: double x = 100; — flag unless it's a known constant.
    if (current is VariableDeclaration) {
      // Flag all — forces dev to use .w/.h etc or mark explicitly.
      return true;
    }

    return false;
  }

  /// Named parameters explicitly excluded (these are NOT widget sizing).
  static const _excludedParameterNames = {
    'designSize', // ScreenUtilInit design canvas reference
  };

  /// Named parameters that indicate a sizing value requiring screenutil.
  static const _sizingParameterNames = {
    // Dimensions
    'width', 'height', 'size', 'extent',
    'minWidth', 'maxWidth', 'minHeight', 'maxHeight',
    'minExtent', 'maxExtent',
    // Spacing / gaps
    'spacing', 'runSpacing', 'gap',
    // Font
    'fontSize', 'letterSpacing', 'wordSpacing', 'lineHeight',
    // Radius
    'radius', 'borderRadius', 'blurRadius', 'spreadRadius',
    'topLeft', 'topRight', 'bottomLeft', 'bottomRight',
    // Padding / margin (EdgeInsets values come through positional, handled below)
    'padding', 'margin',
    // Icon
    'iconSize',
    // Elevation / shadow
    'elevation', 'blurStyle',
    // Stroke / border
    'strokeWidth', 'borderWidth',
    // Flex
    'flex',
    // Offset
    'dx', 'dy',
    // Curve duration (not sizing, but many devs hardcode ms values)
    // Excluded intentionally — Duration(milliseconds: 300) is fine as-is.
  };

  /// Constructors/classes whose positional arguments are all sizing values.
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
