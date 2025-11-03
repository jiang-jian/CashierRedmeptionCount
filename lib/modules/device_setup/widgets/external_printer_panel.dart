import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../data/models/external_printer_info.dart';
import '../controllers/external_printer_controller.dart';

/// 外接打印机面板组件
/// 
/// 显示在打印机配置页右侧，用于：
/// - 展示检测到的外接打印机列表
/// - 显示当前连接状态
/// - 提供连接、断开、测试打印操作
/// 
/// 完全独立的UI组件，遵循组件化原则
class ExternalPrinterPanel extends StatelessWidget {
  const ExternalPrinterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExternalPrinterController());

    return Container(
      height: 420.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          _buildHeader(controller),
          
          Divider(height: 1.h, color: const Color(0xFFE0E0E0)),
          
          // 设备列表区域
          Expanded(
            child: Obx(() => _buildDeviceList(controller)),
          ),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(ExternalPrinterController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(
            Icons.usb,
            size: 20.sp,
            color: const Color(0xFF1890FF),
          ),
          SizedBox(width: 8.w),
          Text(
            '外接打印机',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const Spacer(),
          // 扫描按钮
          Obx(() => IconButton(
            onPressed: controller.isScanning ? null : controller.scanDevices,
            icon: controller.isScanning
                ? SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh, size: 20.sp),
            tooltip: '扫描设备',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: 32.w,
              minHeight: 32.h,
            ),
          )),
        ],
      ),
    );
  }

  /// 构建设备列表
  Widget _buildDeviceList(ExternalPrinterController controller) {
    if (controller.isScanning) {
      return _buildLoadingState();
    }

    if (controller.printers.isEmpty) {
      return _buildEmptyState(controller);
    }

    return ListView.separated(
      padding: EdgeInsets.all(12.w),
      itemCount: controller.printers.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, index) {
        final printer = controller.printers[index];
        final isConnected = controller.currentPrinter?.deviceId == printer.deviceId;
        return _buildDeviceCard(controller, printer, isConnected);
      },
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            '正在扫描USB设备...',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(ExternalPrinterController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.usb_off,
            size: 64.sp,
            color: const Color(0xFFBDBDBD),
          ),
          SizedBox(height: 16.h),
          Text(
            '未检测到外接打印机',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '请连接USB打印机后点击刷新',
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF999999),
            ),
          ),
          SizedBox(height: 24.h),
          OutlinedButton.icon(
            onPressed: controller.scanDevices,
            icon: Icon(Icons.refresh, size: 18.sp),
            label: Text(
              '重新扫描',
              style: TextStyle(fontSize: 14.sp),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1890FF),
              side: const BorderSide(color: Color(0xFF1890FF)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设备卡片
  Widget _buildDeviceCard(
    ExternalPrinterController controller,
    ExternalPrinterInfo printer,
    bool isConnected,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFFE6F7FF) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isConnected ? const Color(0xFF1890FF) : const Color(0xFFE0E0E0),
          width: isConnected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 设备名称和状态
          Row(
            children: [
              Expanded(
                child: Text(
                  printer.deviceName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isConnected)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF52C41A),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    '已连接',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // 设备详情
          if (printer.manufacturer != null)
            _buildInfoRow('制造商', printer.manufacturer!),
          
          _buildInfoRow(
            'VID:PID',
            '0x${printer.vendorId.toRadixString(16).toUpperCase()}:'
            '0x${printer.productId.toRadixString(16).toUpperCase()}',
          ),
          
          _buildInfoRow('接口', printer.interfaceType),
          
          _buildInfoRow(
            '状态',
            '${printer.status.name}(${printer.status.chineseDescription})',
          ),
          
          SizedBox(height: 12.h),
          
          // 操作按钮
          Row(
            children: [
              if (!isConnected)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.connectPrinter(printer),
                    icon: Icon(Icons.link, size: 16.sp),
                    label: Text(
                      '连接',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1890FF),
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 36.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                    ),
                  ),
                ),
              
              if (isConnected) ..[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.disconnectPrinter,
                    icon: Icon(Icons.link_off, size: 16.sp),
                    label: Text(
                      '断开',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4D4F),
                      side: const BorderSide(color: Color(0xFFFF4D4F)),
                      minimumSize: Size(0, 36.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Obx(() => ElevatedButton.icon(
                    onPressed: controller.isPrinting ? null : controller.testPrint,
                    icon: controller.isPrinting
                        ? SizedBox(
                            width: 14.w,
                            height: 14.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.print, size: 16.sp),
                    label: Text(
                      controller.isPrinting ? '打印中' : '测试',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5B544),
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 36.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                    ),
                  )),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 60.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF999999),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}