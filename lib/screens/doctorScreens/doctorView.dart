// ignore: file_names
import 'package:ADDvEEG/models/profile_model.dart';
import 'package:ADDvEEG/screens/doctorScreens/patientDetailedView(DocEnd).dart';
import 'package:ADDvEEG/screens/doctorScreens/assigned_quizzes_screen.dart';
import 'package:ADDvEEG/screens/doctorScreens/question_management_screen.dart';
import 'package:ADDvEEG/screens/patientScreens/quiz_page.dart';
import 'package:ADDvEEG/screens/doctorScreens/patient_quiz_details_screen.dart';
import 'package:ADDvEEG/utils/reportGenerator/quizReportGenerator.dart';
import 'package:ADDvEEG/utils/reportGenerator/eegReportGenerator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../controllers/doctor/doctorview_controller.dart';
import '../../controllers/doctor/getQuizData.dart';
import '../../controllers/patientSideControllers/getProfileController.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/data_context_controller.dart';
import '../landing.dart';
import '../../models/doctor_model.dart';

class DoctorView extends StatefulWidget {
  const DoctorView({super.key});

  @override
  State<DoctorView> createState() => _DoctorViewState();
}

class _DoctorViewState extends State<DoctorView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late DoctorViewController doctorViewController;
  late GetProflieController getProfileController;
  final NotificationController notificationController = Get.put(NotificationController());
  final ScrollController _scrollController = ScrollController();
  var isRefreshing = false.obs;
  Timer? _refreshTimer;
  Timer? _searchFocusTimer;
  final FocusNode _searchFocusNode = FocusNode();

  void _startSearchFocusTimer() {
    _searchFocusTimer?.cancel();
    _searchFocusTimer = Timer(const Duration(seconds: 3), () {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
    });
  }

  void sortPatients() {
    if (doctorViewController.docDetails.value.data?.patientInfo != null) {
      print("Starting sort..."); // Debug print

      // Filter out doctors and relatives, keep only patients (role = "PATIENT")
      final filteredList = doctorViewController
          .docDetails.value.data!.patientInfo!
          .where((patientInfo) => patientInfo.patient?.role == "PATIENT")
          .toList();

      final sortedList = List<PatientInfo>.from(filteredList);
      
      // Update the list immediately without sorting by quiz data for now
      doctorViewController.docDetails.value.data!.patientInfo = sortedList;
      doctorViewController.docDetails.refresh();
      
      print("Filtered ${sortedList.length} patients with role PATIENT");
      print("First patient: ${sortedList.isNotEmpty ? sortedList.first.patient?.name : 'No patients'}");
      
      // Skip quiz-based sorting for now since quiz data might not be loaded
      /*
      sortedList.sort((a, b) {
        // Get latest quiz for both patients
        final aQuiz = getProfileController.quiz.value.data
            .where((q) => q.id == a.patient?.uid)
            .toList();
        final bQuiz = getProfileController.quiz.value.data
            .where((q) => q.id == b.patient?.uid)
            .toList();

        // Check if either has no quiz
        if (aQuiz.isEmpty && bQuiz.isEmpty) return 0;
        if (aQuiz.isEmpty) return 1;
        if (bQuiz.isEmpty) return -1;

        // Get latest quiz for both
        final aLatest = aQuiz.last;
        final bLatest = bQuiz.last;

        print("Comparing patients:"); // Debug print
        print(
            "Patient A: ${a.patient?.name}, Score: ${aLatest.score}, Type: ${aLatest.questionnaireType}");
        print(
            "Patient B: ${b.patient?.name}, Score: ${bLatest.score}, Type: ${bLatest.questionnaireType}");

        // Get depression levels for both
        int getDepressionLevel(dynamic quiz) {
          if (quiz.questionnaireType == 'HAM_D') {
            if (quiz.score >= 23) {
              print("HAM-D Very Severe: ${quiz.score}"); // Debug print
              return 5;
            }
            if (quiz.score >= 19) {
              print("HAM-D Severe: ${quiz.score}"); // Debug print
              return 4;
            }
            if (quiz.score >= 14) {
              print("HAM-D Moderate: ${quiz.score}"); // Debug print
              return 3;
            }
            if (quiz.score >= 8) {
              print("HAM-D Mild: ${quiz.score}"); // Debug print
              return 2;
            }
            print("HAM-D Normal: ${quiz.score}"); // Debug print
            return 1;
          } else {
            // BDI quiz
            if (quiz.score >= 29) {
              print("BDI Very Severe: ${quiz.score}"); // Debug print
              return 5;
            }
            if (quiz.score >= 20) {
              print("BDI Severe: ${quiz.score}"); // Debug print
              return 4;
            }
            if (quiz.score >= 13) {
              print("BDI Moderate: ${quiz.score}"); // Debug print
              return 3;
            }
            if (quiz.score >= 7) {
              print("BDI Mild: ${quiz.score}"); // Debug print
              return 2;
            }
            print("BDI Minimal: ${quiz.score}"); // Debug print
            return 1;
          }
        }

        final aLevel = getDepressionLevel(aLatest);
        final bLevel = getDepressionLevel(bLatest);

        print("Levels - A: $aLevel, B: $bLevel"); // Debug print

        // Sort in descending order (higher severity first)
        final result = bLevel.compareTo(aLevel);
        print("Sort result: $result"); // Debug print
        return result;
      });
      */
      
      print(
          "Sort complete. First patient: ${sortedList.isNotEmpty ? sortedList.first.patient?.name : 'No patients'}"); // Debug print
    }
  }

  // Helper function to get filtered patient count
  int getFilteredPatientCount() {
    if (doctorViewController.docDetails.value.data?.patientInfo == null) {
      return 0;
    }
    return getFilteredPatients().length;
  }

  // Helper function to get filtered patients based on search
  List<PatientInfo> getFilteredPatients() {
    if (doctorViewController.docDetails.value.data?.patientInfo == null) {
      return [];
    }
    
    final allPatients = doctorViewController.docDetails.value.data!.patientInfo!
        .where((patientInfo) => patientInfo.patient?.role == "PATIENT")
        .toList();
    
    final searchQuery = doctorViewController.searchText.text.toLowerCase().trim();
    
    if (searchQuery.isEmpty) {
      return allPatients;
    }
    
    return allPatients.where((patientInfo) {
      final patientName = patientInfo.patient?.name?.toLowerCase() ?? '';
      final patientEmail = patientInfo.patient?.email?.toLowerCase() ?? '';
      final patientId = patientInfo.patient?.uid?.toLowerCase() ?? '';
      
      return patientName.contains(searchQuery) || 
             patientEmail.contains(searchQuery) || 
             patientId.contains(searchQuery);
    }).toList();
  }

  // Refresh function to fetch and sort patient data
  Future<void> _refreshData() async {
    if (doctorViewController.docDetails.value.data?.patientInfo != null) {
      try {
        isRefreshing(true);

        // Add a small delay to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 100));

        // Filter out doctors and relatives, keep only patients (role = "USER")
        final filteredPatients = doctorViewController
            .docDetails.value.data!.patientInfo!
            .where((patientInfo) => patientInfo.patient?.role == "USER")
            .toList();

        // First fetch all quiz data for filtered patients only
        final futures = <Future>[];
        for (var patient in filteredPatients) {
          futures.add(_retryFetchQuiz(patient.patient!.uid!));
        }

        // Wait for all quiz data to be fetched
        await Future.wait(futures);

        // Then sort the patients
        sortPatients();

        // Add a small delay before hiding loading
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('Error refreshing data: $e');
        Get.snackbar(
          'Error',
          'Failed to refresh data. Please check your internet connection.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.white,
        );
      } finally {
        isRefreshing(false);
      }
    } else {
      isRefreshing(false);
    }
  }

  // Force refresh doctor data and then refresh patient list
  Future<void> _forceRefreshData() async {
    try {
      isRefreshing(true);

      // First refresh the doctor data
      await doctorViewController.fetchDocDetails();

      // Wait a bit for the data to be processed
      await Future.delayed(const Duration(milliseconds: 300));

      // Then refresh the patient list
      await _refreshData();
    } catch (e) {
      print('Error force refreshing data: $e');
      Get.snackbar(
        'Error',
        'Failed to refresh data. Please check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.white,
      );
    } finally {
      isRefreshing(false);
    }
  }

  // Retry function for fetching quiz data
  Future<void> _retryFetchQuiz(String uid) async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        await getProfileController.fetchQuiz(uid);
        return;
      } catch (e) {
        retryCount++;
        print('Attempt $retryCount failed: $e');

        if (retryCount == maxRetries) {
          print('Failed to fetch quiz data after $maxRetries attempts: $e');
          Get.snackbar(
            'Connection Error',
            'Unable to fetch patient data. Please check your internet connection.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          rethrow;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(retryDelay * retryCount);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    doctorViewController = Get.put(DoctorViewController());
    getProfileController = Get.put(GetProflieController());

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

    // Wait for controllers to initialize and data to load, then refresh
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Try to refresh data multiple times with increasing delays
      for (int attempt = 1; attempt <= 3; attempt++) {
        await Future.delayed(Duration(milliseconds: 500 * attempt));

        // Check if data is available and refresh
        if (doctorViewController.docDetails.value.data?.patientInfo != null) {
          print('Attempt $attempt: Data found, refreshing...');
          await _refreshData();
          break;
        } else {
          print('Attempt $attempt: No data yet, waiting...');
          // Force refresh the doctor data on the last attempt
          if (attempt == 3) {
            await _forceRefreshData();
          }
        }
      }
      
      // Load assigned quizzes
      await doctorViewController.getQuizAssignedByMe();
    });

    // Set up periodic notification refresh like patient screen
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('🔄 [DOCTOR_DASHBOARD] Periodic refresh - checking for new notifications...');
      notificationController.fetchNotifications();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _searchFocusTimer?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (notificationController.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0850FD)),
                    );
                  }

                  if (notificationController.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notificationController.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notificationController.notifications[index];
                      final isRead = notification['read'] ?? false;
                      final title = notification['title'] ?? 'Notification';
                      final body = notification['body'] ?? '';
                      final createdAt = notification['createdAt'] ?? '';
                      final type = notification['type'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead 
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFF0850FD).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRead 
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFF0850FD).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getNotificationTypeColor(type),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getNotificationTypeLabel(type),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0850FD),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              _formatNotificationTime(createdAt),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'quiz_completion':
        return Colors.green;
      case 'quiz_assignment':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'quiz_completion':
        return 'Quiz Complete';
      case 'quiz_assignment':
        return 'Quiz Assigned';
      default:
        return 'General';
    }
  }

  String _formatNotificationTime(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final DoctorViewController doctorViewController =
        Get.put(DoctorViewController());
    final GetProflieController getProfileController =
        Get.put(GetProflieController());

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      drawer: _buildSidebar(context, doctorViewController),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Doctor Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          GetBuilder<NotificationController>(
            builder: (notificationController) {
              return IconButton(
                onPressed: () {
                  _showNotificationsDialog();
                },
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, color: Colors.white),
                    if (notificationController.unreadCount.value > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '${notificationController.unreadCount.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
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
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/pattern.png',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Obx(() {
                        if (doctorViewController.docDetails.value.data ==
                            null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _refreshData,
                          triggerMode: RefreshIndicatorTriggerMode.anywhere,
                          displacement: 0,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: _scrollController,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16.0 : 24.0,
                                    vertical: 16.0,
                                  ),
                                  child: Material(
                                    elevation: 4,
                                    shadowColor: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: TextField(
                                          controller:
                                              doctorViewController.searchText,
                                          focusNode: _searchFocusNode,
                                          onTap: () {
                            // Start timer when search field is tapped/focused
                            _startSearchFocusTimer();
                          },
                                          onChanged: (value) {
                            // Trigger UI rebuild when search text changes
                            doctorViewController.update();
                            // Start/reset the auto-unfocus timer
                            _startSearchFocusTimer();
                          },
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: 'Search patients...',
                                            hintStyle: GoogleFonts.poppins(
                                              color:
                                                  Colors.white.withValues(alpha: 0.5),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color:
                                                  Colors.white.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildAssignedQuizzesSection(doctorViewController, isSmallScreen),
                                const SizedBox(height: 24),
                                // Patient List Section
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 24.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Patient List',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8BC34A).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF8BC34A).withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          '${getFilteredPatientCount()} Patients',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF8BC34A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Obx(
                                  () => getFilteredPatientCount() == 0
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.people_outline_rounded,
                                                size: 64,
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No patients found',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7),
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Patients will appear here when assigned',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : isMediumScreen || !isSmallScreen
                                          ? GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    isSmallScreen ? 16.0 : 24.0,
                                                vertical: 8.0,
                                              ),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount:
                                                    isMediumScreen ? 2 : 3,
                                                childAspectRatio: 1.5,
                                                crossAxisSpacing: 16,
                                                mainAxisSpacing: 16,
                                              ),
                                              itemCount:
                                                  getFilteredPatientCount(),
                                              itemBuilder: (context, index) =>
                                                  _buildPatientCard(
                                                context,
                                                doctorViewController,
                                                getProfileController,
                                                index,
                                                isSmallScreen,
                                              ),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    isSmallScreen ? 16.0 : 24.0,
                                                vertical: 8.0,
                                              ),
                                              itemCount:
                                                  getFilteredPatientCount(),
                                              itemBuilder: (context, index) =>
                                                  Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12.0),
                                                child: _buildPatientCard(
                                                  context,
                                                  doctorViewController,
                                                  getProfileController,
                                                  index,
                                                  isSmallScreen,
                                                ),
                                              ),
                                            ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Loading overlay when refreshing
                      Obx(() => isRefreshing.value
                          ? Container(
                              color: Colors.black.withValues(alpha: 0.3),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF0850FD)),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Refreshing patient list...',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(
    BuildContext context,
    DoctorViewController doctorViewController,
    GetProflieController getProfileController,
    int index,
    bool isSmallScreen,
  ) {
    // Get the latest quiz score for this patient using filtered list
    final filteredPatients = getFilteredPatients();
    if (index >= filteredPatients.length) return Container();
    
    final patientId = filteredPatients[index].patient!.uid;

    // Fetch quiz data for this specific patient
    // Note: We need to use GetQuizController which fetches patient-specific data
    final GetQuizController patientQuizController = Get.put(GetQuizController(patientId.toString()), tag: patientId.toString());
    
    // Ensure quiz data is fetched for this patient
    if (patientQuizController.quiz.value.data == null || patientQuizController.quiz.value.data!.isEmpty) {
      print('🔄 [DOCTOR] Fetching quiz data for patient: $patientId');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        patientQuizController.fetchQuiz();
      });
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final filteredPatients = getFilteredPatients();
          if (index < filteredPatients.length) {
            _showPatientOptions(
              context,
              doctorViewController,
              getProfileController,
              filteredPatients[index],
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0850FD).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      backgroundImage: const NetworkImage(
                        'https://uxwing.com/wp-content/themes/uxwing/download/peoples-avatars/man-user-circle-icon.png',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${filteredPatients[index].patient!.name}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${filteredPatients[index].patient!.uid?.substring(0, 8) ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                    if (getProfileController.isLoading.value) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        ),
                      );
                    }

                    // Use patient-specific quiz controller instead of global one
                    return Obx(() {
                      if (patientQuizController.isLoading.value) {
                        return Container(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        );
                      }

                      final patientQuizzes = patientQuizController.quiz.value.data;
                      print('🏥 [DOCTOR] Patient ${patientId} quiz data: ${patientQuizzes?.length ?? 0} quizzes');
                      
                      // Debug: Print all quiz data for this patient
                      if (patientQuizzes != null && patientQuizzes.isNotEmpty) {
                        print('🔍 [DEBUG] All quizzes for patient ${patientId}:');
                        for (int i = 0; i < patientQuizzes.length; i++) {
                          final quiz = patientQuizzes[i];
                          print('🔍 [DEBUG] Quiz $i: Score=${quiz.score}, Type=${quiz.questionnaireType}, ID=${quiz.id}');
                        }
                      }

                      // Check if data is null or empty
                      if (patientQuizzes == null || patientQuizzes.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.help_outline,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'No Data',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final latestQuiz = patientQuizzes.last;
                      print('🔍 [DEBUG] Selected latest quiz: Score=${latestQuiz.score}, Type=${latestQuiz.questionnaireType}, ID=${latestQuiz.id}');
                      
                      // Validate quiz data
                      if (latestQuiz.score == null) {
                        print('⚠️ [DOCTOR] Patient ${patientId} has null score');
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.help_outline,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'No Data',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // Convert score to int if it's a string
                      int score;
                      print('🔍 [DEBUG] Patient ${patientId} raw score: ${latestQuiz.score} (type: ${latestQuiz.score.runtimeType})');
                      try {
                        if (latestQuiz.score is String) {
                          score = int.parse(latestQuiz.score.toString());
                          print('🔍 [DEBUG] Parsed string score: $score');
                        } else if (latestQuiz.score is num) {
                          score = latestQuiz.score.toInt();
                          print('🔍 [DEBUG] Converted numeric score: $score');
                        } else {
                          print('⚠️ [DEBUG] Unknown score type: ${latestQuiz.score.runtimeType}');
                          score = 0;
                        }
                      } catch (e) {
                        print('⚠️ [DOCTOR] Patient ${patientId} score parsing error: ${latestQuiz.score} - $e');
                        score = 0;
                      }
                      
                      print('🏥 [DOCTOR] Patient ${patientId} - Final Score: $score, Type: ${latestQuiz.questionnaireType}');
                      
                      if (score == 0) {
                        // Even with score 0, show as "Normal" status
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Normal',
                                style: GoogleFonts.poppins(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Get depression level and color based on validated score
                      String depressionLevel;
                      Color statusColor;
                      String quizType = latestQuiz.questionnaireType?.toString() ?? 'UNKNOWN';

                      print('🔍 [DEBUG] Quiz type check: "$quizType" == "HAM_D" or "HAM-D"?');
                      if (quizType == 'HAM_D' || quizType == 'HAM-D') {
                        print('🔍 [DEBUG] Processing HAM-D scale for score: $score');
                        // HAM-D Depression Scale
                        if (score < 8) {
                          depressionLevel = 'Normal';
                          statusColor = Colors.green;
                          print('🔍 [DEBUG] Score $score < 8 → Normal');
                        } else if (score < 14) {
                          depressionLevel = 'Mild';
                          statusColor = Colors.orange;
                          print('🔍 [DEBUG] Score $score >= 8 and < 14 → Mild');
                        } else if (score < 19) {
                          depressionLevel = 'Moderate';
                          statusColor = Colors.orange;
                          print('🔍 [DEBUG] Score $score >= 14 and < 19 → Moderate');
                        } else if (score < 23) {
                          depressionLevel = 'Severe';
                          statusColor = Colors.red;
                          print('🔍 [DEBUG] Score $score >= 19 and < 23 → Severe');
                        } else {
                          depressionLevel = 'Very Severe';
                          statusColor = const Color.fromARGB(255, 254, 8, 8);
                          print('🔍 [DEBUG] Score $score >= 23 → Very Severe');
                        }
                        print('🏥 [DOCTOR] HAM-D Patient ${patientId} - Score: $score → $depressionLevel');
                      } else if (quizType == 'BDI' || quizType == 'BID') {
                        print('🔍 [DEBUG] Processing BDI scale for score: $score');
                        // BDI Depression Scale
                        if (score < 7) {
                          depressionLevel = 'Minimal';
                          statusColor = Colors.green;
                          print('🔍 [DEBUG] Score $score < 7 → Minimal');
                        } else if (score < 13) {
                          depressionLevel = 'Mild';
                          statusColor = Colors.blue;
                          print('🔍 [DEBUG] Score $score >= 7 and < 13 → Mild');
                        } else if (score < 20) {
                          depressionLevel = 'Moderate';
                          statusColor = Colors.orange;
                          print('🔍 [DEBUG] Score $score >= 13 and < 20 → Moderate');
                        } else if (score < 29) {
                          depressionLevel = 'Severe';
                          statusColor = Colors.red;
                          print('🔍 [DEBUG] Score $score >= 20 and < 29 → Severe');
                        } else {
                          depressionLevel = 'Very Severe';
                          statusColor = const Color.fromARGB(255, 250, 2, 2);
                          print('🔍 [DEBUG] Score $score >= 29 → Very Severe');
                        }
                        print('🏥 [DOCTOR] BDI Patient ${patientId} - Score: $score → $depressionLevel');
                      } else {
                        // Unknown quiz type
                        print('⚠️ [DOCTOR] Unknown quiz type for patient ${patientId}: $quizType');
                        depressionLevel = 'Unknown';
                        statusColor = Colors.grey;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              depressionLevel == 'Normal' || depressionLevel == 'Minimal'
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_rounded,
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              depressionLevel,
                              style: GoogleFonts.poppins(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    context,
                    'View Details',
                    Icons.person_outline_rounded,
                    () {
                      Get.to(() => PatientDetailedViewForDoc(
                            filteredPatients[index],
                          ));
                    },
                  ),
                  _buildActionButton(
                    context,
                    'Assign Quiz',
                    Icons.assignment_outlined,
                    () {
                      _showQuizAssignmentDialog(
                        context,
                        doctorViewController,
                        filteredPatients[index],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    context,
                    'Quiz History',
                    Icons.quiz_outlined,
                    () {
                      final patient = doctorViewController.docDetails.value.data!.patientInfo![index].patient!;
                      Get.to(() => PatientQuizDetailsScreen(
                            patientId: patient.uid!,
                            patientName: patient.name ?? 'Unknown Patient',
                          ));
                    },
                  ),
                  _buildActionButton(
                    context,
                    'Report',
                    Icons.download_outlined,
                    () async {
                      final patient = filteredPatients[index].patient!;
                      _showReportSelectionDialog(context, patient, filteredPatients[index]);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatientOptions(
    BuildContext context,
    DoctorViewController doctorViewController,
    GetProflieController getProfileController,
    PatientInfo patientInfo,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Patient Options',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionItem(
              context,
              'View Patient Details',
              Icons.person_outline_rounded,
              () {
                Get.back();
                Get.to(() => PatientDetailedViewForDoc(
                      patientInfo,
                    ));
              },
            ),
            _buildOptionItem(
              context,
              'Quiz History',
              Icons.quiz_outlined,
              () {
                Get.back();
                final patient = patientInfo.patient!;
                Get.to(() => PatientQuizDetailsScreen(
                      patientId: patient.uid!,
                      patientName: patient.name ?? 'Unknown Patient',
                    ));
              },
            ),
            _buildOptionItem(
              context,
              'Download Patient Quiz Report',
              Icons.download_outlined,
              () async {
                Get.back();
                await getProfileController
                    .fetchQuizHistory()
                    .then((value) async {
                  await generateQuizReport(
                    getProfileController.quizHistory,
                    Profile(
                      name: patientInfo.patient!.name ?? 'Unknown Patient',
                      uid: patientInfo.patient!.uid!,
                      username: patientInfo.patient!.username ?? 'N/A',
                      email: patientInfo.patient!.email ?? 'Not provided',
                      contact: patientInfo.patient!.contact ?? 'Not provided',
                      age: patientInfo.patient!.age,
                      gender: 'Not provided',
                      address: 'Not provided',
                    ),
                  );
                });
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16.0,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF0850FD),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quiz Assignment Dialog
  void _showQuizAssignmentDialog(
    BuildContext context,
    DoctorViewController doctorViewController,
    PatientInfo patientInfo,
  ) {
    String selectedQuizType = 'HAM_D';
    final RxBool isAssigning = false.obs;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF0850FD),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Assign Quiz',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient: ${patientInfo.patient!.name}',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Quiz Type:',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  _buildQuizTypeOption(
                    'HAM_D',
                    'HAM_D Assessment',
                    'Hamilton Depression Rating Scale - Comprehensive assessment for depression severity',
                    selectedQuizType == 'HAM_D',
                    () => setState(() => selectedQuizType = 'HAM_D'),
                  ),
                  const SizedBox(height: 8),
                  _buildQuizTypeOption(
                    'BDI',
                    'BDI Assessment',
                    'Beck Depression Inventory - Self-report measure for depression symptoms',
                    selectedQuizType == 'BDI',
                    () => setState(() => selectedQuizType = 'BDI'),
                  ),
                ],
              ),
            ),
          ],
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
          Obx(() => ElevatedButton(
            onPressed: isAssigning.value
                ? null
                : () async {
                    isAssigning.value = true;
                    final patientId = patientInfo.patient!.uid!;
                    
                    final success = await doctorViewController.assignQuizToPatient(
                      patientId,
                      selectedQuizType,
                    );
                    
                    isAssigning.value = false;
                    Get.back();
                    
                    if (success) {
                      Get.snackbar(
                        'Success',
                        'Quiz assigned successfully to ${patientInfo.patient!.name}',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                        colorText: Colors.white,
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                      );
                    } else {
                      Get.snackbar(
                        'Error',
                        'Failed to assign quiz. Please try again.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        colorText: Colors.white,
                        icon: const Icon(Icons.error, color: Colors.red),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0850FD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isAssigning.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Assign Quiz',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          )),
        ],
      ),
    );
  }

  // Refresh assigned quizzes
  Future<void> _refreshAssignedQuizzes(DoctorViewController controller) async {
    await controller.getQuizAssignedByMe();
  }

  // Build assigned quizzes section
  Widget _buildAssignedQuizzesSection(DoctorViewController controller, bool isSmallScreen) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0850FD)),
          ),
        );
      }

      if (controller.assignedQuizzes.isEmpty) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 24.0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Assigned Quizzes',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quizzes you assign to patients will appear here',
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

      // Show only latest 2 assigned quizzes
      final latestQuizzes = controller.assignedQuizzes.take(2).toList();
      
      return Column(
        children: [
          // Header with count and "View All" link
          Container(
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 24.0),
            child: Row(
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
                if (controller.assignedQuizzes.length > 2)
                  TextButton(
                    onPressed: () {
                      Get.to(() => const AssignedQuizzesScreen());
                    },
                    child: Text(
                      'View All (${controller.assignedQuizzes.length})',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFF9800),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Quiz cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 24.0),
            itemCount: latestQuizzes.length,
            itemBuilder: (context, index) => _buildAssignedQuizCard(
              latestQuizzes[index],
              isSmallScreen,
            ),
          ),
        ],
      );
    });
  }

  // Build assigned quiz card
  Widget _buildAssignedQuizCard(dynamic quiz, bool isSmallScreen) {
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
              color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.quiz_outlined,
              color: const Color(0xFF64B5F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz['questionnaireType'] ?? 'Unknown Type',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient: ${_getPatientName(quiz)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assigned: ${_formatDate(quiz['createdAt'])}',
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
              color: _getStatusColor(quiz['status']).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(quiz['status']).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              quiz['status'] ?? 'Pending',
              style: GoogleFonts.poppins(
                color: _getStatusColor(quiz['status']),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuizTypeOption(
    String value,
    String title,
    String description,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0850FD).withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0850FD)
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0850FD)
                        : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  color: isSelected
                      ? const Color(0xFF0850FD)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
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

  Widget _buildSidebar(BuildContext context, DoctorViewController controller) {
    return Drawer(
      backgroundColor: const Color(0xFF2A2A2A),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0850FD),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Doctor Panel',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sidebar Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Assigned Quizzes Section
                _buildSidebarSection(
                  title: 'Assigned Quizzes',
                  icon: Icons.assignment,
                  child: _buildAssignedQuizzesCard(controller),
                ),
                
                const SizedBox(height: 20),
                
                // Questions Section
                _buildSidebarSection(
                  title: 'Question Management',
                  icon: Icons.quiz,
                  child: _buildQuestionManagement(),
                ),
                
                const SizedBox(height: 20),
                
                // Quick Actions
                _buildSidebarSection(
                  title: 'Quick Actions',
                  icon: Icons.flash_on,
                  child: _buildQuickActions(),
                ),
              ],
            ),
          ),
          
          // Logout Button at Bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF0850FD),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedQuizzesCard(DoctorViewController controller) {
    return Obx(() {
      final totalQuizzes = controller.assignedQuizzes.length;
      final completedQuizzes = controller.assignedQuizzes
          .where((quiz) => quiz['status'] == 'completed')
          .length;
      final pendingQuizzes = totalQuizzes - completedQuizzes;

      return InkWell(
        onTap: () {
          Get.to(() => const AssignedQuizzesScreen());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF0850FD).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: Color(0xFF0850FD),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'View All Quizzes',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$totalQuizzes total assignments',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMiniStat('Completed', completedQuizzes.toString(), Colors.green),
                  const SizedBox(width: 12),
                  _buildMiniStat('Pending', pendingQuizzes.toString(), Colors.orange),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionManagement() {
    return Column(
      children: [
        _buildQuestionTypeCard('HAM-D Questions', 'Depression Assessment', Icons.psychology),
        const SizedBox(height: 8),
        _buildQuestionTypeCard('BDI Questions', 'Beck Depression Inventory', Icons.mood),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Get.to(() => const QuestionManagementScreen());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0850FD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 16),
              const SizedBox(width: 4),
              Text(
                'Manage Questions',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTypeCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF0850FD),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildQuickActionButton(
          'Assign Quiz',
          Icons.assignment_add,
          () {
            Get.snackbar(
              'Feature',
              'Select a patient from the list to assign a quiz',
              backgroundColor: const Color(0xFF0850FD).withValues(alpha: 0.1),
              colorText: Colors.white,
            );
          },
        ),
        const SizedBox(height: 8),
        _buildQuickActionButton(
          'View Reports',
          Icons.analytics,
          () {
            Get.snackbar(
              'Coming Soon',
              'Comprehensive reports feature coming soon',
              backgroundColor: const Color(0xFF0850FD).withValues(alpha: 0.1),
              colorText: Colors.white,
            );
          },
        ),
        const SizedBox(height: 8),
        _buildQuickActionButton(
          'Patient Stats',
          Icons.bar_chart,
          () {
            Get.snackbar(
              'Feature',
              'Select a patient to view detailed statistics',
              backgroundColor: const Color(0xFF0850FD).withValues(alpha: 0.1),
              colorText: Colors.white,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF0850FD),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.3),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'assigned':
        return const Color(0xFF64B5F6);
      default:
        return Colors.grey;
    }
  }

  String _getPatientName(dynamic quiz) {
    // Based on the debug output, the structure is: quiz['patient']['firstName'] and quiz['patient']['lastName']
    if (quiz['patient'] != null) {
      String firstName = quiz['patient']['firstName'] ?? '';
      String lastName = quiz['patient']['lastName'] ?? '';
      String fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) {
        return fullName;
      }
    }
    
    // Fallback attempts
    if (quiz['patientId'] != null && quiz['patientId']['name'] != null) {
      return quiz['patientId']['name'];
    }
    if (quiz['patientName'] != null && quiz['patientName'].isNotEmpty) {
      return quiz['patientName'];
    }
    if (quiz['assignedTo'] != null && quiz['assignedTo']['firstName'] != null) {
      String firstName = quiz['assignedTo']['firstName'] ?? '';
      String lastName = quiz['assignedTo']['lastName'] ?? '';
      return '$firstName $lastName'.trim();
    }
    
    return 'Patient Name Not Available';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Recently';
    }
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  /// Show dialog to select report type (Quiz or EEG)
  void _showReportSelectionDialog(BuildContext context, dynamic patient, PatientInfo patientInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Generate Report',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select the type of report to generate for ${patient.name ?? 'Unknown Patient'}:',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _generateQuizReport(patient, patientInfo);
                      },
                      icon: const Icon(Icons.quiz_outlined),
                      label: Text(
                        'Quiz Report',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _generateEEGReport(patient, patientInfo);
                      },
                      icon: const Icon(Icons.monitor_heart_outlined),
                      label: Text(
                        'EEG Report',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Generate Quiz Report for the selected patient
  Future<void> _generateQuizReport(dynamic patient, PatientInfo patientInfo) async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Set patient context for data fetching
      final dataContext = Get.find<DataContextController>();
      dataContext.setPatientContext(patient.uid!, patient.name ?? 'Unknown Patient');

      // Fetch quiz history for the specific patient
      await getProfileController.fetchQuizHistory();

      // Close loading dialog
      Get.back();

      // Generate the quiz report with proper patient data
      await generateQuizReport(
        getProfileController.quizHistory,
        Profile(
          name: patient.name ?? 'Unknown Patient',
          uid: patient.uid!,
          username: patient.username ?? 'N/A',
          email: patient.email ?? 'Not provided',
          contact: patient.contact ?? 'Not provided',
          age: patient.age,
          gender: 'Not provided',
          address: 'Not provided',
        ),
      );

      // Clear patient context after report generation
      dataContext.clearPatientContext();

      // Show success message
      Get.snackbar(
        'Success',
        'Quiz report generated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) Get.back();
      
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to generate quiz report: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Generate EEG Report for the selected patient
  Future<void> _generateEEGReport(dynamic patient, PatientInfo patientInfo) async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Set patient context for data fetching
      final dataContext = Get.find<DataContextController>();
      dataContext.setPatientContext(patient.uid!, patient.name ?? 'Unknown Patient');

      // Fetch brain scores for the specific patient
      await getProfileController.fetchBrainScore(patient.uid!);

      // Close loading dialog
      Get.back();

      // Generate the EEG report with brain scores
      await generatEEGReport(getProfileController.brainScores);

      // Clear patient context after report generation
      dataContext.clearPatientContext();

      // Show success message
      Get.snackbar(
        'Success',
        'EEG report generated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) Get.back();
      
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to generate EEG report: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
