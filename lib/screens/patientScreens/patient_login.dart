// ignore_for_file: must_be_immutable

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ADDvEEG/screens/patientScreens/patient_dashboard.dart';
import 'package:ADDvEEG/screens/patientScreens/patient_profile.dart';
import 'package:ADDvEEG/screens/patientScreens/quiz_page.dart';
import 'package:ADDvEEG/screens/patientScreens/questions_page.dart';
import 'package:ADDvEEG/screens/patientScreens/resultsScreen.dart';
import 'package:ADDvEEG/screens/patientScreens/musicPlayerScreen.dart';
import 'package:ADDvEEG/screens/patientScreens/yogaScreen.dart';
import 'package:ADDvEEG/screens/patientScreens/yogaPoseDetailed.dart';
import 'package:ADDvEEG/screens/patientScreens/patient_info_form.dart';
import 'package:ADDvEEG/screens/patientScreens/health_analytics_page.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../settings_screen.dart';

import 'package:ADDvEEG/controllers/patientSideControllers/getProfileController.dart';
import 'package:ADDvEEG/controllers/notification_controller.dart';
import 'package:ADDvEEG/models/profile_model.dart';
import 'package:ADDvEEG/screens/landing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_seria_changed/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../../utils/reportGenerator/eegReportGenerator.dart';
import '../../utils/reportGenerator/quizReportGenerator.dart';
import '../../controllers/patientSideControllers/bluetoothConnection_controller.dart';
import 'eegScreen.dart';
import 'patient_info_form.dart';

class PatientLogin extends StatefulWidget {
  const PatientLogin({Key? key}) : super(key: key);

  @override
  State<PatientLogin> createState() => _PatientLoginState();
}

