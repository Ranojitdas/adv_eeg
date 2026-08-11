import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../controllers/auth/login_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/patientSideControllers/getProfileController.dart';
import '../../services/api_service.dart';
import '../landing.dart';
import 'quiz_page.dart';
import 'questions_page.dart';
import 'resultsScreen.dart';
import 'detailed_quiz_history.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final NotificationController notificationController = Get.put(NotificationController());
  final GetProflieController getProfileController = Get.put(GetProflieController());
  final RxList<Map<String, dynamic>> quizHistory = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  Timer? _refreshTimer;

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
    
    // Use WidgetsBinding to ensure the widget is fully built before calling API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatientData();
    });

    // Set up periodic refresh for real-time updates
    _setupPeriodicRefresh();
  }

  Future<void> _loadPatientData() async {
    print('🏠 [PATIENT_DASHBOARD] 🚀 Starting to load patient data...');
    isLoading.value = true;
    try {
      print('🏠 [PATIENT_DASHBOARD] 📋 Calling fetchAssignedQuizzes...');
      await getProfileController.fetchAssignedQuizzes();
      print('🏠 [PATIENT_DASHBOARD] ✅ fetchAssignedQuizzes completed');
      print('🏠 [PATIENT_DASHBOARD] 📊 Assigned quizzes count after fetch: ${getProfileController.assignedQuizzes.length}');
      
      print('🏠 [PATIENT_DASHBOARD] 📚 Loading quiz history...');
      await _loadQuizHistory();
      print('🏠 [PATIENT_DASHBOARD] ✅ Quiz history loaded');
    } catch (e) {
      print('❌ [PATIENT_DASHBOARD] Error loading patient data: $e');
      print('❌ [PATIENT_DASHBOARD] Error type: ${e.runtimeType}');
    } finally {
      print('🏠 [PATIENT_DASHBOARD] 🏁 Finished loading patient data');
      print('🏠 [PATIENT_DASHBOARD] 📈 Final assigned quizzes count: ${getProfileController.assignedQuizzes.length}');
      isLoading.value = false;
    }
  }


  Future<void> _loadQuizHistory() async {
    try {
      print('📊 [DASHBOARD] Loading quiz history from backend API');
      await getProfileController.fetchQuizHistory();
      
      // Use the real quiz history from the controller
      quizHistory.value = getProfileController.quizHistory.value;
      
      print('📊 [DASHBOARD] ✅ Quiz history loaded: ${quizHistory.length} entries');
    } catch (e) {
      print('📊 [QUIZ_HISTORY] Error loading quiz history: $e');
      // Fallback to empty list if API fails
      quizHistory.value = [];
    }
  }

  /// Set up periodic refresh for real-time updates
  void _setupPeriodicRefresh() {
    // Refresh assigned quizzes every 30 seconds to catch new assignments
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('🔄 [PATIENT_DASHBOARD] Periodic refresh - checking for new quiz assignments...');
      getProfileController.fetchAssignedQuizzes();
      notificationController.fetchNotifications();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Patient Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Notification Bell
          Obx(() => Stack(
            children: [
              IconButton(
                onPressed: () => _showNotificationsBottomSheet(),
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              ),
              if (notificationController.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${notificationController.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          )),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Logout Confirmation',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to logout?',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
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
                    TextButton(
                      onPressed: () {
                        final box = GetStorage();
                        box.remove('loginDetails');
                        box.remove('timestamp');
                        Get.offAll(() => const LandingPage());
                      },
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/bg2.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: Obx(() => isLoading.value
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0850FD)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPatientData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16.0 : 24.0,
                            vertical: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quick Actions Section
                              _buildQuickActionsSection(isSmallScreen),
                              const SizedBox(height: 24),
                              
                              // Assigned Quizzes Section
                              _buildAssignedQuizzesSection(isSmallScreen),
                              const SizedBox(height: 24),
                              
                              // Quiz History Section
                              _buildQuizHistorySection(isSmallScreen),
                            ],
                          ),
                        ),
                      ),
                    )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          'Take Quiz',
          'Start a new assessment',
          Icons.quiz_outlined,
          Colors.green,
          () => Get.to(() => const QuizPage(role: 'PATIENT', uid: 'current_user')),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeInOut,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color.lerp(
                    Colors.white.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.4),
                    (math.sin(value * math.pi * 2) + 1) / 2,
                  )!,
                  width: 1 + ((math.sin(value * math.pi * 2) + 1) / 2) * 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1 * ((math.sin(value * math.pi * 2) + 1) / 2)),
                    blurRadius: 8 * ((math.sin(value * math.pi * 2) + 1) / 2),
                    spreadRadius: 2 * ((math.sin(value * math.pi * 2) + 1) / 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAssignedQuizzesSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assigned Quizzes',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Obx(() {
                print('🏠 [PATIENT_DASHBOARD] 🏷️ Badge Update - Count: ${getProfileController.assignedQuizzes.length}');
                return Text(
                  '${getProfileController.assignedQuizzes.length} Pending',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );}),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          print('🏠 [PATIENT_DASHBOARD] 🔄 UI Rebuild - Assigned quizzes count: ${getProfileController.assignedQuizzes.length}');
          print('🏠 [PATIENT_DASHBOARD] 📋 Assigned quizzes data: ${getProfileController.assignedQuizzes}');
          
          return getProfileController.assignedQuizzes.isEmpty
              ? _buildEmptyState(
                  'No Assigned Quizzes',
                  'Your doctor will assign quizzes that appear here',
                  Icons.assignment_outlined,
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: getProfileController.assignedQuizzes.length,
                  itemBuilder: (context, index) {
                    print('🏠 [PATIENT_DASHBOARD] 🎯 Building quiz card $index: ${getProfileController.assignedQuizzes[index]}');
                    return _buildAssignedQuizCard(getProfileController.assignedQuizzes[index]);
                  },
                );
        }),
      ],
    );
  }

  Widget _buildAssignedQuizCard(Map<String, dynamic> quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.lightBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Colors.lightBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${quiz['questionnaireType'] ?? 'Unknown Type'} Assessment',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assigned by: ${quiz['assignedBy'] ?? 'Unknown'}',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${_formatDate(quiz['assignedAt'])}',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _startAssignedQuiz(quiz),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0850FD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Start',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizHistorySection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quiz History',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Obx(() => quizHistory.length > 3
                ? TextButton(
                    onPressed: () => _navigateToDetailedQuizHistory(),
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        color: Colors.lightBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() => quizHistory.isEmpty
            ? _buildEmptyState(
                'No Quiz History',
                'Completed quizzes will appear here',
                Icons.history_outlined,
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quizHistory.length > 3 ? 3 : quizHistory.length,
                itemBuilder: (context, index) => _buildHistoryCard(quizHistory[index]),
              )),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> quiz) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2500),
      curve: Curves.easeInOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color.lerp(
                Colors.white.withValues(alpha: 0.1),
                Colors.orange.withValues(alpha: 0.2),
                (math.sin(value * math.pi * 2) + 1) / 2,
              )!,
              width: 1 + ((math.sin(value * math.pi * 2) + 1) / 2) * 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.03 * ((math.sin(value * math.pi * 2) + 1) / 2)),
                blurRadius: 3 * ((math.sin(value * math.pi * 2) + 1) / 2),
                spreadRadius: 0.5 * ((math.sin(value * math.pi * 2) + 1) / 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outlined,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${quiz['questionnaireType'] ?? 'Unknown Type'} Assessment',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${quiz['score'] ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completed: ${_formatDate(quiz['completedAt'])}',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Completed',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _startAssignedQuiz(Map<String, dynamic> quiz) {
    Get.to(() => QuestionsPage(
      type: quiz['questionnaireType'],
      uid: 'current_user', // This should be the actual user ID
      role: 'PATIENT',
    ));
  }

  void _navigateToDetailedQuizHistory() {
    Get.to(() => const DetailedQuizHistory());
  }


  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => notificationController.markAllAsRead(),
                      child: Text(
                        'Mark All Read',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0850FD),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (notificationController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0850FD)),
                    ),
                  );
                }

                if (notificationController.notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notificationController.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationController.notifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    
    // Debug: Check quiz type in notification display
    print('🎨 [UI] ═══ NOTIFICATION CARD DEBUG ═══');
    print('🎨 [UI] Notification ID: ${notification['_id']}');
    print('🎨 [UI] Title: ${notification['title']}');
    print('🎨 [UI] Message: ${notification['message']}');
    print('🎨 [UI] Type: ${notification['type']}');
    
    if (notification['data'] != null) {
      print('🎨 [UI] Data: ${notification['data']}');
      if (notification['data']['quizType'] != null) {
        print('🎨 [UI] Data.quizType: "${notification['data']['quizType']}"');
      }
    }
    
    // Check for quiz type in message
    final message = notification['message'] ?? '';
    if (message.contains('HAM') || message.contains('BDI')) {
      print('🎨 [UI] ⚠️  QUIZ TYPE FOUND IN MESSAGE: "$message"');
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead 
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFF0850FD).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead 
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFF0850FD).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0850FD).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getNotificationIcon(notification['type']),
              color: const Color(0xFF0850FD),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? 'Notification',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
                if (notification['message'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatNotificationTime(notification['createdAt']),
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead)
            GestureDetector(
              onTap: () => notificationController.markAsRead(notification['_id']),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFF0850FD),
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'quiz':
        return Icons.quiz_outlined;
      case 'appointment':
        return Icons.event_outlined;
      case 'result':
        return Icons.analytics_outlined;
      case 'reminder':
        return Icons.alarm_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatNotificationTime(dynamic time) {
    if (time == null) return 'Unknown';
    try {
      final DateTime dateTime = DateTime.parse(time.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
