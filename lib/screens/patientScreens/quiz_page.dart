import 'package:ADDvEEG/controllers/counter_controller.dart';
import 'package:ADDvEEG/screens/patientScreens/patient_login.dart';
import 'package:ADDvEEG/screens/patientScreens/questions_page.dart';
import 'package:ADDvEEG/services/location_service.dart';
import 'package:ADDvEEG/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({required this.role, required this.uid});
  final role, uid;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isCheckingLocation = true;
  String? _locationError;

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

  Future<bool> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationPermissionDialog(false);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog(true);
        return false;
      }

      // If we get here, we have permission
      // Update location using new backend API
      try {
        final locationService = Get.find<LocationService>();
        await locationService.updateLocationOnQuizAttempt();
      } catch (e) {
        print('Error updating location: $e');
      }

      setState(() {
        _locationError = null;
      });
      return true;
    } catch (e) {
      setState(() {
        _locationError = 'Error checking location permission: $e';
      });
      return false;
    }
  }

  void _showLocationServiceDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'Location Services Disabled',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          'Location services are required to track your quiz location. Please enable location services in your device settings.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await Geolocator.openLocationSettings();
              // Wait a bit then retry
              await Future.delayed(Duration(seconds: 2));
              _checkLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _checkLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showLocationPermissionDialog(bool isPermanentlyDenied) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_disabled, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'Location Permission Required',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: Text(
          isPermanentlyDenied
              ? 'Location permission has been permanently denied. Please enable it manually in app settings to continue with the quiz.'
              : 'Location permission is required to track your quiz location. Please grant permission when prompted.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          if (isPermanentlyDenied)
            ElevatedButton(
              onPressed: () async {
                Get.back();
                await openAppSettings();
                // Wait a bit then retry
                await Future.delayed(Duration(seconds: 2));
                _checkLocationPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'App Settings',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _checkLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _startQuiz(String quizType) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_searching_rounded,
                color: Color(0xFF0850FD),
                size: 56,
              ),
              const SizedBox(height: 18),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0850FD)),
                strokeWidth: 4,
              ),
              const SizedBox(height: 22),
              Text(
                'Getting your location...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we securely fetch your location to start the quiz.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      bool locationOk = await _checkLocationPermissionSilent();
      Navigator.pop(context); // Remove loading dialog
      
      if (locationOk) {
        Get.to(() => QuestionsPage(
          type: quizType,
          role: widget.role,
          uid: widget.uid,
        ));
      } else {
        // Location check failed, show appropriate dialog
        await _checkLocationPermission();
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading dialog
      setState(() {
        _locationError = 'Error checking location: $e';
      });
    }
  }

  Future<bool> _checkLocationPermissionSilent() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // If we get here, we have permission
      // Update location using new backend API
      try {
        // Update location using new backend API
        final locationService = Get.find<LocationService>();
        await locationService.updateLocationOnQuizAttempt();
      } catch (e) {
        print('Error updating location: $e');
        return false;
      }

      setState(() {
        _locationError = null;
      });
      return true;
    } catch (e) {
      print('Error in silent location check: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Quiz Type',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the type of quiz you want to take',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_locationError != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 32),
                          const SizedBox(height: 12),
                          Text(
                            _locationError!,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _checkLocationPermission,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0850FD),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildQuizTypeCard(
                            title: 'HAM_D Assessment',
                            description: 'Hamilton Depression Rating Scale',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0850FD), Color(0xFF3F3D9E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => _startQuiz("HAM_D"),
                          ),
                          _buildQuizTypeCard(
                            title: 'BDI Assessment',
                            description: 'Beck Depression Inventory',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => _startQuiz("BDI"),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizTypeCard({
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
