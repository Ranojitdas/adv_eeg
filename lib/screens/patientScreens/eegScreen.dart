// ignore_for_file: must_be_immutable

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter_bluetooth_seria_changed/flutter_bluetooth_serial.dart';
import 'package:toast/toast.dart';
import '../../controllers/patientSideControllers/bluetoothConnection_controller.dart';
import '../../controllers/patientSideControllers/brain_signals_send_data.dart';
import '../../controllers/brain_signal/brain_signal_controller.dart';
import '../../widgets/raw_signal_chart.dart';

class EegScreen extends StatefulWidget {
  EegScreen({super.key});

  @override
  State<EegScreen> createState() => _EegScreenState();
}

class _EegScreenState extends State<EegScreen> with TickerProviderStateMixin {
  String _incomingSignalBuffer = '';

  List<double> _buildLiveSamples(List<double> samples, {int maxPoints = 120}) {
    if (samples.length <= maxPoints) {
      return samples.toList(growable: false);
    }
    return samples.sublist(samples.length - maxPoints);
  }
  
  // Parse streamed EEG chunks safely. Serial chunks can split numbers across packets.
  void _parseAndAddEEGData(String rawDataChunk, BrainSignalsController controller) {
    try {
      print('🧠 [EEG] 🔍 Parsing chunk: "$rawDataChunk" (length: ${rawDataChunk.length})');

      if (rawDataChunk.isEmpty) {
        return;
      }

      _incomingSignalBuffer += rawDataChunk;
      _incomingSignalBuffer = _incomingSignalBuffer
          .replaceAll('\r', ';')
          .replaceAll('\n', ';');

      final hasTerminator = _incomingSignalBuffer.endsWith(';');
      final parts = _incomingSignalBuffer.split(';');

      if (!hasTerminator) {
        _incomingSignalBuffer = parts.removeLast();
      } else {
        _incomingSignalBuffer = '';
        if (parts.isNotEmpty && parts.last.isEmpty) {
          parts.removeLast();
        }
      }

      if (parts.isEmpty) {
        return;
      }

      print('🧠 [EEG] 📝 Complete values in this chunk: $parts');

      int addedCount = 0;
      final parsedBatch = <double>[];
      for (String value in parts) {
        // Stop collecting if we already have 256 data points
        if (controller.dataList.length >= 256) {
          print('🧠 [EEG] ✅ Reached target: 256 data points collected. Stopping data collection.');
          break;
        }
        
        value = value.trim();
        if (value.isNotEmpty && value != '-') {
          try {
            double parsedValue = double.parse(value);
            controller.dataList.add(parsedValue);
            parsedBatch.add(parsedValue);
            addedCount++;
            
            // Only show debug for first 10 data points
            if (controller.dataList.length <= 10) {
              print('🧠 [EEG] ✅ Added value: $parsedValue (Total: ${controller.dataList.length})');
            }
            
            // Show progress every 50 points
            if (controller.dataList.length % 50 == 0) {
              print('🧠 [EEG] 📊 Progress: ${controller.dataList.length}/256 data points collected');
            }
          } catch (e) {
            print('🧠 [EEG] ❌ Failed to parse value: "$value" - Error: $e');
          }
        } else {
          print('🧠 [EEG] ⏭️ Skipping empty/invalid value: "$value"');
        }
      }

      controller.enqueueLiveSamples(parsedBatch);
      
      print('🧠 [EEG] 📊 Parsing complete: Added $addedCount values, Total in list: ${controller.dataList.length}');
    } catch (e) {
      print('🧠 [EEG] 💥 Error parsing EEG data: "$rawDataChunk" - Error: $e');
    }
  }
  
