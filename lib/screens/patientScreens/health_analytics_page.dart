import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ADDvEEG/screens/patientScreens/detailed_quiz_history.dart';
import 'package:ADDvEEG/screens/patientScreens/detailed_eeg_history.dart';
import 'package:ADDvEEG/screens/patientScreens/analytics_chart_page.dart';
import '../../controllers/patientSideControllers/getProfileController.dart';
import '../../controllers/data_context_controller.dart';

class HealthAnalyticsPage extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  
  const HealthAnalyticsPage({
    super.key,
    this.patientId,
    this.patientName,
  });

  @override
  State<HealthAnalyticsPage> createState() => _HealthAnalyticsPageState();
}

class _HealthAnalyticsPageState extends State<HealthAnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final GetProflieController getProfileController = Get.put(GetProflieController());
  final DataContextController _dataContext = Get.put(DataContextController());

  @override
  void initState() {
    super.initState();
    
    // Set patient context if provided (for relative viewing patient data)
    if (widget.patientId != null && widget.patientName != null) {
      _dataContext.setPatientContext(widget.patientId!, widget.patientName!);
    }
    
    // Refresh data with new context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getProfileController.refreshData();
    });
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'health_analytics'.tr,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF2D2D2D),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20.0 : 32.0,
                  vertical: 20.0,
                ),
                child: GridView.count(
                  crossAxisCount: isSmallScreen ? 1 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isSmallScreen ? 3.0 : 2.2,
                  children: [
                          _buildAnalyticsCard(
                            title: 'Detailed Quiz History',
                            subtitle: 'Complete quiz records & scores',
                            icon: Icons.quiz_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Get.to(() => DetailedQuizHistory(
                                patientId: widget.patientId,
                                patientName: widget.patientName,
                              ), transition: Transition.cupertino);
                            },
                          ),
                          _buildAnalyticsCard(
                            title: 'Quiz History Chart',
                            subtitle: 'Visual trends & progress graphs',
                            icon: Icons.bar_chart_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Get.to(() => AnalyticsChartPage(
                                chartType: ChartType.quiz,
                                title: 'Quiz History Chart',
                                patientId: widget.patientId,
                                patientName: widget.patientName,
                              ), transition: Transition.cupertino);
                            },
                          ),
                          _buildAnalyticsCard(
                            title: 'Detailed EEG History',
                            subtitle: 'Complete brain signal records',
                            icon: Icons.memory_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Get.to(() => DetailedEEGHistory(
                                patientId: widget.patientId,
                                patientName: widget.patientName,
                              ), transition: Transition.cupertino);
                            },
                          ),
                          _buildAnalyticsCard(
                            title: 'EEG History Chart',
                            subtitle: 'Brain signal trends & patterns',
                            icon: Icons.timeline_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF41AD17), Color(0xFF1E8612)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Get.to(() => AnalyticsChartPage(
                                chartType: ChartType.eeg,
                                title: 'EEG History Chart',
                                patientId: widget.patientId,
                                patientName: widget.patientName,
                              ), transition: Transition.cupertino);
                            },
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Icon - centered vertically
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Title and Subtitle Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow Icon
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}