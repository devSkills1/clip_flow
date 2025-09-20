import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:flutter/material.dart';

/// 国际化文本混合模式工具类
///
/// 采用"高频专用方法 + 通用方法"的混合设计模式，在代码简洁性和类型安全之间找到平衡。
///
/// ## 设计原则
/// 1. **高频文本**：为常用的国际化文本提供专用方法，确保类型安全和IDE友好
/// 2. **低频文本**：使用通用方法处理，减少代码冗余
/// 3. **统一兜底**：所有方法都有统一的兜底机制
///
/// ## 使用指南
///
/// ### 高频文本使用（推荐）
/// ```dart
/// // 使用专用方法，IDE有完整提示，类型安全
/// String okText = I18nHybridUtil.getActionOk(context);
/// String cancelText = I18nHybridUtil.getActionCancel(context);
/// String deleteText = I18nHybridUtil.getActionDelete(context);
/// ```
///
/// ### 低频文本使用
/// ```dart
/// // 使用通用方法，减少样板代码
/// String customText = I18nHybridUtil.getText(
///   context,
///   (l10n) => l10n.someRareText,
///   'Default Text',
/// );
///
/// // 带参数的文本
/// String paramText = I18nHybridUtil.getTextWithArgs(
///   context,
///   (l10n, count) => l10n.itemCount(count),
///   5,
///   (count) => 'Items: $count',
/// );
/// ```
///
/// ### 扩展方法使用（可选）
/// ```dart
/// // 使用扩展方法，更简洁的语法
/// String text = context.i18nText(
///   (l10n) => l10n.someText,
///   'Fallback',
/// );
/// ```
///
/// ## 何时使用哪种方式
///
/// | 使用场景 | 推荐方式 | 原因 |
/// |---------|---------|------|
/// | 通用操作文本（确定、取消、删除等） | 专用方法 | 高频使用，IDE友好 |
/// | 时间显示文本 | 专用方法 | 格式统一，类型安全 |
/// | 剪贴板类型文本 | 专用方法 | 枚举性质，便于维护 |
/// | 设置页面文本 | 通用方法 | 使用频率相对较低 |
/// | 错误提示文本 | 通用方法 | 种类繁多，专用方法会过于冗余 |
/// | 一次性使用的文本 | 通用方法 | 避免不必要的方法定义 |
///
/// ## 性能考虑
/// - 专用方法：编译时优化，运行时开销最小
/// - 通用方法：轻微的函数调用开销，但可忽略不计
/// - 扩展方法：与通用方法性能相当，语法更简洁
///
/// ## 维护策略
/// 1. 新增高频文本时，评估是否需要专用方法
/// 2. 当某个通用方法使用频率很高时，考虑提升为专用方法
/// 3. 定期review专用方法的使用频率，移除不必要的方法
class I18nHybridUtil {
  /// 私有构造：禁止实例化
  const I18nHybridUtil._();

  // ==================== 通用方法 ====================

  /// 获取本地化文本，如果为空则使用兜底值
  ///
  /// 这是最基础的通用方法，适用于所有简单的国际化文本获取场景。
  ///
  /// [context] 构建上下文
  /// [getter] 从S对象获取文本的函数
  /// [fallback] 兜底文本
  ///
  /// 示例：
  /// ```dart
  /// String text = I18nHybridUtil.getText(
  ///   context,
  ///   (l10n) => l10n.customText,
  ///   'Default Text',
  /// );
  /// ```
  static String getText(
    BuildContext context,
    String Function(S) getter,
    String fallback,
  ) {
    final l10n = S.of(context);
    return l10n != null ? getter(l10n) : fallback;
  }

