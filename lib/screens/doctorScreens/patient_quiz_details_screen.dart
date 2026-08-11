import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/patientSideControllers/getProfileController.dart';
import '../../Constants/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PatientQuizDetailsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientQuizDetailsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientQuizDetailsScreen> createState() => _PatientQuizDetailsScreenState();
}

class _PatientQuizDetailsScreenState extends State<PatientQuizDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late GetProflieController _profileController;
  
  var quizHistory = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

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

    _profileController = Get.put(GetProflieController());
    _fetchPatientQuizzes();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchPatientQuizzes() async {
    try {
      isLoading.value = true;
      print('📋 [PATIENT_QUIZ] Fetching all quizzes for patient: ${widget.patientId}');
      
      // Use patient-specific quiz history endpoint
      final response = await http.get(
        Uri.parse(Constants.getQuizHistory(widget.patientId)),
        headers: Constants.authHeader,
      );
      
      print('📋 [PATIENT_QUIZ] Response status: ${response.statusCode}');
      print('📋 [PATIENT_QUIZ] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> quizzes = data['data'];
          List<Map<String, dynamic>> processedHistory = [];
          
          for (var quiz in quizzes) {
            Map<String, dynamic> quizMap = Map<String, dynamic>.from(quiz);
            // Include all quizzes in history (assigned, completed, etc.)
            processedHistory.add(quizMap);
          }
          
          quizHistory.value = processedHistory;
          print('📋 [PATIENT_QUIZ] Found ${processedHistory.length} total quizzes');
        } else {
          quizHistory.value = [];
        }
      } else {
        quizHistory.value = [];
      }
      
    } catch (e) {
      print('📋 [PATIENT_QUIZ] Error fetching patient quizzes: $e');
      quizHistory.value = [];
    } finally {
      isLoading.value = false;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E293B)),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Assessment History',
              style: GoogleFonts.inter(
                color: const Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.patientName,
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F4FF),
              Color(0xFFE6EFFF),
            ],
          ),
        ),
        child: Column(
          children: [
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: RefreshIndicator(
                      onRefresh: _fetchPatientQuizzes,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
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
              ),
            ],
        ),
      ),
    );
  }


  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assessment_outlined,
              color: Color(0xFF3B82F6),
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Assessments',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  '${quizHistory.length}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1E293B),
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                )),
              ],
            ),
          ),
          Obx(() {
            final completed = quizHistory.where((q) => 
              (q['responses'] as List).isNotEmpty && 
              (q['responses'] as List).every((r) => r['selectedOptionId'] != null)
            ).length;
            final pending = quizHistory.length - completed;
            
            return Row(
              children: [
                _buildStatItem('Completed', completed, const Color(0xFF059669)),
                const SizedBox(width: 20),
                _buildStatItem('Pending', pending, const Color(0xFFEF4444)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: GoogleFonts.inter(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizList() {
    return Obx(() {
      if (isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
        );
      }

      if (quizHistory.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Assessment History',
              style: GoogleFonts.inter(
                color: const Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quizHistory.length,
              itemBuilder: (context, index) {
                final quiz = quizHistory[index];
                return _buildDetailedQuizCard(quiz, index);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Quiz History',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This patient hasn\'t completed any quizzes yet',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedQuizCard(Map<String, dynamic> quiz, int index) {
    final quizType = quiz['questionnaireType'] ?? 'Unknown';
    final responses = quiz['responses'] ?? [];
    final completedAt = quiz['completedAt'] ?? quiz['assignedAt'] ?? quiz['createdAt'];
    final status = quiz['status'] ?? 'assigned';
    final isAssigned = quiz['isSelfInitiated'] != true;
    
    // Calculate score from responses if not provided
    int calculatedScore = 0;
    if (responses.isNotEmpty) {
      for (var response in responses) {
        if (response['selectedOptionId'] != null) {
          calculatedScore += (response['selectedOptionId'] as int);
        }
      }
    }
    final score = quiz['score'] ?? calculatedScore;
    
    // Determine if quiz is actually completed based on responses
    final isCompleted = responses.isNotEmpty && responses.every((r) => r['selectedOptionId'] != null);
    
    // Get depression level based on quiz type and score
    String depressionLevel = isCompleted ? 'Normal' : 'Pending';
    Color levelColor = isCompleted ? Colors.green : Colors.orange;
    
    // Only calculate depression level if quiz has responses and score
    if (isCompleted && score > 0) {
      depressionLevel = 'Normal';
      levelColor = Colors.green;
      
      if (quizType == 'HAM_D' || quizType == 'HAM-D') {
        if (score >= 23) {
          depressionLevel = 'Severe';
          levelColor = Colors.red;
        } else if (score >= 19) {
          depressionLevel = 'Moderate';
          levelColor = Colors.orange;
        } else if (score >= 14) {
          depressionLevel = 'Mild';
          levelColor = Colors.yellow;
        }
      } else if (quizType == 'BDI' || quizType == 'BDI') {
        if (score >= 29) {
          depressionLevel = 'Severe';
          levelColor = Colors.red;
        } else if (score >= 20) {
          depressionLevel = 'Moderate';
          levelColor = Colors.orange;
        } else if (score >= 14) {
          depressionLevel = 'Mild';
          levelColor = Colors.yellow;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD1E7FF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quizType == 'HAM_D' || quizType == 'HAM-D' 
                          ? 'Hamilton Depression Scale' 
                          : quizType == 'BDI' || quizType == 'BDI'
                              ? 'Beck Depression Inventory'
                              : quizType,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1E293B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(depressionLevel).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _getSeverityColor(depressionLevel).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      depressionLevel,
                      style: GoogleFonts.inter(
                        color: _getSeverityColor(depressionLevel),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${responses.length} questions ${isCompleted ? 'completed' : 'pending'}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isAssigned ? const Color(0xFF059669).withValues(alpha: 0.1) : const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isAssigned ? 'Assigned' : 'Self',
                      style: GoogleFonts.inter(
                        color: isAssigned ? const Color(0xFF059669) : const Color(0xFF7C3AED),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted ? '$score' : 'Pending',
                      style: GoogleFonts.inter(
                        color: isCompleted ? const Color(0xFF1E293B) : const Color(0xFFEF4444),
                        fontSize: isCompleted ? 18 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'Completed' : 'Assigned',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(completedAt),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDepressionLevel(String quizType, dynamic score) {
    if (score == null || score == 'N/A') return 'Unknown';
    
    int scoreInt = 0;
    if (score is String) {
      scoreInt = int.tryParse(score) ?? 0;
    } else if (score is int) {
      scoreInt = score;
    }
    
    if (quizType == 'HAM_D' || quizType == 'HAM-D') {
      if (scoreInt >= 23) return 'Severe';
      if (scoreInt >= 19) return 'Moderate';
      if (scoreInt >= 14) return 'Mild';
      return 'Normal';
    } else if (quizType == 'BDI' || quizType == 'BDI') {
      if (scoreInt >= 29) return 'Severe';
      if (scoreInt >= 20) return 'Moderate';
      if (scoreInt >= 14) return 'Mild';
      return 'Normal';
    }
    return 'Normal';
  }

  Color _getLevelColor(String quizType) {
    // This will be updated based on actual score in the card
    return Colors.green;
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

  Color _getSeverityColor(String level) {
    switch (level.toLowerCase()) {
      case 'severe':
        return const Color(0xFFDC2626);
      case 'moderate':
        return const Color(0xFFEA580C);
      case 'mild':
        return const Color(0xFFCA8A04);
      case 'normal':
        return const Color(0xFF059669);
      case 'pending':
      case 'awaiting response':
        return const Color(0xFF7C2D12);
      default:
        return const Color(0xFF64748B);
    }
  }
}
