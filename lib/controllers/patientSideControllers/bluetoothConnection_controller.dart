import 'dart:async';
// import 'dart:io';

import 'package:flutter_bluetooth_seria_changed/flutter_bluetooth_serial.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class BluetoothController extends GetxController {
  static const Duration _discoveryTimeout = Duration(seconds: 15);

  @override
  void dispose() {
    _discoveryTimeoutTimer?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
    isDiscovering.value = false;
  }

  // ToastContext().init(context);
  @override
  void onInit() async {
    super.onInit();
    await checkAndRequestBluetoothPermissions();
    if (hasBluetoothPermission.value) {
      discoverBluetooth();
    }
    print(results);
  }

  RxList<String> devices = <String>[].obs;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  Timer? _discoveryTimeoutTimer;
  var results = <BluetoothDiscoveryResult>[].obs;
  var isDiscovering = false.obs;
  var connecting = false.obs;
  var connection=Rxn<BluetoothConnection>();
  var hasBluetoothPermission = false.obs;
  var permissionCheckCompleted = false.obs;

  /// Check and request all necessary Bluetooth permissions
  Future<void> checkAndRequestBluetoothPermissions() async {
    print('🔐 [BLUETOOTH] Checking permissions...');
    
    try {
      // Check if Bluetooth is available
      final isAvailable = await FlutterBluetoothSerial.instance.isAvailable;
      if (isAvailable != true) {
        print('❌ [BLUETOOTH] Bluetooth not available on this device');
        _showPermissionError('Bluetooth not available', 'This device does not support Bluetooth functionality.');
        permissionCheckCompleted.value = true;
        return;
      }

      // Check multiple permissions
      Map<Permission, PermissionStatus> permissions = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      print('🔐 [BLUETOOTH] Permission results:');
      permissions.forEach((permission, status) {
        print('  ${permission.toString()}: ${status.toString()}');
      });

      // Check if all critical permissions are granted
      // Note: Permission.bluetooth might be denied on newer Android versions, but specific bluetooth permissions work
      bool bluetoothGranted = permissions[Permission.bluetoothConnect]?.isGranted == true &&
                             permissions[Permission.bluetoothScan]?.isGranted == true;
      bool locationGranted = permissions[Permission.location]?.isGranted == true || 
                            permissions[Permission.locationWhenInUse]?.isGranted == true;
      
      bool allGranted = bluetoothGranted && locationGranted;

      hasBluetoothPermission.value = allGranted;
      permissionCheckCompleted.value = true;

      if (!allGranted) {
        print('❌ [BLUETOOTH] Some permissions denied - Bluetooth: $bluetoothGranted, Location: $locationGranted');
        _showPermissionGuidance();
      } else {
        print('✅ [BLUETOOTH] All permissions granted - Bluetooth: $bluetoothGranted, Location: $locationGranted');
      }
    } catch (e) {
      print('❌ [BLUETOOTH] Error checking permissions: $e');
      hasBluetoothPermission.value = false;
      permissionCheckCompleted.value = true;
      _showPermissionError('Permission Error', 'Failed to check Bluetooth permissions. Please try again.');
    }
  }

  /// Show permission guidance dialog
  void _showPermissionGuidance() {
    Get.dialog(
      Builder(
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(
              'Bluetooth Permissions Required',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To use EEG functionality, please grant the following permissions:',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 12),
                _buildPermissionItem('📱', 'Bluetooth', 'Connect to EEG devices'),
                _buildPermissionItem('🔍', 'Nearby Devices', 'Scan for EEG devices'),
                _buildPermissionItem('📍', 'Location', 'Required for Bluetooth scanning'),
                SizedBox(height: 16),
                Text(
                  'Steps to enable:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Go to Settings > Apps > ADDvEEG\n2. Tap Permissions\n3. Enable Bluetooth and Location\n4. Return to app and try again',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Open Settings'),
              ),
            ],
          );
        },
      ),
      barrierDismissible: true,
    );
  }

  /// Build permission item widget
  Widget _buildPermissionItem(String icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(description, style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show permission error dialog
  void _showPermissionError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 5),
    );
  }

  /// Check if ready for EEG operations
  bool get isReadyForEEG => hasBluetoothPermission.value && permissionCheckCompleted.value;

  void _stopDiscovery() {
    _discoveryTimeoutTimer?.cancel();
    _discoveryTimeoutTimer = null;
    isDiscovering.value = false;
  }

  void discoverBluetooth() async {
    if (!hasBluetoothPermission.value) {
      print('❌ [BLUETOOTH] Cannot start discovery - permissions not granted');
      _stopDiscovery();
      _showPermissionGuidance();
      return;
    }

    results.clear();
    isDiscovering.value = true;
    print('🔍 [BLUETOOTH] Starting device discovery...');
    final startTime = DateTime.now();

    _discoveryTimeoutTimer?.cancel();
    _discoveryTimeoutTimer = Timer(_discoveryTimeout, () async {
      print('⏱️ [BLUETOOTH] Discovery timeout reached after ${_discoveryTimeout.inSeconds}s');
      try {
        await _streamSubscription?.cancel();
      } catch (_) {}
      _stopDiscovery();
      print('📱 [BLUETOOTH] Discovery stopped by timeout. Found ${results.length} devices total');
    });
    
    try {
      _streamSubscription =
          FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        print('📱 [BLUETOOTH] Found device: ${r.device.name ?? 'Unknown'} (${r.device.address})');
        final existingIndex = results
            .indexWhere((element) => element.device.address == r.device.address);
        if (existingIndex >= 0) {
          results[existingIndex] = r;
        } else {
          results.add(r);
        }
      });

      _streamSubscription!.onDone(() {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        _stopDiscovery();
        print('✅ [BLUETOOTH] Discovery completed in ${duration.inSeconds}s (${duration.inMilliseconds}ms)');
        print('📱 [BLUETOOTH] Found ${results.length} devices total');
      });
    } catch (e) {
      print('❌ [BLUETOOTH] Discovery error: $e');
      _stopDiscovery();
      _showPermissionError('Discovery Failed', 'Failed to scan for devices. Please check permissions and try again.');
    }
    print(results);
  }
}
