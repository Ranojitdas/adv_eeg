import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/doctor/doctorview_controller.dart';

class AssignedQuizzesScreen extends StatefulWidget {
  const AssignedQuizzesScreen({super.key});

  @override
  State<AssignedQuizzesScreen> createState() => _AssignedQuizzesScreenState();
}

class _AssignedQuizzesScreenState extends State<AssignedQuizzesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late DoctorViewController doctorViewController;

  @override
  void initState() {
    super.initState();
    doctorViewController = Get.find<DoctorViewController>();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Assigned Quizzes',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              doctorViewController.getQuizAssignedByMe();
              Get.snackbar(
                'Refreshed',
                'Quiz data has been updated',
                backgroundColor: const Color(0xFF0850FD).withValues(alpha: 0.1),
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF2A2A2A).withValues(alpha: 0.8),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  // Header Stats
                  _buildHeaderStats(),
                  
                  // Quiz List
                  Expanded(
                    child: _buildQuizList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Obx(() {
      final totalQuizzes = doctorViewController.assignedQuizzes.length;
      final completedQuizzes = doctorViewController.assignedQuizzes
          .where((quiz) => quiz['status'] == 'completed')
          .length;
      final pendingQuizzes = totalQuizzes - completedQuizzes;

      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            _buildStatCard('Total', totalQuizzes.toString(), const Color(0xFF0850FD)),
            const SizedBox(width: 16),
            _buildStatCard('Completed', completedQuizzes.toString(), Colors.green),
            const SizedBox(width: 16),
            _buildStatCard('Pending', pendingQuizzes.toString(), Colors.orange),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizList() {
    return Obx(() {
      if (doctorViewController.assignedQuizzes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 80,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 20),
              Text(
                'No Assigned Quizzes',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: doctorViewController.assignedQuizzes.length,
        itemBuilder: (context, index) {
          final quiz = doctorViewController.assignedQuizzes[index];
          return _buildQuizCard(quiz, index);
        },
      );
    });
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz, int index) {
    final patientName = _getPatientName(quiz);
    final quizType = quiz['questionnaireType'] ?? 'Quiz';
    final status = quiz['status'] ?? 'assigned';
    final assignedAt = quiz['assignedAt'] ?? '';
    final score = quiz['score'];
    final completedAt = quiz['completedAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showQuizDetails(quiz);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getQuizTypeColor(quizType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getQuizTypeIcon(quizType),
                        color: _getQuizTypeColor(quizType),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$quizType Assessment',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Details Row
                Row(
                  children: [
                    _buildDetailItem(
                      Icons.calendar_today,
                      'Assigned',
                      _formatDate(assignedAt),
                    ),
                    if (status == 'completed' && score != null) ...[
                      const SizedBox(width: 20),
                      _buildDetailItem(
                        Icons.score,
                        'Score',
                        score.toString(),
                      ),
                    ],
                    if (status == 'completed' && completedAt != null) ...[
                      const SizedBox(width: 20),
                      _buildDetailItem(
                        Icons.check_circle,
                        'Completed',
                        _formatDate(completedAt),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action Row
                Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showQuizDetails(quiz),
                      icon: const Icon(
                        Icons.visibility,
                        size: 16,
                        color: Color(0xFF0850FD),
                      ),
                      label: Text(
                        'View Details',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0850FD),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.5),
          size: 16,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showQuizDetails(Map<String, dynamic> quiz) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Quiz Details',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Patient', _getPatientName(quiz)),
                    _buildDetailRow('Quiz Type', quiz['questionnaireType'] ?? 'Unknown'),
                    _buildDetailRow('Status', quiz['status'] ?? 'Unknown'),
                    _buildDetailRow('Assigned At', _formatDate(quiz['assignedAt'])),
                    if (quiz['score'] != null)
                      _buildDetailRow('Score', quiz['score'].toString()),
                    if (quiz['completedAt'] != null)
                      _buildDetailRow('Completed At', _formatDate(quiz['completedAt'])),
                    if (quiz['dueDate'] != null)
                      _buildDetailRow('Due Date', _formatDate(quiz['dueDate'])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
        return const Color(0xFF0850FD);
      default:
        return Colors.grey;
    }
  }

  Color _getQuizTypeColor(String quizType) {
    switch (quizType.toUpperCase()) {
      case 'HAM_D':
      case 'HAM-D':
        return Colors.purple;
      case 'BDI':
        return Colors.teal;
      default:
        return const Color(0xFF0850FD);
    }
  }

  IconData _getQuizTypeIcon(String quizType) {
    switch (quizType.toUpperCase()) {
      case 'HAM_D':
      case 'HAM-D':
        return Icons.psychology;
      case 'BDI':
        return Icons.mood;
      default:
        return Icons.quiz;
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
      String fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) {
        return fullName;
      }
    }
    
    return 'Unknown Patient';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
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
}
