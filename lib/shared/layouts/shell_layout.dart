import 'package:flutter/material.dart';
import '../widgets/app_header.dart';

/// Shell Layout - 包含 Header 的布局容器
/// 使用 GoRouter 的 ShellRoute，Header 固定显示，子页面内容会根据路由变化
class ShellLayout extends StatelessWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // 固定的 Header
            const AppHeader(),
            // 动态变化的内容区域
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