  BluetoothController bluetoothController = Get.put(BluetoothController());
  BrainSignalsController brainSignalsCont = Get.put(BrainSignalsController());
  BrainSignalController brainSignalController = Get.put(BrainSignalController());
  BluetoothConnection? connection;
  StreamSubscription? _dataSubscription;
  bool _predictionInProgress = false;
  DateTime? _analysisStartTime;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          bluetoothController.results.value = [];
          bluetoothController.isDiscovering.value = true;
          bluetoothController.discoverBluetooth();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Connect EEG Device',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              Obx(() => IconButton(
                onPressed: bluetoothController.isDiscovering.value 
                  ? null 
                  : () {
                      bluetoothController.results.value = [];
                      bluetoothController.isDiscovering.value = true;
                      bluetoothController.discoverBluetooth();
                    },
                icon: Icon(
                  Icons.refresh_rounded,
                  color: bluetoothController.isDiscovering.value 
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white,
                  size: 24,
                ),
                tooltip: 'Retry Discovery',
              )),
              const SizedBox(width: 8),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: Obx(
            () => ModalProgressHUD(
              inAsyncCall: bluetoothController.isDiscovering.value ||
                  bluetoothController.connecting.value ||
                  brainSignalsCont.isLoading.value ||
                  brainSignalsCont.isSendingData.value ||
                  brainSignalsCont.isProcessingResults.value ||
                  (bluetoothController.connection.value != null &&
                      bluetoothController.connection.value!.isConnected),
              progressIndicator: Container(
                constraints: const BoxConstraints(
                  maxHeight: 500,
                  maxWidth: 390,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        final displaySamples = brainSignalsCont
                                .liveDisplayData.isNotEmpty
                            ? brainSignalsCont.liveDisplayData.toList()
                            : brainSignalsCont.completedRawSignalTrace.isNotEmpty
                                ? brainSignalsCont.completedRawSignalTrace
                                    .toList()
                                : brainSignalsCont.dataList.toList();

                        if (displaySamples.isNotEmpty) {
                          return RawSignalChart(
                            samples: _buildLiveSamples(displaySamples),
                            title: brainSignalsCont.isProcessingResults.value
                                ? 'Saved Raw EEG Trace'
                                : 'Live Raw EEG Signal',
                            height: 240,
                          );
                        }

                        return const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF0850FD)),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isSmallScreen ? 24.0 : 32.0,
                          size.height * 0.12,
                          isSmallScreen ? 24.0 : 32.0,
                          16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Devices',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select your EEG device from the list below',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Obx(
                        () => Expanded(
                          child: bluetoothController.results.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bluetooth_searching_rounded,
                                        size: 64,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No devices found',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Make sure your EEG device is turned on and in pairing mode',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          bluetoothController.results.value = [];
                                          bluetoothController.isDiscovering.value = true;
                                          bluetoothController.discoverBluetooth();
                                        },
                                        icon: Icon(Icons.refresh, color: Colors.white),
                                        label: Text(
                                          'Retry Discovery',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF0850FD),
                                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Or pull down to refresh',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16.0 : 24.0,
                                  ),
                                  itemCount: bluetoothController.results.length,
                                  itemBuilder: (context, index) =>
                                      _buildDeviceCard(
                                    context,
                                    bluetoothController.results[index],
                                    index,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
      BuildContext context, BluetoothDiscoveryResult result, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            try {
              bluetoothController.connecting.value = true;
              print(
                '🧠 [EEG] Attempting connection to ${result.device.name ?? 'Unknown'} (${result.device.address})',
              );
              final bondState = await FlutterBluetoothSerial.instance
                  .getBondStateForAddress(result.device.address);

              if (!bondState.isBonded) {
                final bonded = await FlutterBluetoothSerial.instance
                    .bondDeviceAtAddress(result.device.address);

                if (bonded != true) {
                  throw Exception(
                      'Device is not bonded. Pair the EEG device first and try again.');
                }
              }

              for (var attempt = 0; attempt < 5; attempt++) {
                final currentBondState = await FlutterBluetoothSerial.instance
                    .getBondStateForAddress(result.device.address);
                if (currentBondState.isBonded) {
                  break;
                }
                await Future.delayed(const Duration(milliseconds: 300));
              }

              await Future.delayed(const Duration(milliseconds: 500));

              connection = await BluetoothConnection.toAddress(
                  result.device.address);
              bluetoothController.connection.value = connection;
              brainSignalsCont.deviceId.value = result.device.address;

              connection!.output.add(ascii.encode('1'));
              bluetoothController.connecting.value = false;

              _showConnectionDialog(context);
            } catch (exception) {
              bluetoothController.connecting.value = false;
              bluetoothController.connection.value = null;
              connection?.dispose();
              connection = null;
              Get.snackbar(
                'Connection Error',
                'Cannot connect to your device. Make sure it is paired and in pairing mode, then try again.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 8,
              );
              print('Cannot connect, exception occurred: $exception');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bluetooth_rounded,
                    color: Color(0xFF0850FD),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.device.name ?? 'Unknown Device',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.device.address,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConnectionDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Connected Successfully',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Please sit with your eyes closed in an isolated environment (preferably). Wear the headband. Make sure the electrodes are in proper contact with the scalp. Data collection will take 15-30 seconds or until 256+ data points are collected. Once you have completed all the setup, please press the start button below.',
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              
              // Reset prediction state and clear any existing data
              _predictionInProgress = false;
              _incomingSignalBuffer = '';
              brainSignalsCont.resetSession();
              _analysisStartTime = DateTime.now();
              print('🧠 [EEG] 🔄 Starting new EEG session - all state reset');
              
              var t = DateTime.now().millisecondsSinceEpoch;
              _dataSubscription = connection!.input?.listen((var data) async {
                // Skip processing if prediction is already in progress
                if (_predictionInProgress) {
                  print('🧠 [EEG] ⏭️ Skipping data - prediction in progress');
                  return;
                }
                
                print('🧠 [EEG] Raw bytes received: $data');
                String rawData = ascii.decode(data);
                print('🧠 [EEG] Decoded data: "$rawData"');

                // Always parse the incoming data first
                int dataCountBefore = brainSignalsCont.dataList.length;
                _parseAndAddEEGData(rawData, brainSignalsCont);
                int dataCountAfter = brainSignalsCont.dataList.length;
                
                print('🧠 [EEG] 📊 Data count: $dataCountBefore → $dataCountAfter (Added: ${dataCountAfter - dataCountBefore})');

                // Check if we have enough data (around 256 points) or 30 seconds passed
                int secondsElapsed = DateTime.now().millisecondsSinceEpoch - t;
                int secondsPassed = (secondsElapsed / 1000).floor();
                
                // Show progress every 2 seconds or when significant data is added
                if (secondsPassed % 2 == 0 || (dataCountAfter - dataCountBefore) > 0) {
                  print('🧠 [EEG] 📈 Progress: ${secondsPassed}s / 30s - Total collected: ${brainSignalsCont.dataList.length} data points');
                }
                
                // Check stopping conditions AFTER parsing data
                if ((brainSignalsCont.dataList.length >= 256 || secondsPassed >= 20) && !_predictionInProgress) {
                  // Set flag to prevent multiple predictions
                  _predictionInProgress = true;
                  brainSignalsCont.completedRawSignalTrace.assignAll(brainSignalsCont.dataList);
                  brainSignalsCont.isProcessingResults.value = true;
                  brainSignalsCont.currentStatus.value = 'Analyzing brain activity...';
                  
                  // Either 256 data points or 30 seconds completed - stop collection and get prediction
                  String reason = brainSignalsCont.dataList.length >= 256 ? 'Target 256+ data points reached' : '30 seconds completed';
                  print('🧠 [EEG] ✅ $reason! Total data collected: ${brainSignalsCont.dataList.length}');
                  print('🧠 [EEG] 🔒 PREDICTION FLAG SET - No more predictions will be processed');
                  
                  // Cancel the subscription to stop receiving more data
                  await _dataSubscription?.cancel();
                  _dataSubscription = null;
                  print('🧠 [EEG] 🛑 Data subscription cancelled - no more data will be processed');
                  
                  // Stop the Bluetooth connection
                  connection!.output.add(ascii.encode('0'));
                  connection!.finish();
                  print('🧠 [EEG] 🔌 Bluetooth connection terminated');
                  
                  // Validate data quality before prediction
                  if (brainSignalsCont.dataList.isNotEmpty && brainSignalsCont.dataList.length >= 256) {
                    print('🧠 [EEG] ✅ Data validation passed: ${brainSignalsCont.dataList.length} points (min 256 required)');
                    print('🧠 [EEG] 📊 Data sample (first 10): ${brainSignalsCont.dataList.take(10).toList()}');
                    print('🧠 [EEG] 🚀 Starting SINGLE prediction request...');
                    
                    // Ensure minimum 20 seconds display time for "Analyzing Your Brain Activity"
                    if (_analysisStartTime != null) {
                      int elapsedSeconds = DateTime.now().difference(_analysisStartTime!).inSeconds;
                      if (elapsedSeconds < 20) {
                        int remainingTime = 20 - elapsedSeconds;
                        print('🧠 [EEG] ⏰ Ensuring minimum 20s display time - waiting ${remainingTime}s more');
                        await Future.delayed(Duration(seconds: remainingTime));
                      }
                    }
                    
                    await brainSignalsCont.getPrediction();
                    
                    print('🧠 [EEG] ✅ PREDICTION COMPLETED - SESSION FINISHED');
                    print('🧠 [EEG] 🔒 Session locked - no more predictions possible');
                  } else {
                    print('🧠 [EEG] ❌ Insufficient data: ${brainSignalsCont.dataList.length} points (need min 256)');
                    print('🧠 [EEG] ⏭️ Skipping prediction due to insufficient data');
                  }
                  
                  // Final cleanup
                  if (ascii.decode(data).contains('!')) {
                    connection!.finish();
                    print('🧠 [EEG] 🔌 Final disconnection by local host');
                  }
                  
                  // Return to prevent any further processing
                  return;
                }
              });
              
              _dataSubscription?.onDone(() {
                print('🧠 [EEG] 🔌 Disconnected by remote request');
                _predictionInProgress = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0850FD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Start',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
