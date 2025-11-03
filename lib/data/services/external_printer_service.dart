import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/external_printer_info.dart';

/// 外接USB打印机服务（使用Platform Channel实现）
/// 
/// 功能：
/// - USB打印机设备检测和管理
/// - 打印机连接和断开
/// - ESC/POS指令打印
/// - 设备状态监控
/// 
/// 完全独立于内置打印机服务，使用Android原生USB API
class ExternalPrinterService extends GetxService {
  /// 单例实例
  static ExternalPrinterService get instance => Get.find<ExternalPrinterService>();

  /// Platform Channel
  static const MethodChannel _channel = MethodChannel('com.ailand.pos/usb_printer');

  /// 已检测到的外接打印机列表
  final RxList<ExternalPrinterInfo> detectedPrinters = <ExternalPrinterInfo>[].obs;

  /// 当前连接的打印机
  final Rxn<ExternalPrinterInfo> currentPrinter = Rxn<ExternalPrinterInfo>();

  /// 调试日志列表
  final RxList<String> debugLogs = <String>[].obs;

  /// 最大日志数量
  static const int maxLogCount = 100;

  /// 是否正在扫描设备
  final RxBool isScanning = false.obs;

  /// 是否正在打印
  final RxBool isPrinting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _addLog('外接打印机服务初始化');
    _initMethodCallHandler();
    // 延迟扫描，避免初始化时阻塞
    Future.delayed(const Duration(milliseconds: 500), () {
      scanDevices();
    });
  }

  @override
  void onClose() {
    _addLog('外接打印机服务关闭');
    disconnect();
    super.onClose();
  }

  /// 初始化方法调用处理器（接收Android端事件）
  void _initMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onUsbDeviceAttached':
          _addLog('检测到USB设备连接');
          scanDevices();
          break;
        case 'onUsbDeviceDetached':
          final deviceId = call.arguments['deviceId'] as String?;
          _addLog('检测到USB设备断开: $deviceId');
          if (deviceId != null) {
            _handleDeviceDetached(deviceId);
          }
          break;
        default:
          _addLog('未知方法调用: ${call.method}');
      }
    });
  }

  /// 处理设备断开事件
  void _handleDeviceDetached(String deviceId) {
    // 从已检测列表中移除
    detectedPrinters.removeWhere((p) => p.deviceId == deviceId);

    // 如果是当前连接的设备，断开连接
    if (currentPrinter.value?.deviceId == deviceId) {
      _addLog('当前打印机已断开');
      disconnect();
    }
  }

  /// 扫描USB打印机设备
  Future<void> scanDevices() async {
    if (isScanning.value) {
      _addLog('正在扫描中，跳过重复扫描');
      return;
    }

    isScanning.value = true;
    _addLog('开始扫描USB打印机设备...');

    try {
      // 调用Android原生方法扫描设备
      final result = await _channel.invokeMethod<List>('scanDevices');
      
      if (result == null) {
        _addLog('扫描结果为空');
        detectedPrinters.clear();
        return;
      }

      _addLog('检测到 ${result.length} 个USB设备');

      // 清空旧列表
      detectedPrinters.clear();

      // 解析设备信息
      for (var deviceData in result) {
        final deviceMap = Map<String, dynamic>.from(deviceData as Map);
        final printerInfo = ExternalPrinterInfo.fromUsbDevice(
          deviceId: deviceMap['deviceId'] as String,
          vid: deviceMap['vendorId'] as int,
          pid: deviceMap['productId'] as int,
          manufacturer: deviceMap['manufacturer'] as String?,
          product: deviceMap['productName'] as String?,
          connected: false,
        );

        detectedPrinters.add(printerInfo);
        _addLog('发现打印机: ${printerInfo.deviceName} '
            '[VID:0x${printerInfo.vendorId.toRadixString(16)}, '
            'PID:0x${printerInfo.productId.toRadixString(16)}]');
      }

      if (detectedPrinters.isEmpty) {
        _addLog('未检测到外接打印机设备');
      } else {
        _addLog('共检测到 ${detectedPrinters.length} 台打印机');
      }
    } catch (e) {
      _addLog('扫描设备失败: $e', isError: true);
    } finally {
      isScanning.value = false;
    }
  }

  /// 连接到指定打印机
  Future<bool> connect(ExternalPrinterInfo printerInfo) async {
    _addLog('尝试连接打印机: ${printerInfo.deviceName}');

    try {
      // 先断开旧连接
      if (currentPrinter.value != null) {
        await disconnect();
      }

      // 调用Android原生方法连接设备
      final success = await _channel.invokeMethod<bool>(
        'connectDevice',
        {'deviceId': printerInfo.deviceId},
      );

      if (success == true) {
        // 更新当前打印机状态
        currentPrinter.value = printerInfo.copyWith(
          isConnected: true,
          status: ExternalPrinterStatus.ready,
        );

        // 更新检测列表中的状态
        final index = detectedPrinters.indexWhere(
          (p) => p.deviceId == printerInfo.deviceId,
        );
        if (index >= 0) {
          detectedPrinters[index] = currentPrinter.value!;
        }

        _addLog('✅ 打印机连接成功');
        return true;
      } else {
        _addLog('连接失败: 原生方法返回false', isError: true);
        return false;
      }
    } catch (e) {
      _addLog('连接打印机失败: $e', isError: true);
      currentPrinter.value = printerInfo.copyWith(
        isConnected: false,
        status: ExternalPrinterStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// 断开打印机连接
  Future<void> disconnect() async {
    if (currentPrinter.value == null) {
      return;
    }

    _addLog('断开打印机连接');
    
    try {
      await _channel.invokeMethod('disconnectDevice');
    } catch (e) {
      _addLog('断开连接时出错: $e', isError: true);
    }

    if (currentPrinter.value != null) {
      currentPrinter.value = currentPrinter.value!.copyWith(
        isConnected: false,
        status: ExternalPrinterStatus.disconnected,
      );
    }
  }

  /// 测试打印（打印示例小票）
  Future<bool> testPrint() async {
    if (currentPrinter.value == null || !currentPrinter.value!.isConnected) {
      _addLog('打印机未连接', isError: true);
      return false;
    }

    isPrinting.value = true;
    _addLog('开始测试打印...');

    try {
      // 构建测试小票内容
      final testContent = _buildTestReceiptContent();
      
      // 调用Android原生方法打印
      final success = await _channel.invokeMethod<bool>(
        'printText',
        {'content': testContent},
      );

      if (success == true) {
        _addLog('✅ 测试打印成功');
        return true;
      } else {
        _addLog('打印失败: 原生方法返回false', isError: true);
        return false;
      }
    } catch (e) {
      _addLog('打印失败: $e', isError: true);
      return false;
    } finally {
      isPrinting.value = false;
    }
  }

  /// 构建测试小票内容
  String _buildTestReceiptContent() {
    final printer = currentPrinter.value!;
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return '''
        外接打印机测试
        
设备信息:
名称: ${printer.deviceName}
制造商: ${printer.manufacturer ?? '未知'}
VID: 0x${printer.vendorId.toRadixString(16).toUpperCase()}
PID: 0x${printer.productId.toRadixString(16).toUpperCase()}

测试时间: $dateStr $timeStr

--------------------------------
        打印测试成功！
--------------------------------



''';
  }

  /// 打印自定义内容
  Future<bool> printCustomContent(String content) async {
    if (currentPrinter.value == null || !currentPrinter.value!.isConnected) {
      _addLog('打印机未连接', isError: true);
      return false;
    }

    isPrinting.value = true;
    _addLog('开始打印自定义内容...');

    try {
      final success = await _channel.invokeMethod<bool>(
        'printText',
        {'content': content},
      );

      if (success == true) {
        _addLog('✅ 打印成功');
        return true;
      } else {
        _addLog('打印失败', isError: true);
        return false;
      }
    } catch (e) {
      _addLog('打印失败: $e', isError: true);
      return false;
    } finally {
      isPrinting.value = false;
    }
  }

  /// 添加调试日志
  void _addLog(String message, {bool isError = false}) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final prefix = isError ? '❌' : '📝';
    final log = '[$timestamp] $prefix $message';

    debugLogs.insert(0, log);

    // 限制日志数量
    if (debugLogs.length > maxLogCount) {
      debugLogs.removeRange(maxLogCount, debugLogs.length);
    }

    // 输出到控制台
    print('[ExternalPrinter] $message');
  }

  /// 清空调试日志
  void clearLogs() {
    debugLogs.clear();
    _addLog('日志已清空');
  }
}