// ignore_for_file: must_be_immutable

import 'package:ADDvEEG/controllers/patientSideControllers/bluetoothConnection_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/patientSideControllers/brain_signals_send_data.dart';
import '../../controllers/brain_signal/brain_signal_controller.dart';

class CollectingData extends StatefulWidget {
  CollectingData({
    super.key,
  });

  @override
  State<CollectingData> createState() => _CollectingDataState();
}

class _CollectingDataState extends State<CollectingData>
    with SingleTickerProviderStateMixin {
  BrainSignalsController brainSignalsController =
      Get.put(BrainSignalsController());
  BluetoothController bluetoothController = Get.put(BluetoothController());
  BrainSignalController brainSignalController = Get.put(BrainSignalController());

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isCollecting = false;
  String _sessionId = '';
  int _collectionDuration = 30; // 30 seconds default

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });

    _controller.forward();
    _startDataCollection();
  }

  void _startDataCollection() async {
    setState(() {
      _isCollecting = true;
    });

    // Update brain signals controller state
    brainSignalsController.isCollectingData.value = true;
    brainSignalsController.currentStatus.value = 'Starting data collection...';

    // Start EEG data collection session
    final success = await brainSignalController.startDataCollection(
      deviceId: 'EEG_DEVICE_001',
      sessionName: 'Patient EEG Session',
    );
    
    if (success) {
      _sessionId = brainSignalController.currentSessionId.value;
      brainSignalsController.currentStatus.value = 'Collecting brain signals...';
      
      // Simulate data collection for the specified duration
      _simulateDataCollection();
    }
  }

  void _simulateDataCollection() async {
    // Generate and store simulated EEG data
    await brainSignalController.simulateEEGData(
      deviceId: 'EEG_DEVICE_001',
      durationSeconds: _collectionDuration,
    );
    
    // Stop collection session
    await brainSignalController.stopDataCollection();
    
    setState(() {
      _isCollecting = false;
    });

    // Navigate back or show completion
    Get.back();
    Get.snackbar(
      'Collection Complete',
      'EEG data has been successfully collected and stored',
      backgroundColor: const Color(0xFF0850FD),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 24.0 : 32.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.psychology_rounded,
                          size: 60,
                          color: const Color(0xFF0850FD),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              Obx(() => Text(
                brainSignalsController.isCollectingData.value 
                    ? 'Collecting Brain Data' 
                    : brainSignalsController.isSendingData.value
                        ? 'Sending for Analysis'
                        : brainSignalsController.isProcessingResults.value
                            ? 'Processing Results'
                            : _isCollecting 
                                ? 'Scanning Brain Signals' 
                                : 'Preparing EEG Collection',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                ),
              )),
              const SizedBox(height: 16),
              Obx(() => Text(
                brainSignalsController.currentStatus.value != 'Ready'
                    ? brainSignalsController.currentStatus.value
                    : _isCollecting 
                        ? 'Please remain still and keep your eyes closed'
                        : 'Initializing brain signal collection...',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              )),
              Obx(() {
                if (_isCollecting || brainSignalsController.isLoading.value) {
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFF0850FD).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0850FD),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              brainSignalsController.isSendingData.value
                                  ? 'Sending data...'
                                  : brainSignalsController.isProcessingResults.value
                                      ? 'Processing...'
                                      : 'Recording in progress...',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF0850FD),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (brainSignalsController.isLoading.value) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0850FD)),
                          strokeWidth: 2,
                        ),
                      ],
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 40),
              Obx(() {
                if (brainSignalsController.isLoading.value) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0850FD)),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Processing Analysis',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This may take a few moments...',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Musicvisulaizer(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class VisualComponent extends StatefulWidget {
  VisualComponent({super.key, required this.duration});
  final int duration;

  @override
  State<VisualComponent> createState() => _VisualComponentState();
}

class _VisualComponentState extends State<VisualComponent>
    with TickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController animController;
  @override
  void initState() {
    super.initState();
    animController = AnimationController(
        duration: Duration(milliseconds: widget.duration), vsync: this);
    final curvedAnimation =
        CurvedAnimation(parent: animController, curve: Curves.easeInOut);
    animation = Tween<double>(begin: 0, end: 100).animate(curvedAnimation)
      ..addListener(() {
        setState(() {});
      });
    animController.repeat(reverse: true);
  }

  @override
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: widget.duration),
      width: 5,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0850FD), Color(0xFF00C6FF)])),
      height: animation.value,
    );
  }
}

class Musicvisulaizer extends StatelessWidget {
  Musicvisulaizer({super.key});
  List<int> duration = [900, 700, 600, 800, 500];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List<Widget>.generate(
          10,
          (index) => VisualComponent(
                duration: duration[index % 5],
              )),
    );
  }
}