  /// 获取带参数的本地化文本，如果为空则使用兜底值
  ///
  /// 适用于需要动态参数的国际化文本场景。
  ///
  /// [context] 构建上下文
  /// [getter] 从S对象获取文本的函数，接受参数
  /// [args] 传递给getter的参数
  /// [fallbackGetter] 生成兜底文本的函数
  ///
  /// 示例：
  /// ```dart
  /// String text = I18nHybridUtil.getTextWithArgs(
  ///   context,
  ///   (l10n, count) => l10n.itemCount(count),
  ///   5,
  ///   (count) => 'Items: $count',
  /// );
  /// ```
  static String getTextWithArgs<T>(
    BuildContext context,
    String Function(S, T) getter,
    T args,
    String Function(T) fallbackGetter,
  ) {
    final l10n = S.of(context);
    return l10n != null ? getter(l10n, args) : fallbackGetter(args);
  }

  // ==================== 高频专用方法 ====================
  // 以下方法为高频使用的国际化文本提供专用接口
  // 优点：类型安全、IDE友好、编译时优化
  // 适用：通用操作、时间显示、剪贴板类型等高频场景

  /// 获取操作类文本：确定
  ///
  /// 这是最常用的操作按钮文本，几乎在所有对话框中都会使用。
  static String getActionOk(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.actionOk,
      I18nFallbacks.common.actionOk,
    );
  }

  /// 获取操作类文本：取消
  ///
  /// 与确定按钮配对使用，同样是高频操作文本。
  static String getActionCancel(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.actionCancel,
      I18nFallbacks.common.actionCancel,
    );
  }

  /// 获取操作类文本：删除
  ///
  /// 危险操作的标准文本，需要保持一致性。
  static String getActionDelete(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.actionDelete,
      I18nFallbacks.common.actionDelete,
    );
  }

  /// 获取时间显示：刚刚
  ///
  /// 时间显示是高频场景，且格式需要统一。
  static String getTimeJustNow(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.timeJustNow,
      I18nFallbacks.common.timeJustNow,
    );
  }

  /// 获取时间显示：分钟前
  ///
  /// 带参数的时间显示，使用频率很高。
  static String getTimeMinutesAgo(BuildContext context, int minutes) {
    return getTextWithArgs(
      context,
      (l10n, minutes) => l10n.timeMinutesAgo(minutes),
      minutes,
      (minutes) => I18nFallbacks.common.timeMinutesAgo(minutes),
    );
  }

  /// 获取剪贴板类型：文本
  ///
  /// 剪贴板类型是枚举性质的文本，适合专用方法。
  static String getClipTypeText(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeText,
      I18nFallbacks.common.clipTypeText,
    );
  }

  /// 获取剪贴板类型：图片
  static String getClipTypeImage(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeImage,
      I18nFallbacks.common.clipTypeImage,
    );
  }

  // ==================== 示例：低频文本的使用 ====================
  // 以下注释展示了如何使用通用方法处理低频文本

  /*
  // 设置页面文本 - 使用通用方法
  static String getSettingsTitle(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.settingsTitle,
      I18nFallbacks.settings.title,
    );
  }
  
  // 但实际使用时，可以直接调用通用方法：
  // String title = I18nHybridUtil.getText(
  //   context,
  //   (l10n) => l10n.settingsTitle,
  //   I18nFallbacks.settings.title,
  // );
  */
}

/// BuildContext的扩展方法，提供更简洁的国际化文本获取方式
///
/// 这是可选的语法糖，让代码更加简洁。适合喜欢链式调用的开发者。
///
/// 使用示例：
/// ```dart
/// String text = context.i18nText(
///   (l10n) => l10n.someText,
///   'Fallback',
/// );
///
/// String paramText = context.i18nTextWithArgs(
///   (l10n, count) => l10n.itemCount(count),
///   5,
///   (count) => 'Items: $count',
/// );
/// ```
extension I18nContextExtension on BuildContext {
  /// 获取国际化文本的扩展方法
  String i18nText(
    String Function(S) getter,
    String fallback,
  ) {
    return I18nHybridUtil.getText(this, getter, fallback);
  }

  /// 获取带参数的国际化文本的扩展方法
  String i18nTextWithArgs<T>(
    String Function(S, T) getter,
    T args,
    String Function(T) fallbackGetter,
  ) {
    return I18nHybridUtil.getTextWithArgs(this, getter, args, fallbackGetter);
  }
}
