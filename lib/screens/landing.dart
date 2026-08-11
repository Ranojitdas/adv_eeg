import 'package:ADDvEEG/screens/auth/emaillogin.dart';
import 'package:ADDvEEG/screens/patientScreens/eegScreen.dart';
import 'package:ADDvEEG/screens/patientScreens/offline_quiz_page.dart';
import 'package:ADDvEEG/screens/patientScreens/yogaScreen.dart';
import 'package:ADDvEEG/screens/settings_screen.dart';
import 'package:ADDvEEG/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Debouncing variables
  bool _isNavigating = false;
  DateTime? _lastTapTime;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Debounced navigation method
  void _navigateWithDebounce(Widget destination) {
    final now = DateTime.now();
    
    // Prevent navigation if already navigating
    if (_isNavigating) {
      print('🚫 [NAVIGATION] Already navigating, ignoring tap');
      return;
    }
    
    // Prevent rapid taps (less than 500ms apart)
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!).inMilliseconds < 500) {
      print('🚫 [NAVIGATION] Rapid tap detected, ignoring');
      return;
    }
    
    _lastTapTime = now;
    _isNavigating = true;
    
    print('✅ [NAVIGATION] Navigating to ${destination.runtimeType}');
    
    Get.to(() => destination)?.then((_) {
      // Reset navigation flag when returning
      _isNavigating = false;
      print('🔄 [NAVIGATION] Navigation completed, flag reset');
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/bg2.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top,
              ),
              child: Stack(
                children: [
                  // Background gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF1A1A1A).withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 24.0 : 48.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          'welcome_to'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 24 : 28,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'mental_health_assessment'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 32 : 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'landing_description'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        _buildActionButton(
                          title: 'login'.tr,
                          subtitle: 'access_account'.tr,
                          icon: Icons.login_rounded,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0850FD),
                              Color(0xFF0850FD).withValues(alpha: 0.8)
                            ],
                          ),
                          onTap: () => _navigateWithDebounce(const UsernameLogin()),
                        ),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          title: 'Wellness Center',
                          subtitle: 'practice_exercises'.tr,
                          icon: Icons.spa_rounded,
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.purple.shade600
                            ],
                          ),
                          onTap: () => _navigateWithDebounce(YogaScreen()),
                        ),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          title: 'eeg_analysis'.tr,
                          subtitle: 'brain_activity'.tr,
                          icon: Icons.psychology_rounded,
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade400,
                              Colors.teal.shade600
                            ],
                          ),
                          onTap: () => _navigateWithDebounce(EegScreen()),
                        ),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          title: 'offline_mode'.tr,
                          subtitle: 'access_without_internet'.tr,
                          icon: Icons.wifi_off_rounded,
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600
                            ],
                          ),
                          onTap: () => _navigateWithDebounce(const OfflineQuizPage()),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton.icon(
                            onPressed: () =>
                                _navigateWithDebounce(const SettingsScreen()),
                            icon: Icon(Icons.settings, color: Colors.white70),
                            label: Text(
                              'settings'.tr,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                          ),
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

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
