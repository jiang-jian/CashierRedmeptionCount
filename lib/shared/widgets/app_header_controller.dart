import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/storage/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/auth_service.dart';
import '../../app/routes/router_config.dart';

/// AppHeader 专用控制器
/// 管理头部组件的交互逻辑，包括修改密码、退出登录等
class AppHeaderController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final AuthService _authService = AuthService();

  /// 显示退出登录确认对话框
  Future<void> showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认退出'),
        content: Container(width: 400, child: const Text('您确定要退出登录吗?')),
        actions: [
          OutlinedButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          ElevatedButton(
            child: const Text('确定'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    // 在对话框关闭后再执行退出登录
    if (result == true) {
      await logout();
    }
  }

  /// 退出登录
  Future<void> logout() async {
    print('logout');
    try {
      // 先调用退出登录 API（此时 token 还在，可以正常请求）
      await _authService.logout();
    } catch (e) {
      debugPrint('退出登录 API 调用失败: $e');
    }
    print('logout success');
    // 清除本地存储的用户数据
    await _storage.remove(StorageKeys.token);
    await _storage.remove(StorageKeys.tokenName);
    await _storage.remove(StorageKeys.userId);
    await _storage.remove(StorageKeys.cashierName);
    await _storage.remove(StorageKeys.merchantCode);

    // 使用全局 GoRouter 实例进行导航
    AppRouter.replace('/login');
  }

  /// 显示修改密码对话框
  Future<void> showChangePasswordDialog(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      // dialog 宽度为 500
      builder: (context) => AlertDialog(
        title: const Text('修改登录密码'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请输入旧密码和新密码'),
              const SizedBox(width: 400, height: 16),
              const Text('旧密码'),
              const SizedBox(height: 8),
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '请输入旧密码'),
              ),
              const SizedBox(height: 16),
              const Text('新密码'),
              const SizedBox(height: 8),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '请输入新密码'),
              ),
              const SizedBox(height: 16),
              const Text('确认新密码'),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '请再次输入新密码'),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: const Text('确定'),
            onPressed: () {
              if (oldPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入旧密码')));
                return;
              }
              if (newPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入新密码')));
                return;
              }
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
                return;
              }
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      // TODO: 调用修改密码 API
      debugPrint(
        '修改密码: ${oldPasswordController.text} -> ${newPasswordController.text}',
      );
    }

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}
