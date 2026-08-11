import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/patientSideControllers/getProfileController.dart';
import '../../controllers/data_context_controller.dart';
import '../../utils/reportGenerator/eegReportGenerator.dart';

class DetailedEEGHistory extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  
  const DetailedEEGHistory({
    super.key,
    this.patientId,
    this.patientName,
  });

  @override
  State<DetailedEEGHistory> createState() => _DetailedEEGHistoryState();
}

class _DetailedEEGHistoryState extends State<DetailedEEGHistory>
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
    
    // Refresh data with new context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getProfileController.refreshData();
    });
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsOverview(),
                          const SizedBox(height: 30),
                          _buildEEGHistoryList(),
                        ],
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
            'EEG History',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await getProfileController.fetchBrainScore(null);
              await generatEEGReport(getProfileController.brainScores);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download_outlined,
                color: Color(0xFF00C6FF),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Obx(() {
      final brainScores = getProfileController.brainScores;
      final totalSessions = brainScores.length;
      
      double averageScore = 0.0;
      double highestScore = 0.0;
      double lowestScore = 100.0;
      
      if (brainScores.isNotEmpty) {
        double totalScore = 0.0;
        for (var score in brainScores) {
          final scoreValue = double.tryParse(score.score ?? '0') ?? 0.0;
          totalScore += scoreValue;
          if (scoreValue > highestScore) highestScore = scoreValue;
          if (scoreValue < lowestScore) lowestScore = scoreValue;
        }
        averageScore = totalScore / brainScores.length;
        if (brainScores.length == 1) lowestScore = highestScore;
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00C6FF).withValues(alpha: 0.2),
              const Color(0xFF0072FF).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EEG Statistics',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Sessions',
                    totalSessions.toString(),
                    Icons.psychology_outlined,
                    const Color(0xFF00C6FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Average Score',
                    '${averageScore.toInt()}',
                    Icons.analytics_rounded,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Highest Score',
                    '${highestScore.toInt()}',
                    Icons.star_outline,
                    const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Lowest Score',
                    '${lowestScore.toInt()}',
                    Icons.insights,
                    const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEEGHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All EEG Sessions',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        Obx(() {
          if (getProfileController.isLoading.value) {
            return _buildLoadingAnimation();
          } else if (getProfileController.brainScores.isEmpty) {
            return _buildEmptyState();
          } else {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: getProfileController.brainScores.length,
              itemBuilder: (context, index) {
                final eegData = getProfileController.brainScores[index];
                return _buildDetailedEEGCard(eegData, index);
              },
            );
          }
        }),
      ],
    );
  }

  Widget _buildDetailedEEGCard(dynamic eegData, int index) {
    final score = double.tryParse(eegData.score ?? '0') ?? 0.0;
    final timestamp = eegData.timestamp ?? '';
    final deviceId = eegData.deviceId ?? 'Unknown Device';
    final createdAt = eegData.createdAt;
    
    // Determine score level and color
    Color scoreColor;
    String scoreLevel;
    if (score <= 30) {
      scoreColor = const Color(0xFF4CAF50);
      scoreLevel = 'Good';
    } else if (score <= 60) {
      scoreColor = const Color(0xFFFF9800);
      scoreLevel = 'Moderate';
    } else {
      scoreColor = const Color(0xFFFF6B6B);
      scoreLevel = 'Needs Attention';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00C6FF).withValues(alpha: 0.1),
            const Color(0xFF0072FF).withValues(alpha: 0.05),
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
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFF00C6FF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EEG Session #${index + 1}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDetailedTimestamp(timestamp, createdAt),
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scoreLevel,
                  style: GoogleFonts.poppins(
                    color: scoreColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Depression Score',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${score.toInt()}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Device ID',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deviceId.length > 10 
                            ? '${deviceId.substring(0, 10)}...' 
                            : deviceId,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (score / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: scoreColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetailedTimestamp(String timestamp, dynamic createdAt) {
    try {
      DateTime dateTime;
      if (timestamp.isNotEmpty) {
        dateTime = DateTime.parse(timestamp);
      } else if (createdAt != null) {
        dateTime = createdAt is DateTime ? createdAt : DateTime.parse(createdAt.toString());
      } else {
        return 'Unknown date';
      }
      
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildLoadingAnimation() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          for (int i = 0; i < 5; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: const Alignment(-1.0, 0.0),
                  end: const Alignment(1.0, 0.0),
                ),
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                tween: Tween(begin: -1.0, end: 1.0),
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment(value - 0.3, 0.0),
                        end: Alignment(value + 0.3, 0.0),
                      ),
                    ),
                  );
                },
                onEnd: () {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ),
        ],
      ),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00C6FF).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_outlined,
              color: Color(0xFF00C6FF),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No EEG Data',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first EEG session to see your brain activity data here',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
