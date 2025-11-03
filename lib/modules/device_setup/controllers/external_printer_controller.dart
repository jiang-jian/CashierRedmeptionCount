import 'package:get/get.dart';
import '../../../data/models/external_printer_info.dart';
import '../../../data/services/external_printer_service.dart';

/// 外接打印机控制器
/// 
/// 职责：
/// - 管理外接打印机UI状态
/// - 处理用户交互逻辑
/// - 协调服务层调用
/// 
/// 完全独立于内置打印机控制器
class ExternalPrinterController extends GetxController {
  /// 外接打印机服务实例
  late final ExternalPrinterService _printerService;

  /// 设备列表
  List<ExternalPrinterInfo> get printers => _printerService.detectedPrinters;

  /// 当前连接的打印机
  ExternalPrinterInfo? get currentPrinter => _printerService.currentPrinter.value;

  /// 调试日志
  List<String> get logs => _printerService.debugLogs;

  /// 是否正在扫描
  bool get isScanning => _printerService.isScanning.value;

  /// 是否正在打印
  bool get isPrinting => _printerService.isPrinting.value;

  /// 是否有打印机连接
  bool get hasConnectedPrinter => 
      currentPrinter != null && currentPrinter!.isConnected;

  /// 检测状态
  final Rx<String> checkStatus = 'idle'.obs;

  @override
  void onInit() {
    super.onInit();
    _initService();
  }

  /// 初始化服务
  Future<void> _initService() async {
    try {
      // 尝试获取已存在的服务实例
      _printerService = ExternalPrinterService.instance;
    } catch (e) {
      // 如果不存在，则创建新实例
      _printerService = Get.put(ExternalPrinterService());
    }
  }

  /// 扫描设备
  Future<void> scanDevices() async {
    checkStatus.value = 'scanning';
    try {
      await _printerService.scanDevices();
      
      if (printers.isEmpty) {
        checkStatus.value = 'no_device';
      } else {
        checkStatus.value = 'found';
      }
    } catch (e) {
      checkStatus.value = 'error';
    }
  }

  /// 连接到打印机
  Future<void> connectPrinter(ExternalPrinterInfo printerInfo) async {
    checkStatus.value = 'connecting';
    
    final success = await _printerService.connect(printerInfo);
    
    if (success) {
      checkStatus.value = 'connected';
      Get.snackbar(
        '连接成功',
        '已连接到 ${printerInfo.deviceName}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } else {
      checkStatus.value = 'error';
      Get.snackbar(
        '连接失败',
        '无法连接到 ${printerInfo.deviceName}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// 断开打印机连接
  Future<void> disconnectPrinter() async {
    await _printerService.disconnect();
    checkStatus.value = 'idle';
    Get.snackbar(
      '已断开',
      '打印机连接已断开',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  /// 测试打印
  Future<void> testPrint() async {
    if (!hasConnectedPrinter) {
      Get.snackbar(
        '提示',
        '请先连接打印机',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final success = await _printerService.testPrint();
    
    if (success) {
      Get.snackbar(
        '打印成功',
        '测试小票已发送到打印机',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        '打印失败',
        '请检查打印机状态和连接',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// 清空日志
  void clearLogs() {
    _printerService.clearLogs();
  }

  @override
  void onClose() {
    // 不在这里断开连接，让服务层管理连接生命周期
    super.onClose();
  }
}