class _PatientLoginState extends State<PatientLogin>
    with SingleTickerProviderStateMixin {
  final GetProflieController getProflieController =
      Get.put(GetProflieController());
  final NotificationController notificationController =
      Get.put(NotificationController());
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Onboarding variables
  bool _showOnboarding = false;
  int _currentTooltipIndex = 0;
  final List<GlobalKey> _tooltipKeys = [
    GlobalKey(), // Share button
    GlobalKey(), // Notifications
    GlobalKey(), // Quiz button
    GlobalKey(), // EEG button
    GlobalKey(), // Yoga button
    GlobalKey(), // Health Analytics button
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    
    // Check if this is the first time user is opening the app
    _checkFirstTimeUser();
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    
    if (!hasSeenOnboarding) {
      // Show onboarding automatically only on first app launch
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showOnboarding = true;
        });
      });
    }
  }

  void _nextTooltip() {
    if (_currentTooltipIndex < _tooltipKeys.length - 1) {
      setState(() {
        _currentTooltipIndex++;
      });
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    setState(() {
      _showOnboarding = false;
      _currentTooltipIndex = 0;
    });
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
      drawer: CustomDrawer(getProflieController: getProflieController),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            key: _tooltipKeys[0],
            icon: const Icon(
              Icons.share_outlined,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () => _showInvitationCodeDialog(),
            tooltip: 'Share Invitation Code',
          ),
          Obx(() => Stack(
            key: _tooltipKeys[1],
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => _showNotificationDialog(),
              ),
              if (notificationController.unreadCount.value > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${notificationController.unreadCount.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Obx(
            () => ModalProgressHUD(
              inAsyncCall: getProflieController.isLoading.value,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/bg2.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 24.0 : 32.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: size.height * 0.1),
                            Text(
                              _getWelcomeMessage(),
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 32 : 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'choose_option'.tr,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 16 : 18,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: size.height * 0.05),
                            _buildOptionButton(
                              key: _tooltipKeys[2],
                              text: 'quiz'.tr,
                              icon: Icons.quiz_rounded,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () {
                                final loginDetails =
                                    GetStorage().read('loginDetails');
                                final userId = loginDetails?['user']?['_id'] ??
                                    loginDetails?['user']?['uid'];
                                Get.to(() => PatientDashboard());
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildOptionButton(
                              key: _tooltipKeys[3],
                              text: 'eeg'.tr,
                              icon: Icons.bluetooth_searching_rounded,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () async {
                                if (!GetPlatform.isAndroid) {
                                  Get.snackbar(
                                    'Alert',
                                    'This feature is not available for your Platform',
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    colorText: Colors.white,
                                  );
                                  return;
                                }
                                
                                // Check Bluetooth permissions before proceeding
                                final bluetoothController = Get.find<BluetoothController>();
                                if (!bluetoothController.isReadyForEEG) {
                                  Get.snackbar(
                                    'Permissions Required',
                                    'Please grant Bluetooth and Location permissions to use EEG functionality',
                                    backgroundColor: Colors.orange.withOpacity(0.1),
                                    colorText: Colors.orange,
                                    duration: Duration(seconds: 4),
                                  );
                                  await bluetoothController.checkAndRequestBluetoothPermissions();
                                  return;
                                }
                                if (await FlutterBluetoothSerial.instance.state ==
                                    BluetoothState.STATE_OFF) {
                                  try {
                                    await FlutterBluetoothSerial.instance
                                        .requestEnable();
                                  } catch (e) {
                                    print('Bluetooth enable error: $e');
                                    Get.snackbar(
                                      'Alert',
                                      'Please enable Bluetooth manually in settings',
                                      backgroundColor: Colors.red.withOpacity(0.1),
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }
                                  if (await FlutterBluetoothSerial.instance.state ==
                                      BluetoothState.STATE_OFF) {
                                    Get.snackbar(
                                      'Alert',
                                      'Please turn on bluetooth',
                                      backgroundColor: Colors.red.withOpacity(0.1),
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }
                                }
                                await Get.to(() => EegScreen(),
                                    transition: Transition.cupertino);
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildOptionButton(
                              key: _tooltipKeys[4],
                              text: 'yoga'.tr,
                              icon: Icons.self_improvement_rounded,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF41AD17), Color(0xFF1E8612)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () {
                                Get.to(() => YogaScreen());
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildOptionButton(
                              key: _tooltipKeys[5],
                              text: 'health_analytics'.tr,
                              icon: Icons.analytics_rounded,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () {
                                Get.to(() => HealthAnalyticsPage(),
                                    transition: Transition.cupertino);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Onboarding overlay
          if (_showOnboarding) _buildOnboardingOverlay(),
          // Help button - allows users to replay onboarding tour
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF6C63FF),
              onPressed: () {
                setState(() {
                  _showOnboarding = true;
                  _currentTooltipIndex = 0;
                });
              },
              child: const Icon(
                Icons.help_outline,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    Key? key,
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingOverlay() {
    final tooltipData = [
      {
        'title': 'Share Invitation Code',
        'description': 'Share your unique code with family members so they can monitor your health progress.',
        'icon': Icons.share_outlined,
      },
      {
        'title': 'Notifications',
        'description': 'Stay updated with important alerts, quiz reminders, and health insights.',
        'icon': Icons.notifications_outlined,
      },
      {
        'title': 'Mental Health Quiz',
        'description': 'Take assessments like HAM-D and BDI to track your mental wellness.',
        'icon': Icons.quiz_rounded,
      },
      {
        'title': 'EEG Brain Monitoring',
        'description': 'Connect your EEG device via Bluetooth to analyze brain activity.',
        'icon': Icons.bluetooth_searching_rounded,
      },
      {
        'title': 'Yoga & Meditation',
        'description': 'Practice guided exercises to improve mental and physical wellbeing.',
        'icon': Icons.self_improvement_rounded,
      },
      {
        'title': 'Health Analytics',
        'description': 'View detailed reports about your mental health progress and data.',
        'icon': Icons.analytics_rounded,
      },
    ];

    return FutureBuilder<Rect>(
      future: _getWidgetPosition(_tooltipKeys[_currentTooltipIndex]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final targetRect = snapshot.data!;
        final screenSize = MediaQuery.of(context).size;
        
        // Calculate tooltip position
        bool showBelow = targetRect.bottom + 200 < screenSize.height;
        double tooltipTop = showBelow 
            ? targetRect.bottom + 16 
            : targetRect.top - 200 - 16;
        
        // Ensure tooltip stays within screen bounds
        tooltipTop = tooltipTop.clamp(16.0, screenSize.height - 200 - 16);
        
        return Stack(
          children: [
            // Semi-transparent overlay with cutout
            _buildCutoutOverlay(targetRect),
            
            // Tooltip bubble
            Positioned(
              left: 16,
              right: 16,
              top: tooltipTop,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _tooltipKeys.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index <= _currentTooltipIndex
                                  ? _getButtonColorForStep(index)
                                  : Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        tooltipData[_currentTooltipIndex]['title'] as String,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        tooltipData[_currentTooltipIndex]['description'] as String,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _skipOnboarding,
                              child: Text(
                                'Skip',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _nextTooltip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getButtonColorForStep(_currentTooltipIndex),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _currentTooltipIndex == _tooltipKeys.length - 1
                                    ? 'Done'
                                    : 'Next',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCutoutOverlay(Rect targetRect) {
    return ClipPath(
      clipper: CutoutClipper(targetRect),
      child: Container(
        color: Colors.black.withOpacity(0.7),
      ),
    );
  }

  Widget _buildHighlight(GlobalKey key) {
    return FutureBuilder(
      future: _getWidgetPosition(key),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final rect = snapshot.data as Rect;
        return Positioned(
          left: rect.left - 8,
          top: rect.top - 8,
          child: Container(
            width: rect.width + 16,
            height: rect.height + 16,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF6C63FF),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Rect> _getWidgetPosition(GlobalKey key) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Rect.zero;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  Color _getButtonColorForStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Share button
        return const Color(0xFF00BCD4); // Cyan
      case 1: // Notifications
        return const Color(0xFFFF9800); // Orange
      case 2: // Quiz
        return const Color(0xFF6C63FF); // Purple
      case 3: // EEG
        return const Color(0xFF00C6FF); // Blue
      case 4: // Yoga
        return const Color(0xFF41AD17); // Green
      case 5: // Health Analytics
        return const Color(0xFFFF6B6B); // Red
      default:
        return const Color(0xFF6C63FF); // Default purple
    }
  }

  void _showInvitationCodeDialog() {
    final invitationCode = getProflieController.userInvitationCode;
    
    if (invitationCode == null || invitationCode.isEmpty) {
      Get.snackbar(
        'No Invitation Code',
        'Invitation code not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232323),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.share_outlined,
                color: Color(0xFF00BCD4),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Invitation Code',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this code with relatives to connect',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    invitationCode.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _copyInvitationCode(invitationCode),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.copy,
                          color: Color(0xFF00BCD4),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDialogButton(
                    'Copy Code',
                    Icons.copy,
                    () {
                      _copyInvitationCode(invitationCode);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDialogButton(
                    'Share',
                    Icons.share,
                    () {
                      _shareInvitationCode(invitationCode);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogButton(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF00BCD4).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF00BCD4),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00BCD4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyInvitationCode(String code) {
    Clipboard.setData(ClipboardData(text: code.toUpperCase()));
    Get.snackbar(
      'Copied!',
      'Invitation code copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF00BCD4).withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        Icons.check_circle,
        color: Colors.white,
      ),
    );
  }

  void _shareInvitationCode(String code) {
    final message = '''
🔗 Join my EEG monitoring network!

Use my invitation code: ${code.toUpperCase()}

This code will connect us so you can monitor my health progress and receive important updates.

Download the EEG app and use this code during registration.
    ''';
    
    Clipboard.setData(ClipboardData(text: message));
    Get.snackbar(
      'Ready to Share!',
      'Full invitation message copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF00BCD4).withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        Icons.share,
        color: Colors.white,
      ),
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232323),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (notificationController.unreadCount.value > 0)
              TextButton(
                onPressed: () {
                  notificationController.markAllAsRead();
                },
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.poppins(
                    color: Colors.lightBlue,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(() => notificationController.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 48,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: notificationController.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationController.notifications[index];
                    final isRead = notification['read'] ?? false;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isRead 
                            ? Colors.white.withOpacity(0.05)
                            : Colors.lightBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isRead 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.lightBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'] ?? 'Notification',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.lightBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          if (notification['body'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              notification['body'],
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _formatNotificationDate(notification['createdAt']),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNotificationDate(dynamic date) {
    if (date == null) return '';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  String _getWelcomeMessage() {
    try {
      final box = GetStorage();
      final loginDetails = box.read('loginDetails');
      
      if (loginDetails != null) {
        final userDetails = loginDetails['user'];
        
        // Try to get firstName only
        if (userDetails['firstName'] != null) {
          return 'Welcome ${userDetails['firstName']}';
        }
        
        // Fallback to name field if firstName not available
        if (userDetails['name'] != null) {
          String fullName = userDetails['name'];
          String firstName = fullName.split(' ')[0];
          return 'Welcome $firstName';
        }
        
        // Fallback to email if no name available
        if (userDetails['email'] != null) {
          return 'Welcome ${userDetails['email'].split('@')[0]}';
        }
      }
    } catch (e) {
      print('Error getting user name for welcome message: $e');
    }
    
    // Fallback to generic welcome message
    return 'welcome_back'.tr;
  }
}

class CutoutClipper extends CustomClipper<Path> {
  final Rect cutoutRect;

  CutoutClipper(this.cutoutRect);

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Add the full screen rectangle
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Subtract the cutout area (this creates the hole)
    final cutoutPath = Path();
    final expandedRect = cutoutRect.inflate(8);
    cutoutPath.addRRect(RRect.fromRectAndRadius(
      expandedRect,
      const Radius.circular(12),
    ));
    
    // Use difference to create the cutout effect
    return Path.combine(PathOperation.difference, path, cutoutPath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({
    super.key,
    required this.getProflieController,
  });

  final GetProflieController getProflieController;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      width: MediaQuery.of(context).size.width * 0.8,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/bg2.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.8),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 50,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: const NetworkImage(
                      'https://uxwing.com/wp-content/themes/uxwing/download/peoples-avatars/man-user-circle-icon.png',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getProflieController.userFullName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getProflieController.profile.value.username ?? 
                    getProflieController.profile.value.email ?? 
                    'Patient',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildSectionTitle('Profile'),
                    const SizedBox(height: 18),
                    _buildDrawerItem(
                      icon: Icons.person_outline_rounded,
                      title: 'My Profile',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      onTap: () {
                        Get.to(() => const PatientProfile());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDrawerItem(
                      icon: Icons.assignment_ind_rounded,
                      title: 'Complete Patient Info',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      onTap: () {
                        print('📋 [NAVIGATION] Navigating to PatientInfoForm via Get.toNamed');
                        Get.toNamed('/PatientInfoForm');
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('reports'.tr),
                    const SizedBox(height: 18),
                    _buildDrawerItem(
                      icon: Icons.quiz_rounded,
                      title: 'quiz_reports'.tr,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      onTap: () async {
                        await getProflieController.fetchQuizHistory();
                        
                        // Fetch complete profile data first
                        final loginDetails = GetStorage().read('loginDetails');
                        final userId = loginDetails?['user']?['_id'] ?? loginDetails?['user']?['uid'];
                        if (userId != null) {
                          await getProflieController.fetchProfile(userId);
                        }
                        
                        // Use the fetched profile data with fallbacks
                        final profile = getProflieController.profile.value;
                        final userProfile = Profile(
                          name: getProflieController.userFullName,
                          email: profile.email ?? loginDetails?['user']?['email'] ?? 'Not provided',
                          contact: profile.contact ?? 'Not provided',
                          age: profile.age,
                          gender: profile.gender ?? 'Not provided',
                          address: profile.address ?? 'Not provided',
                          maritalStatus: profile.maritalStatus,
                          income: profile.income,
                          religion: profile.religion,
                          education: profile.education,
                          occupation: profile.occupation,
                          habitat: profile.habitat,
                          durationOfIllness: profile.durationOfIllness,
                          ageOfOnset: profile.ageOfOnset,
                          handedness: profile.handedness,
                          bloodGroup: profile.bloodGroup,
                          bloodPressure: profile.bloodPressure,
                        );
                        
                        await generateQuizReport(
                          getProflieController.quizHistory,
                          userProfile,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDrawerItem(
                      icon: Icons.bluetooth_searching_rounded,
                      title: 'eeg_reports'.tr,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      onTap: () async {
                        await getProflieController.fetchBrainScore(null);
                        await generatEEGReport(
                            getProflieController.brainScores);
                      },
                    ),
                    const Spacer(),
                    _buildSectionTitle('settings'.tr),
                    const SizedBox(height: 18),
                    _buildDrawerItem(
                      icon: Icons.settings_rounded,
                      title: 'settings'.tr,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      onTap: () {
                        Get.to(() => const SettingsScreen());
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'logout'.tr,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1A1A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              'Logout',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Text(
                              'logout_confirm'.tr,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text(
                                  'cancel'.tr,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await getProflieController.logout();
                                  final box = GetStorage();
                                  box.remove('loginDetails');
                                  box.remove('timestamp');
                                  Get.offAll(() => const LandingPage());
                                },
                                child: Text(
                                  'logout'.tr,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.5),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWelcomeMessage() {
    try {
      final box = GetStorage();
      final loginDetails = box.read('loginDetails');
      
      if (loginDetails != null) {
        final userDetails = loginDetails['user'];
        
        // Try to get firstName only
        if (userDetails['firstName'] != null) {
          return 'Welcome ${userDetails['firstName']}';
        }
        
        // Fallback to name field if firstName not available
        if (userDetails['name'] != null) {
          String fullName = userDetails['name'];
          String firstName = fullName.split(' ')[0];
          return 'Welcome $firstName';
        }
        
        // Fallback to email if no name available
        if (userDetails['email'] != null) {
          return 'Welcome ${userDetails['email'].split('@')[0]}';
        }
      }
    } catch (e) {
      print('Error getting user name for welcome message: $e');
    }
    
    // Fallback to generic welcome message
    return 'welcome_back'.tr;
  }
}
