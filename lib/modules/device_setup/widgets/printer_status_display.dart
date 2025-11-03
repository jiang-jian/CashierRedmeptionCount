import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/services/sunmi_printer_service.dart';

/// 打印机状态显示组件
/// 根据不同状态显示不同的UI：
/// - Status.READY（正常）-> 绿色✓
/// - Status.ERR_*（错误）-> 红色✗ 
/// - Status.WARN_*（警告）-> 黄色⚠
class PrinterStatusDisplay extends StatelessWidget {
  final PrinterStatusInfo? statusInfo;
  final bool isChecking;

  const PrinterStatusDisplay({
    super.key,
    this.statusInfo,
    this.isChecking = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return _buildCheckingStatus();
    }

    if (statusInfo == null) {
      return _buildUnknownStatus();
    }

    switch (statusInfo!.status) {
      case PrinterStatus.ready:
        return _buildReadyStatus();
      case PrinterStatus.error:
        return _buildErrorStatus();
      case PrinterStatus.warning:
        return _buildWarningStatus();
      case PrinterStatus.unknown:
        return _buildUnknownStatus();
    }
  }

  /// 检测中状态（蓝色加载）
  Widget _buildCheckingStatus() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF1890FF), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24.w,
            height: 24.h,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1890FF)),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            '正在检测打印机状态...',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1890FF),
            ),
          ),
        ],
      ),
    );
  }

  /// 就绪状态（绿色✓）- Status.READY
  Widget _buildReadyStatus() {
    final detailInfo = statusInfo?.detailInfo;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FFED),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF52C41A), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态标题行
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: const BoxDecoration(
                  color: Color(0xFF52C41A),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 24.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '打印机正常',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF52C41A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '可以进行打印测试',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 打印机详情信息（对应demo的【打印机详情】显示）
          if (detailInfo != null) ...[
            SizedBox(height: 12.h),
            Divider(color: const Color(0xFF52C41A).withValues(alpha: 0.2), height: 1),
            SizedBox(height: 10.h),
            _buildDetailRow('ID', detailInfo.printerId ?? '--'),
            SizedBox(height: 6.h),
            _buildDetailRow('名称', detailInfo.printerName ?? '--'),
            SizedBox(height: 6.h),
            _buildDetailRow('状态', _formatStatusWithChinese(detailInfo.printerStatus ?? '--')),
            SizedBox(height: 6.h),
            _buildDetailRow('类型', detailInfo.printerType ?? '--'),
            SizedBox(height: 6.h),
            _buildDetailRow('规格', detailInfo.printerPaper ?? '--'),
          ],
        ],
      ),
    );
  }
  
  /// 详情行（紧凑版）
  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 42.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF999999),
            ),
          ),
        ),
        Text(
          '：',
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xFF999999),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 错误状态（红色✗）- Status.ERR_*, Status.OFFLINE, Status.COMM
  Widget _buildErrorStatus() {
    final detailInfo = statusInfo?.detailInfo;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE74C3C), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态标题行
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: const BoxDecoration(
                  color: Color(0xFFE74C3C),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cancel,
                  size: 24.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '打印机异常',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE74C3C),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _getErrorMessage(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF666666),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 打印机详情信息（对应demo的【打印机详情】显示）
          if (detailInfo != null) ...[
            SizedBox(height: 12.h),
            Divider(color: const Color(0xFFE74C3C).withValues(alpha: 0.2), height: 1),
            SizedBox(height: 10.h),
            _buildDetailRow('ID', detailInfo.printerId ?? '--'),
            SizedBox(height: 6.h),
            _buildDetailRow('名称', detailInfo.printerName ?? '--'),
            SizedBox(height: 6.h),
            _buildDetailRow('状态', _formatStatusWithChinese(detailInfo.printerStatus ?? '--')),
            SizedBox(height: 6.h),
            _buildDetailRow('类型', detailInfo.printerType ?? '--'),
            SizedBox(height: 6.h),
            _buildDetailRow('规格', detailInfo.printerPaper ?? '--'),
          ],
        ],
      ),
    );
  }

  /// 警告状态（黄色⚠）- Status.WARN_*
  Widget _buildWarningStatus() {
    final detailInfo = statusInfo?.detailInfo;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF39C12), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态标题行
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: const BoxDecoration(
                  color: Color(0xFFF39C12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 24.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '打印机警告',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF39C12),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      statusInfo?.message ?? '打印机有警告信息',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF666666),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 打印机详情信息（对应demo的【打印机详情】显示）
          if (detailInfo != null) ...[
            SizedBox(height: 12.h),
            Divider(color: const Color(0xFFF39C12).withValues(alpha: 0.2), height: 1),
            SizedBox(height: 10.h),
            _buildDetailRow('ID', detailInfo.printerId ?? '--'),
            SizedBox(height: 6.h),
            _buildDetailRow('名称', detailInfo.printerName ?? '--'),
            SizedBox(height: 6.h),
            _buildDetailRow('状态', _formatStatusWithChinese(detailInfo.printerStatus ?? '--')),
            SizedBox(height: 6.h),
            _buildDetailRow('类型', detailInfo.printerType ?? '--'),
            SizedBox(height: 6.h),
            _buildDetailRow('规格', detailInfo.printerPaper ?? '--'),
          ],
        ],
      ),
    );
  }

  /// 未知状态（灰色？）
  Widget _buildUnknownStatus() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56.w,
            height: 56.h,
            decoration: const BoxDecoration(
              color: Color(0xFF999999),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.help_outline,
              size: 32.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 20.w),
          Text(
            '未检测到打印机',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取错误消息（根据不同错误类型返回详细说明）
  String _getErrorMessage() {
    final message = statusInfo?.message ?? '打印机发生错误';
    final rawStatus = statusInfo?.rawStatus ?? '';

    if (rawStatus.contains('PAPER_OUT') || message.contains('缺纸')) {
      return '打印机缺纸，请补充打印纸';
    } else if (rawStatus.contains('PAPER_JAM') || message.contains('堵纸')) {
      return '打印机堵纸，请检查纸张';
    } else if (rawStatus.contains('PAPER_MISMATCH')) {
      return '打印纸不匹配打印机';
    } else if (rawStatus.contains('OFFLINE')) {
      return '打印机离线或故障';
    } else if (rawStatus.contains('COMM')) {
      return '打印机通信异常';
    }

    return message;
  }

  /// 格式化状态显示，添加中文说明
  /// 格式：英文状态(中文说明)
  String _formatStatusWithChinese(String englishStatus) {
    if (englishStatus == '--' || englishStatus.isEmpty) {
      return '--';
    }

    final upperStatus = englishStatus.toUpperCase();
    String chineseDescription = '';

    // 根据英文状态添加对应的中文说明
    if (upperStatus.contains('READY')) {
      chineseDescription = '准备就绪';
    } else if (upperStatus.contains('ERR_PAPER_OUT') || upperStatus.contains('PAPER_OUT')) {
      chineseDescription = '缺纸错误';
    } else if (upperStatus.contains('ERR_PAPER_JAM') || upperStatus.contains('PAPER_JAM')) {
      chineseDescription = '卡纸错误';
    } else if (upperStatus.contains('ERR_PAPER_MISMATCH') || upperStatus.contains('PAPER_MISMATCH')) {
      chineseDescription = '纸张不匹配错误';
    } else if (upperStatus.contains('OFFLINE')) {
      chineseDescription = '设备离线';
    } else if (upperStatus.contains('COMM')) {
      chineseDescription = '通信异常';
    } else if (upperStatus.startsWith('ERR_')) {
      chineseDescription = '设备错误';
    } else if (upperStatus.startsWith('WARN_') || upperStatus.contains('WARNING')) {
      chineseDescription = '设备警告';
    } else if (upperStatus.contains('UNKNOWN')) {
      chineseDescription = '状态未知';
    } else if (upperStatus.contains('BUSY')) {
      chineseDescription = '设备忙碌';
    } else if (upperStatus.contains('STANDBY')) {
      chineseDescription = '待机状态';
    } else {
      // 对于未识别的状态，不添加中文说明
      return englishStatus;
    }

    return '$englishStatus($chineseDescription)';
  }
}
