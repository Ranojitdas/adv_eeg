import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../controllers/patientSideControllers/getProfileController.dart';
import '../../controllers/data_context_controller.dart';

class DetailedQuizHistory extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  
  const DetailedQuizHistory({
    super.key,
    this.patientId,
    this.patientName,
  });

  @override
  State<DetailedQuizHistory> createState() => _DetailedQuizHistoryState();
}

class _DetailedQuizHistoryState extends State<DetailedQuizHistory>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final GetProflieController getProfileController = Get.put(GetProflieController());
  final DataContextController _dataContext = Get.find<DataContextController>();

  @override
  void initState() {
    super.initState();
    
    // Set patient context if provided (for relative viewing patient data)
    if (widget.patientId != null && widget.patientName != null) {
      _dataContext.setPatientContext(widget.patientId!, widget.patientName!);
    }
    
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
    
    // Refresh data with new context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getProfileController.refreshData();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Clear patient context when leaving screen if it was set by this screen
    if (widget.patientId != null) {
      _dataContext.clearPatientContext();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
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
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: RefreshIndicator(
                      onRefresh: () => getProfileController.fetchQuizHistory(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsHeader(),
                            const SizedBox(height: 24),
                            _buildQuizList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            'Quiz History',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 3000),
      curve: Curves.easeInOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  const Color(0xFF00BCD4).withValues(alpha: 0.15),
                  const Color(0xFF4FC3F7).withValues(alpha: 0.25),
                  (math.sin(value * math.pi * 2) + 1) / 2,
                )!,
                Color.lerp(
                  const Color(0xFF0097A7).withValues(alpha: 0.1),
                  const Color(0xFF29B6F6).withValues(alpha: 0.15),
                  (math.sin(value * math.pi * 2) + 1) / 2,
                )!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.lerp(
                Colors.white.withValues(alpha: 0.1),
                const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                (math.sin(value * math.pi * 2) + 1) / 2,
              )!,
              width: 1 + ((math.sin(value * math.pi * 2) + 1) / 2) * 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.1 * ((math.sin(value * math.pi * 2) + 1) / 2)),
                blurRadius: 12 * ((math.sin(value * math.pi * 2) + 1) / 2),
                spreadRadius: 2 * ((math.sin(value * math.pi * 2) + 1) / 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Quizzes',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      '${getProfileController.quizHistory.length}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    )),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 2000),
                curve: Curves.easeInOut,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, iconValue, child) {
                  return Transform.scale(
                    scale: 1.0 + (math.sin(iconValue * math.pi * 2) * 0.05),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFF00BCD4).withValues(alpha: 0.2),
                          const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                          (math.sin(iconValue * math.pi * 2) + 1) / 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4FC3F7).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        color: const Color(0xFF4FC3F7),
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizList() {
    return Obx(() {
      if (getProfileController.quizHistory.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Quiz Attempts',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: getProfileController.quizHistory.length,
            itemBuilder: (context, index) {
              final quiz = getProfileController.quizHistory[index];
              return _buildDetailedQuizCard(quiz, index);
            },
          ),
        ],
      );
    });
  }

  Widget _buildDetailedQuizCard(Map<String, dynamic> quiz, int index) {
    final quizType = quiz['questionnaireType'] ?? 'Unknown';
    final score = quiz['score'] ?? 0;
    final completedAt = quiz['completedAt'] ?? quiz['createdAt'];
    final status = quiz['status'] ?? 'completed';
    
    // Get depression level based on quiz type and score
    String depressionLevel = 'Normal';
    Color levelColor = Colors.green;
    
    if (quizType == 'HAM_D') {
      if (score >= 0 && score <= 7) {
        depressionLevel = 'Normal';
        levelColor = const Color(0xFF4CAF50);
      } else if (score >= 8 && score <= 13) {
        depressionLevel = 'Mild Depression';
        levelColor = const Color(0xFF8BC34A);
      } else if (score >= 14 && score <= 18) {
        depressionLevel = 'Moderate Depression';
        levelColor = const Color(0xFFFFEB3B);
      } else if (score >= 19 && score <= 22) {
        depressionLevel = 'Severe Depression';
        levelColor = const Color(0xFFFF9800);
      } else if (score >= 23) {
        depressionLevel = 'Very Severe Depression';
        levelColor = const Color(0xFFF44336);
      }
    } else if (quizType == 'BDI' || quizType == 'BDI') {
      if (score >= 1 && score <= 10) {
        depressionLevel = 'Normal';
        levelColor = const Color(0xFF4CAF50);
      } else if (score >= 11 && score <= 16) {
        depressionLevel = 'Mild mood disturbance';
        levelColor = const Color(0xFF8BC34A);
      } else if (score >= 17 && score <= 20) {
        depressionLevel = 'Borderline clinical depression';
        levelColor = const Color(0xFFFFEB3B);
      } else if (score >= 21 && score <= 30) {
        depressionLevel = 'Moderate depression';
        levelColor = const Color(0xFFFF9800);
      } else if (score >= 31 && score <= 40) {
        depressionLevel = 'Severe depression';
        levelColor = const Color(0xFFF44336);
      } else if (score > 40) {
        depressionLevel = 'Extreme depression';
        levelColor = const Color(0xFFD32F2F);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withValues(alpha: 0.1),
            const Color(0xFF3F3D9E).withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  color: Color(0xFF6C63FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${quizType} Assessment',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quiz #${index + 1}',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Score', '$score', Icons.score_outlined),
              ),
              Expanded(
                child: _buildInfoItem('Level', depressionLevel, Icons.psychology_outlined, levelColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('Completed', _formatDate(completedAt), Icons.schedule_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, [Color? valueColor]) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.6),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: valueColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Quiz History',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first assessment to see your quiz history here',
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

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
