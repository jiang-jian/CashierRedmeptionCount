/// Sunmi Customer API 快速测试
/// 用于验证 SDK 集成是否正常

import 'package:flutter/material.dart';
import 'package:ailand_pos/data/services/sunmi_customer_api_service.dart';

class TestSunmiCustomerApi extends StatefulWidget {
  const TestSunmiCustomerApi({super.key});

  @override
  State<TestSunmiCustomerApi> createState() => _TestSunmiCustomerApiState();
}

class _TestSunmiCustomerApiState extends State<TestSunmiCustomerApi> {
  final SunmiCustomerApiService _apiService = SunmiCustomerApiService();
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
    print(message);
  }

  Future<void> _runTests() async {
    _addLog('========== 开始测试 Sunmi Customer API ==========');
    
    // 测试1: 初始化
    _addLog('测试1: 初始化服务...');
    final initSuccess = await _apiService.initialize();
    _addLog('初始化结果: ${initSuccess ? "成功 ✓" : "失败 ✗"}');
    
    // 测试2: 检查连接
    _addLog('测试2: 检查连接状态...');
    final isConnected = await _apiService.isConnected();
    _addLog('连接状态: ${isConnected ? "已连接 ✓" : "未连接 ✗"}');
    
    if (!isConnected) {
      _addLog('⚠️ 服务未连接，后续测试可能失败');
      _addLog('请确保：');
      _addLog('1. 设备已安装 SunmiCustomerService');
      _addLog('2. 运行在商米设备上');
      return;
    }
    
    // 测试3: 获取设备型号
    _addLog('测试3: 获取设备型号...');
    final model = await _apiService.getDeviceModel();
    _addLog('设备型号: ${model ?? "获取失败"}');
    
    // 测试4: 获取序列号
    _addLog('测试4: 获取设备序列号...');
    final serialNumber = await _apiService.getDeviceSerialNumber();
    _addLog('序列号: ${serialNumber ?? "获取失败"}');
    
    // 测试5: 获取完整设备信息
    _addLog('测试5: 获取完整设备信息...');
    final deviceInfo = await _apiService.getDeviceInfo();
    if (deviceInfo != null) {
      _addLog('设备信息获取成功:');
      deviceInfo.forEach((key, value) {
        _addLog('  - $key: $value');
      });
    } else {
      _addLog('设备信息获取失败');
    }
    
    _addLog('========== 测试完成 ==========');
    _addLog('');
    _addLog('💡 提示：');
    _addLog('- 如果所有测试通过，说明 SDK 集成成功');
    _addLog('- 网络管理功能需要在实际设备上测试');
    _addLog('- 查看完整演示请使用 SunmiCustomerApiDemoPage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunmi Customer API 测试'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _logs.clear();
              });
              _runTests();
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            final log = _logs[index];
            Color textColor = Colors.white;
            
            if (log.contains('✓') || log.contains('成功')) {
              textColor = Colors.green;
            } else if (log.contains('✗') || log.contains('失败')) {
              textColor = Colors.red;
            } else if (log.contains('⚠️') || log.contains('警告')) {
              textColor = Colors.orange;
            } else if (log.contains('💡') || log.contains('提示')) {
              textColor = Colors.cyan;
            } else if (log.contains('==========')) {
              textColor = Colors.yellow;
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                log,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SunmiCustomerApiDemoPage(),
            ),
          );
        },
        icon: const Icon(Icons.dashboard),
        label: const Text('打开演示页面'),
      ),
    );
  }
}

// 导入演示页面
import 'package:ailand_pos/presentation/pages/sunmi_customer_api_demo_page.dart';
