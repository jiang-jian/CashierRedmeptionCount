/// 外接打印机设备信息模型
/// 
/// 完全独立于内置打印机，用于管理USB外接打印机设备
class ExternalPrinterInfo {
  /// 设备ID
  final String deviceId;
  
  /// 设备名称
  final String deviceName;
  
  /// 制造商名称
  final String? manufacturer;
  
  /// 产品型号
  final String? productName;
  
  /// 供应商ID (VID)
  final int vendorId;
  
  /// 产品ID (PID)
  final int productId;
  
  /// 设备接口类型
  final String interfaceType;
  
  /// 设备状态
  final ExternalPrinterStatus status;
  
  /// 是否已连接
  final bool isConnected;
  
  /// 最后更新时间
  final DateTime lastUpdateTime;
  
  /// 错误信息（如果有）
  final String? errorMessage;

  ExternalPrinterInfo({
    required this.deviceId,
    required this.deviceName,
    this.manufacturer,
    this.productName,
    required this.vendorId,
    required this.productId,
    this.interfaceType = 'USB',
    this.status = ExternalPrinterStatus.unknown,
    this.isConnected = false,
    DateTime? lastUpdateTime,
    this.errorMessage,
  }) : lastUpdateTime = lastUpdateTime ?? DateTime.now();

  /// 从USB设备信息创建
  factory ExternalPrinterInfo.fromUsbDevice({
    required String deviceId,
    required int vid,
    required int pid,
    String? manufacturer,
    String? product,
    bool connected = false,
  }) {
    return ExternalPrinterInfo(
      deviceId: deviceId,
      deviceName: product ?? '外接打印机',
      manufacturer: manufacturer,
      productName: product,
      vendorId: vid,
      productId: pid,
      interfaceType: 'USB',
      isConnected: connected,
      status: connected ? ExternalPrinterStatus.ready : ExternalPrinterStatus.disconnected,
    );
  }

  /// 复制并更新部分字段
  ExternalPrinterInfo copyWith({
    String? deviceId,
    String? deviceName,
    String? manufacturer,
    String? productName,
    int? vendorId,
    int? productId,
    String? interfaceType,
    ExternalPrinterStatus? status,
    bool? isConnected,
    DateTime? lastUpdateTime,
    String? errorMessage,
  }) {
    return ExternalPrinterInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      manufacturer: manufacturer ?? this.manufacturer,
      productName: productName ?? this.productName,
      vendorId: vendorId ?? this.vendorId,
      productId: productId ?? this.productId,
      interfaceType: interfaceType ?? this.interfaceType,
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 转换为Map（用于日志记录）
  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'manufacturer': manufacturer,
      'productName': productName,
      'vendorId': '0x${vendorId.toRadixString(16).toUpperCase()}',
      'productId': '0x${productId.toRadixString(16).toUpperCase()}',
      'interfaceType': interfaceType,
      'status': status.name,
      'isConnected': isConnected,
      'lastUpdateTime': lastUpdateTime.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return 'ExternalPrinterInfo{'
        'deviceName: $deviceName, '
        'manufacturer: $manufacturer, '
        'VID: 0x${vendorId.toRadixString(16)}, '
        'PID: 0x${productId.toRadixString(16)}, '
        'status: ${status.name}, '
        'connected: $isConnected}'
    ;
  }
}

/// 外接打印机状态枚举
enum ExternalPrinterStatus {
  /// 未知状态
  unknown,
  
  /// 准备就绪
  ready,
  
  /// 打印中
  printing,
  
  /// 缺纸
  paperOut,
  
  /// 卡纸
  paperJam,
  
  /// 打印机离线
  offline,
  
  /// 已断开连接
  disconnected,
  
  /// 通信错误
  communicationError,
  
  /// 其他错误
  error;

  /// 获取状态的中文描述
  String get chineseDescription {
    switch (this) {
      case ExternalPrinterStatus.unknown:
        return '状态未知';
      case ExternalPrinterStatus.ready:
        return '准备就绪';
      case ExternalPrinterStatus.printing:
        return '打印中';
      case ExternalPrinterStatus.paperOut:
        return '缺纸';
      case ExternalPrinterStatus.paperJam:
        return '卡纸';
      case ExternalPrinterStatus.offline:
        return '离线';
      case ExternalPrinterStatus.disconnected:
        return '已断开';
      case ExternalPrinterStatus.communicationError:
        return '通信错误';
      case ExternalPrinterStatus.error:
        return '设备错误';
    }
  }

  /// 是否为错误状态
  bool get isError {
    return this == ExternalPrinterStatus.paperOut ||
        this == ExternalPrinterStatus.paperJam ||
        this == ExternalPrinterStatus.offline ||
        this == ExternalPrinterStatus.communicationError ||
        this == ExternalPrinterStatus.error;
  }

  /// 是否可以打印
  bool get canPrint {
    return this == ExternalPrinterStatus.ready;
  }
}