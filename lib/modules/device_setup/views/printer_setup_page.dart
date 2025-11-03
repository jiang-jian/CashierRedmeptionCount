import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/device_setup_controller.dart';
import '../../../data/services/sunmi_printer_service.dart';
import '../widgets/device_setup_layout.dart';
import '../widgets/printer_status_display.dart';

/// 打印机设置页面 - 重新设计布局
/// 左侧：操作提示和状态
/// 右侧：调试日志
class PrinterSetupPage extends GetView<DeviceSetupController> {
  const PrinterSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceSetupLayout(
      currentStep: 3,
      title: '打印机',
      statusSection: Obx(() => _buildMainContent()),
      instructionsSection: const SizedBox.shrink(),
      actionButtons: const SizedBox.shrink(),
      recognitionStatus: Obx(() => _buildRecognitionStatus()),
      bottomButtons: Obx(() => _buildBottomButtons()),
    );
  }

  /// 主内容区域 - 三栏布局
  Widget _buildMainContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧：操作提示区域（25%宽度）
        Expanded(
          flex: 25,
          child: _buildInstructionsPanel(),
        ),
        
        SizedBox(width: 16.w),
        
        // 中间：打印机状态检测和测试区域（45%宽度）
        Expanded(
          flex: 45,
          child: _buildCenterPanel(),
        ),
        
        SizedBox(width: 16.w),
        
        // 右侧：调试日志区域（30%宽度）
        Expanded(
          flex: 30,
          child: _buildDebugLogPanel(),
        ),
      ],
    );
  }

  /// 左侧面板：操作提示
  Widget _buildInstructionsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInstructions(),
      ],
    );
  }

  /// 中间面板：打印机状态检测和测试区域
  Widget _buildCenterPanel() {
    final printerService = Get.find<SunmiPrinterService>();
    final checkStatus = controller.printerCheckStatus.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 打印机状态显示
        PrinterStatusDisplay(
          statusInfo: printerService.printerStatus.value,
          isChecking: checkStatus == 'checking',
        ),
        
        SizedBox(height: 16.h),
        
        // 操作按钮
        _buildActionButtons(),
      ],
    );
  }

  /// 右侧面板：调试日志
  Widget _buildDebugLogPanel() {
    final printerService = Get.find<SunmiPrinterService>();

    return Container(
      height: 420.h, // 与左侧面板保持相同高度
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 18.sp,
                  color: const Color(0xFF4EC9B0),
                ),
                SizedBox(width: 8.w),
                Text(
                  'SDK调试日志',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    printerService.debugLogs.clear();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3E3E),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.clear_all,
                          size: 14.sp,
                          color: const Color(0xFFCCCCCC),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '清空',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFFCCCCCC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 日志内容
          Expanded(
            child: Obx(() {
              final logs = printerService.debugLogs;
              
              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48.sp,
                        color: const Color(0xFF666666),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        '暂无日志\n点击"重新检测"或"测试打印"查看SDK调用日志',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: EdgeInsets.all(12.w),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final isError = log.contains('✗') || log.contains('错误');
                  final isSuccess = log.contains('✓');
                  final isSeparator = log.contains('=====');
                  
                  Color textColor = const Color(0xFFCCCCCC);
                  if (isError) {
                    textColor = const Color(0xFFF48771);
                  } else if (isSuccess) {
                    textColor = const Color(0xFF4EC9B0);
                  } else if (isSeparator) {
                    textColor = const Color(0xFF569CD6);
                  }
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: 'monospace',
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 操作提示（左侧独立面板）
  Widget _buildInstructions() {
    return Container(
      height: 420.h, // 与右侧日志区域保持相同高度
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF1890FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18.sp,
                color: const Color(0xFF1890FF),
              ),
              SizedBox(width: 8.w),
              Text(
                '操作提示',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1890FF),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          
          // 操作步骤
          _buildInstructionItem('1', '自动检测打印机状态'),
          SizedBox(height: 12.h),
          _buildInstructionItem('2', '状态正常后点击测试打印'),
          SizedBox(height: 12.h),
          _buildInstructionItem('3', '右侧日志显示SDK调用详情'),
          
          SizedBox(height: 24.h),
          
          // 注意事项
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16.sp,
                      color: const Color(0xFFF39C12),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '注意事项',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF39C12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '• 确保打印机已连接电源\n• 检查打印纸是否装好\n• 测试成功后可进行下一步',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.w,
          height: 20.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1890FF),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF333333),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// 操作按钮（紧凑版）
  Widget _buildActionButtons() {
    final checkStatus = controller.printerCheckStatus.value;
    final testStatus = controller.printerTestStatus.value;
    final isPrinterReady = checkStatus == 'ready';
    final isTesting = testStatus == 'testing';

    return Column(
      children: [
        // 重新检测按钮
        if (checkStatus == 'error' || checkStatus == 'warning' || checkStatus == 'ready')
          Container(
            margin: EdgeInsets.only(bottom: 12.h),
            width: double.infinity,
            height: 48.h, // 增加按钮高度
            child: OutlinedButton.icon(
              onPressed: checkStatus == 'checking' ? null : controller.checkPrinterStatus,
              icon: Icon(Icons.refresh, size: 18.sp),
              label: Text(
                '重新检测',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1890FF),
                side: const BorderSide(color: Color(0xFF1890FF), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
            ),
          ),

        // 测试打印按钮（只有打印机正常时才开放）
        SizedBox(
          width: double.infinity,
          height: 52.h, // 增加按钮高度
          child: ElevatedButton.icon(
            onPressed: isPrinterReady && !isTesting
                ? controller.testPrintReceipt
                : null,
            icon: isTesting
                ? SizedBox(
                    width: 18.w,
                    height: 18.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.print, size: 20.sp),
            label: Text(
              isTesting ? '正在打印...' : '测试打印',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPrinterReady ? const Color(0xFFE5B544) : const Color(0xFFE0E0E0),
              foregroundColor: isPrinterReady ? Colors.white : const Color(0xFF999999),
              disabledBackgroundColor: const Color(0xFFE0E0E0),
              disabledForegroundColor: const Color(0xFF999999),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              elevation: 0,
            ),
          ),
        ),
        
        // 状态提示
        if (!isPrinterReady && checkStatus != 'checking')
          Container(
            margin: EdgeInsets.only(top: 8.h),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: const Color(0xFFF39C12).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14.sp,
                  color: const Color(0xFFF39C12),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '请先确保打印机状态正常',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFFF39C12),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 错误提示
        if (controller.errorMessage.value.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 8.h),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F0),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14.sp,
                  color: const Color(0xFFE74C3C),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFFE74C3C),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 识别状态（测试成功后显示）
  Widget _buildRecognitionStatus() {
    final testStatus = controller.printerTestStatus.value;

    if (testStatus != 'success') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          width: 56.w,
          height: 56.h,
          decoration: const BoxDecoration(
            color: Color(0xFF52C41A),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, size: 32.sp, color: Colors.white),
        ),
        SizedBox(height: 12.h),
        Text(
          '测试通过',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF52C41A),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '打印机配置成功',
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// 底部按钮
  Widget _buildBottomButtons() {
    final isCompleted = controller.printerCompleted.value;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600.w),
        child: Column(
          children: [
            // 下一步按钮
            SizedBox(
              width: double.infinity,
              height: 52.h, // 增加按钮高度
              child: ElevatedButton(
                onPressed: isCompleted ? controller.completeSetup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5B544),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  disabledForegroundColor: const Color(0xFF999999),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                  elevation: 0,
                ),
                child: Text(
                  '下一步',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // 稍后设置链接
            TextButton(
              onPressed: controller.skipCurrentStep,
              child: Text(
                '稍后设置"硬件"',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF1890FF),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
