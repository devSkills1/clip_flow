import 'dart:ui' as ui;

import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/platform/system/window_listener.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用切换器页面
///
/// 模拟 macOS Cmd+Tab 的应用切换界面，支持：
/// - 全屏半透明背景
/// - 水平居中的应用列表
/// - 键盘和鼠标导航
/// - 实时预览和切换
class AppSwitcherPage extends ConsumerStatefulWidget {
  /// 构造器
  const AppSwitcherPage({super.key});

  @override
  ConsumerState<AppSwitcherPage> createState() => _AppSwitcherPageState();
}

class _AppSwitcherPageState extends ConsumerState<AppSwitcherPage> {

  @override
  void initState() {
    super.initState();
    _setupWindow();
  }

  /// 设置窗口尺寸和属性
  Future<void> _setupWindow() async {
    try {
      // 等待一帧以确保context已初始化
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          // 使用WindowManagementService统一处理窗口设置
          await WindowManagementService.instance.applyUISettings(UiMode.appSwitcher, context: context);
        }
      });
    } on Exception catch (e, stackTrace) {
      // 错误处理，不阻止界面显示
      await Log.e(
        '应用切换器窗口设置失败',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
        ),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 15,
            sigmaY: 15,
            tileMode: ui.TileMode.decal,
          ),
          child: const Center(
            child: _AppSwitcherWidget(),
          ),
        ),
      ),
    );
  }
}

/// 占位应用切换器组件
class _AppSwitcherWidget extends ConsumerWidget {
  const _AppSwitcherWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '应用切换器',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming Soon\n类似 macOS Cmd+Tab 的应用切换界面',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 切换回传统UI的按钮
          ElevatedButton.icon(
            onPressed: () {
              // 切换回传统UI模式
              ref
                  .read(userPreferencesProvider.notifier)
                  .setUiMode(UiMode.traditional);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('切回传统剪贴板'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
