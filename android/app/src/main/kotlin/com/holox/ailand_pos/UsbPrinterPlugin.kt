package com.holox.ailand_pos

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.charset.StandardCharsets

/**
 * USB打印机插件
 * 
 * 功能：
 * - 扫描USB打印机设备
 * - 连接和断开USB设备
 * - 发送打印数据
 * - 监听USB设备插拔事件
 */
class UsbPrinterPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var usbManager: UsbManager
    
    private var currentDevice: UsbDevice? = null
    private var currentConnection: UsbDeviceConnection? = null
    
    companion object {
        private const val CHANNEL_NAME = "com.ailand.pos/usb_printer"
        private const val ACTION_USB_PERMISSION = "com.ailand.pos.USB_PERMISSION"
        
        // 常见打印机厂商VID列表
        private val PRINTER_VENDOR_IDS = setOf(
            0x04b8, // Epson
            0x03f0, // HP
            0x04a9, // Canon
            0x04f9, // Brother
            0x04e8, // Samsung
            0x0a5f, // Zebra
            0x0519, // Star Micronics
            0x0483, // Generic USB-Serial
            0x1a86, // QinHeng Electronics (CH340/CH341)
        )
    }
    
    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                ACTION_USB_PERMISSION -> {
                    synchronized(this) {
                        val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                        }
                        
                        if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                            device?.let {
                                log("USB权限已授予: ${it.deviceName}")
                            }
                        } else {
                            log("USB权限被拒绝")
                        }
                    }
                }
                UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                    val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    }
                    
                    device?.let {
                        log("USB设备已连接: ${it.deviceName}")
                        channel.invokeMethod("onUsbDeviceAttached", mapOf(
                            "deviceId" to it.deviceName
                        ))
                    }
                }
                UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                    val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    }
                    
                    device?.let {
                        log("USB设备已断开: ${it.deviceName}")
                        if (currentDevice?.deviceName == it.deviceName) {
                            disconnect()
                        }
                        channel.invokeMethod("onUsbDeviceDetached", mapOf(
                            "deviceId" to it.deviceName
                        ))
                    }
                }
            }
        }
    }
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
        
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        
        // 注册USB事件监听
        val filter = IntentFilter().apply {
            addAction(ACTION_USB_PERMISSION)
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(usbReceiver, filter)
        }
        
        log("USB打印机插件已初始化")
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        try {
            context.unregisterReceiver(usbReceiver)
        } catch (e: Exception) {
            log("注销USB监听器失败: ${e.message}")
        }
        disconnect()
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanDevices" -> scanDevices(result)
            "connectDevice" -> {
                val deviceId = call.argument<String>("deviceId")
                if (deviceId != null) {
                    connectDevice(deviceId, result)
                } else {
                    result.error("INVALID_ARGUMENT", "设备ID不能为空", null)
                }
            }
            "disconnectDevice" -> {
                disconnect()
                result.success(true)
            }
            "printText" -> {
                val content = call.argument<String>("content")
                if (content != null) {
                    printText(content, result)
                } else {
                    result.error("INVALID_ARGUMENT", "打印内容不能为空", null)
                }
            }
            else -> result.notImplemented()
        }
    }
    
    /**
     * 扫描USB设备
     */
    private fun scanDevices(result: Result) {
        try {
            val deviceList = usbManager.deviceList
            val printers = mutableListOf<Map<String, Any>>()
            
            deviceList.values.forEach { device ->
                if (isPrinterDevice(device)) {
                    printers.add(mapOf(
                        "deviceId" to device.deviceName,
                        "deviceName" to (device.deviceName ?: "未知设备"),
                        "vendorId" to device.vendorId,
                        "productId" to device.productId,
                        "manufacturer" to (device.manufacturerName ?: "未知制造商"),
                        "productName" to (device.productName ?: "未知产品")
                    ))
                    log("发现打印机: ${device.deviceName} [VID:0x${device.vendorId.toString(16)}, PID:0x${device.productId.toString(16)}]")
                }
            }
            
            log("扫描完成，共检测到 ${printers.size} 台打印机")
            result.success(printers)
        } catch (e: Exception) {
            log("扫描设备失败: ${e.message}")
            result.error("SCAN_FAILED", e.message, null)
        }
    }
    
    /**
     * 判断是否为打印机设备
     */
    private fun isPrinterDevice(device: UsbDevice): Boolean {
        // 检查VID是否在打印机厂商列表中
        if (PRINTER_VENDOR_IDS.contains(device.vendorId)) {
            return true
        }
        
        // 检查设备类型（打印机类为7）
        for (i in 0 until device.interfaceCount) {
            val usbInterface = device.getInterface(i)
            if (usbInterface.interfaceClass == UsbConstants.USB_CLASS_PRINTER) {
                return true
            }
        }
        
        return false
    }
    
    /**
     * 连接到指定设备
     */
    private fun connectDevice(deviceId: String, result: Result) {
        try {
            val deviceList = usbManager.deviceList
            val device = deviceList.values.find { it.deviceName == deviceId }
            
            if (device == null) {
                result.error("DEVICE_NOT_FOUND", "未找到设备: $deviceId", null)
                return
            }
            
            // 检查权限
            if (!usbManager.hasPermission(device)) {
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_MUTABLE
                } else {
                    0
                }
                val permissionIntent = PendingIntent.getBroadcast(
                    context,
                    0,
                    Intent(ACTION_USB_PERMISSION),
                    flags
                )
                usbManager.requestPermission(device, permissionIntent)
                result.error("PERMISSION_REQUIRED", "需要USB权限", null)
                return
            }
            
            // 打开设备连接
            val connection = usbManager.openDevice(device)
            if (connection == null) {
                result.error("CONNECT_FAILED", "无法打开设备连接", null)
                return
            }
            
            // 保存当前连接
            currentDevice = device
            currentConnection = connection
            
            log("✅ 设备连接成功: ${device.deviceName}")
            result.success(true)
        } catch (e: Exception) {
            log("连接设备失败: ${e.message}")
            result.error("CONNECT_FAILED", e.message, null)
        }
    }
    
    /**
     * 断开当前设备
     */
    private fun disconnect() {
        currentConnection?.close()
        currentConnection = null
        currentDevice = null
        log("设备已断开")
    }
    
    /**
     * 打印文本内容
     */
    private fun printText(content: String, result: Result) {
        if (currentConnection == null || currentDevice == null) {
            result.error("NOT_CONNECTED", "设备未连接", null)
            return
        }
        
        try {
            val device = currentDevice!!
            val connection = currentConnection!!
            
            // 查找批量输出端点
            var endpoint: android.hardware.usb.UsbEndpoint? = null
            for (i in 0 until device.interfaceCount) {
                val usbInterface = device.getInterface(i)
                for (j in 0 until usbInterface.endpointCount) {
                    val ep = usbInterface.getEndpoint(j)
                    if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                        ep.direction == UsbConstants.USB_DIR_OUT) {
                        endpoint = ep
                        break
                    }
                }
                if (endpoint != null) break
            }
            
            if (endpoint == null) {
                result.error("NO_ENDPOINT", "未找到输出端点", null)
                return
            }
            
            // 转换为字节数据
            val data = content.toByteArray(StandardCharsets.UTF_8)
            
            // 发送数据
            val bytesWritten = connection.bulkTransfer(endpoint, data, data.size, 5000)
            
            if (bytesWritten < 0) {
                result.error("PRINT_FAILED", "数据传输失败", null)
                return
            }
            
            log("✅ 打印成功，发送 $bytesWritten 字节")
            result.success(true)
        } catch (e: Exception) {
            log("打印失败: ${e.message}")
            result.error("PRINT_FAILED", e.message, null)
        }
    }
    
    /**
     * 日志输出
     */
    private fun log(message: String) {
        println("[UsbPrinterPlugin] $message")
    }
}