import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../controllers/patientSideControllers/getProfileController.dart';
import '../../controllers/data_context_controller.dart';
import '../../models/brainScoreModel.dart';

enum ChartType { quiz, eeg }

class AnalyticsChartPage extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  final ChartType chartType;
  final String title;
  
  const AnalyticsChartPage({
    super.key,
    this.patientId,
    this.patientName,
    required this.chartType,
    required this.title,
  });

  @override
  State<AnalyticsChartPage> createState() => _AnalyticsChartPageState();
}

class _AnalyticsChartPageState extends State<AnalyticsChartPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;
  
  final GetProflieController getProfileController = Get.put(GetProflieController());
  final DataContextController _dataContext = Get.find<DataContextController>();
  String selectedPeriod = '7 Days';
  final List<String> periods = ['7 Days', '1 Month', '3 Months', '6 Months', '1 Year'];

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
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
    
    // Delay chart animation for better effect
    Future.delayed(const Duration(milliseconds: 500), () {
      _chartController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _chartController.dispose();
    // Clear patient context when leaving screen if it was set by this screen
    if (widget.patientId != null) {
      _dataContext.clearPatientContext();
    }
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
          widget.title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: _exportChart,
            tooltip: 'Export Chart',
          ),
        ],
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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20.0 : 32.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Stats
                    _buildHeaderStats(),
                    const SizedBox(height: 24),
                    
                    // Visual Performance Overview
                    _buildPerformanceOverview(),
                    const SizedBox(height: 24),
                    
                    // Period Selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    
                    // Main Chart
                    _buildMainChart(),
                    const SizedBox(height: 24),
                    
                    // Visual Progress Indicators
                    _buildProgressIndicators(),
                    const SizedBox(height: 24),
                    
                    // Insights Cards
                    _buildInsightsSection(),
                    const SizedBox(height: 24),
                    
                    // Score Distribution
                    _buildScoreDistribution(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    final isQuiz = widget.chartType == ChartType.quiz;
    final data = isQuiz ? getProfileController.quizHistory : getProfileController.brainScores;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isQuiz 
            ? [const Color(0xFF6C63FF), const Color(0xFF3F3D9E)]
            : [const Color(0xFFFF6B6B), const Color(0xFFEE5A24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isQuiz ? const Color(0xFF6C63FF) : const Color(0xFFFF6B6B)).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
              isQuiz ? Icons.quiz_rounded : Icons.memory_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isQuiz ? 'Quiz Performance' : 'EEG Analysis',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isQuiz 
                    ? '${data.length} assessments completed'
                    : '${data.length} brain signal sessions',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                _getChartAverageScore().toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Avg Score',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = period == selectedPeriod;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedPeriod = period;
              });
              _chartController.reset();
              _chartController.forward();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                  ? LinearGradient(
                      colors: widget.chartType == ChartType.quiz
                        ? [const Color(0xFF6C63FF), const Color(0xFF3F3D9E)]
                        : [const Color(0xFFFF6B6B), const Color(0xFFEE5A24)],
                    )
                  : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected 
                    ? Colors.transparent 
                    : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                period,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainChart() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Trend',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildLineChart(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLineChart() {
    final data = _getChartData();
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.chartType == ChartType.quiz ? Icons.quiz_outlined : Icons.memory_outlined,
              color: Colors.white.withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              widget.chartType == ChartType.quiz 
                ? 'No quiz data available'
                : 'No EEG data available',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return CustomPaint(
      size: Size.infinite,
      painter: LineChartPainter(
        data: data,
        animation: _chartAnimation.value,
        chartType: widget.chartType,
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInsightCard(
              'Lowest Score', 
              _getBestScore().toStringAsFixed(1), 
              Icons.trending_down_rounded, 
              Colors.green
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildInsightCard('Improvement', '+${_getImprovement().toStringAsFixed(1)}%', Icons.show_chart_rounded, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  List<ChartPoint> _getChartData() {
    final isQuiz = widget.chartType == ChartType.quiz;
    
    if (isQuiz) {
      final quizData = getProfileController.quizHistory;
      if (quizData.isEmpty) return [];
      
      return quizData.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        
        double score = 0;
        DateTime? date;
        if (item is Map<String, dynamic>) {
          score = (item['score'] ?? 0).toDouble();
          // Try to get date from various possible fields
          final dateStr = item['createdAt'] ?? item['date'] ?? item['timestamp'];
          if (dateStr != null) {
            try {
              date = DateTime.parse(dateStr.toString());
            } catch (e) {
              // Fallback to current date if parsing fails
              date = DateTime.now().subtract(Duration(days: quizData.length - index));
            }
          } else {
            // Generate dates going backwards from today
            date = DateTime.now().subtract(Duration(days: quizData.length - index));
          }
        }
        
        return ChartPoint(date?.millisecondsSinceEpoch.toDouble() ?? index.toDouble(), score, date: date);
      }).toList();
    } else {
      final eegData = getProfileController.brainScores;
      if (eegData.isEmpty) return [];
      
      return eegData.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        
        double score = 0;
        DateTime? date;
        if (item is BrainScoreModel) {
          final scoreStr = item.score ?? '0';
          score = double.tryParse(scoreStr) ?? 0;
          // Normalize EEG score to 0-100 range
          if (score > 100) {
            score = math.log(score + 1) * 20; // Logarithmic scaling
          }
          score = score.clamp(0, 100);
          
          // Try to get date from timestamp
          final timestampStr = item.timestamp;
          if (timestampStr != null && timestampStr.isNotEmpty) {
            try {
              date = DateTime.parse(timestampStr);
            } catch (e) {
              // Fallback to current date if parsing fails
              date = DateTime.now().subtract(Duration(days: eegData.length - index));
            }
          } else {
            // Generate dates going backwards from today
            date = DateTime.now().subtract(Duration(days: eegData.length - index));
          }
        }
        
        return ChartPoint(date?.millisecondsSinceEpoch.toDouble() ?? index.toDouble(), score, date: date);
      }).toList();
    }
  }

  double _getChartAverageScore() {
    final data = _getChartData();
    if (data.isEmpty) return 0;
    
    double total = 0;
    for (var point in data) {
      total += point.y;
    }
    
    return total / data.length;
  }

  double _getBestScore() {
    final data = _getChartData();
    if (data.isEmpty) return 0;
    
    // For both EEG and Quiz (HAM_D/BDI): lower scores are better (less depression/risk)
    return data.map((point) => point.y).reduce(math.min);
  }

  double _getImprovement() {
    final data = _getChartData();
    if (data.length < 2) return 0;
    
    final first = data.first.y;
    final last = data.last.y;
    
    if (first == 0) return 0;
    
    // For both EEG and Quiz (HAM_D/BDI): improvement means scores going DOWN (less depression)
    final rawImprovement = ((last - first) / first) * 100;
    
    return -rawImprovement; // Negative because lower scores = better
  }


  double _getDataAverageScore() {
    final isQuiz = widget.chartType == ChartType.quiz;
    final data = isQuiz ? getProfileController.quizHistory : getProfileController.brainScores;
    
    if (data.isEmpty) return 0.0;
    
    double total = 0.0;
    for (var item in data) {
      if (isQuiz) {
        final quizItem = item as Map<String, dynamic>;
        total += (quizItem['score'] ?? 0).toDouble();
      } else {
        // Cast to BrainScoreModel and access score property
        final brainScore = item as BrainScoreModel;
        total += double.tryParse(brainScore.score ?? '0') ?? 0.0;
      }
    }
    
    return total / data.length;
  }

  double _getHighestScore() {
    final isQuiz = widget.chartType == ChartType.quiz;
    final data = isQuiz ? getProfileController.quizHistory : getProfileController.brainScores;
    
    if (data.isEmpty) return 0.0;
    
    double highest = 0.0;
    for (var item in data) {
      double score;
      if (isQuiz) {
        final quizItem = item as Map<String, dynamic>;
        score = (quizItem['score'] ?? 0).toDouble();
      } else {
        final brainScore = item as BrainScoreModel;
        score = double.tryParse(brainScore.score ?? '0') ?? 0.0;
      }
      if (score > highest) highest = score;
    }
    
    return highest;
  }

  double _getLowestScore() {
    final isQuiz = widget.chartType == ChartType.quiz;
    final data = isQuiz ? getProfileController.quizHistory : getProfileController.brainScores;
    
    if (data.isEmpty) return 0.0;
    
    double lowest = double.infinity;
    for (var item in data) {
      double score;
      if (isQuiz) {
        final quizItem = item as Map<String, dynamic>;
        score = (quizItem['score'] ?? 0).toDouble();
      } else {
        final brainScore = item as BrainScoreModel;
        score = double.tryParse(brainScore.score ?? '0') ?? 0.0;
      }
      if (score < lowest) lowest = score;
    }
    
    return lowest == double.infinity ? 0.0 : lowest;
  }


  Widget _buildPerformanceOverview() {
    final isQuiz = widget.chartType == ChartType.quiz;
    final avgScore = _getDataAverageScore();
    final highestScore = _getHighestScore();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Current Avg',
                  avgScore.toStringAsFixed(1),
                  Icons.trending_up_rounded,
                  isQuiz ? const Color(0xFF6C63FF) : const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPerformanceCard(
                  'Best Score',
                  highestScore.toStringAsFixed(1),
                  Icons.star_rounded,
                  const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicators() {
    final isQuiz = widget.chartType == ChartType.quiz;
    final avgScore = _getDataAverageScore();
    final progress = avgScore / 100.0; // Assuming max score is 100
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Indicators',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          // Circular Progress
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isQuiz ? const Color(0xFF6C63FF) : const Color(0xFFFF6B6B),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Performance',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProgressBar('Consistency', 0.75, const Color(0xFF4CAF50)),
                    const SizedBox(height: 8),
                    _buildProgressBar('Improvement', progress, isQuiz ? const Color(0xFF6C63FF) : const Color(0xFFFF6B6B)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDistribution() {
    final isQuiz = widget.chartType == ChartType.quiz;
    final data = isQuiz ? getProfileController.quizHistory : getProfileController.brainScores;
    
    // Calculate score ranges
    Map<String, int> distribution = widget.chartType == ChartType.quiz ? {
      '1-10': 0,    // Normal
      '11-16': 0,   // Mild mood disturbance
      '17-20': 0,   // Borderline clinical depression
      '21-30': 0,   // Moderate depression
      '31-40': 0,   // Severe depression
      '40+': 0,     // Extreme depression
    } : {
      '0-20': 0,
      '21-40': 0,
      '41-60': 0,
      '61-80': 0,
      '81-100': 0,
    };
    
    for (var item in data) {
      double score;
      if (isQuiz) {
        final quizScore = item as Map<String, dynamic>;
        score = (quizScore['score'] as num?)?.toDouble() ?? 0.0;
        // Quiz distribution based on depression scale
        if (score >= 1 && score <= 10) distribution['1-10'] = distribution['1-10']! + 1;
        else if (score >= 11 && score <= 16) distribution['11-16'] = distribution['11-16']! + 1;
        else if (score >= 17 && score <= 20) distribution['17-20'] = distribution['17-20']! + 1;
        else if (score >= 21 && score <= 30) distribution['21-30'] = distribution['21-30']! + 1;
        else if (score >= 31 && score <= 40) distribution['31-40'] = distribution['31-40']! + 1;
        else if (score > 40) distribution['40+'] = distribution['40+']! + 1;
      } else {
        final brainScore = item as BrainScoreModel;
        score = double.tryParse(brainScore.score ?? '0') ?? 0.0;
        // EEG distribution
        if (score <= 20) distribution['0-20'] = distribution['0-20']! + 1;
        else if (score <= 40) distribution['21-40'] = distribution['21-40']! + 1;
        else if (score <= 60) distribution['41-60'] = distribution['41-60']! + 1;
        else if (score <= 80) distribution['61-80'] = distribution['61-80']! + 1;
        else distribution['81-100'] = distribution['81-100']! + 1;
      }
    }
    
    int maxCount = distribution.values.reduce(math.max);
    if (maxCount == 0) maxCount = 1;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Distribution',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...distribution.entries.map((entry) {
            double percentage = entry.value / maxCount;
            Color barColor = _getScoreRangeColor(entry.key);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${entry.value}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getScoreRangeColor(String range) {
    if (widget.chartType == ChartType.quiz) {
      // For Quiz (Depression Scale): Based on clinical ranges from image
      switch (range) {
        case '1-10': return const Color(0xFF4CAF50);   // Green - Normal
        case '11-16': return const Color(0xFF8BC34A);  // Light Green - Mild mood disturbance
        case '17-20': return const Color(0xFFFFEB3B);  // Yellow - Borderline clinical depression
        case '21-30': return const Color(0xFFFF9800);  // Orange - Moderate depression
        case '31-40': return const Color(0xFFF44336);  // Red - Severe depression
        case '40+': return const Color(0xFFD32F2F);    // Dark Red - Extreme depression
        default: return const Color(0xFF9E9E9E);
      }
    } else {
      // For EEG: Lower is better (green), Higher is worse (red)
      switch (range) {
        case '0-20': return const Color(0xFF4CAF50);   // Green - Best (lowest depression)
        case '21-40': return const Color(0xFF8BC34A);  // Light Green - Good
        case '41-60': return const Color(0xFFFFEB3B);  // Yellow - Moderate
        case '61-80': return const Color(0xFFFF9800);  // Orange - Concerning
        case '81-100': return const Color(0xFFF44336); // Red - Worst (highest depression)
        default: return const Color(0xFF9E9E9E);
      }
    }
  }

  void _exportChart() {
    Get.snackbar(
      'Export Chart',
      'Chart export functionality will be implemented',
      backgroundColor: widget.chartType == ChartType.quiz 
        ? const Color(0xFF6C63FF).withValues(alpha: 0.9)
        : const Color(0xFFFF6B6B).withValues(alpha: 0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}

class ChartPoint {
  final double x;
  final double y;
  final DateTime? date;
  
  ChartPoint(this.x, this.y, {this.date});
}

class LineChartPainter extends CustomPainter {
  final List<ChartPoint> data;
  final double animation;
  final ChartType chartType;
  
  LineChartPainter({
    required this.data,
    required this.animation,
    required this.chartType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    // Reserve space for labels
    final chartHeight = size.height - 40; // Reserve 40px for X-axis labels
    final chartWidth = size.width - 60; // Reserve 60px for Y-axis labels
    final chartRect = Rect.fromLTWH(60, 0, chartWidth, chartHeight);
    
    final paint = Paint()
      ..color = chartType == ChartType.quiz 
        ? const Color(0xFF6C63FF)
        : const Color(0xFFFF6B6B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (chartType == ChartType.quiz 
            ? const Color(0xFF6C63FF)
            : const Color(0xFFFF6B6B)).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(chartRect)
      ..style = PaintingStyle.fill;
    
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    
    final labelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    
    // Calculate Y-axis values with NaN protection
    if (data.isEmpty) return;
    
    final validData = data.where((p) => !p.y.isNaN && !p.y.isInfinite).toList();
    if (validData.isEmpty) return;
    
    final maxY = validData.map((p) => p.y).reduce(math.max);
    final minY = validData.map((p) => p.y).reduce(math.min);
    final range = maxY - minY == 0 ? 1 : maxY - minY;
    
    // Draw Y-axis grid and labels
    for (int i = 0; i <= 4; i++) {
      final y = chartRect.top + (chartHeight / 4) * i;
      final value = maxY - (range / 4) * i;
      
      // Draw horizontal grid line
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      
      // Draw Y-axis label
      final textSpan = TextSpan(
        text: value.toInt().toString(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }
    
    // Calculate chart points
    final points = <Offset>[];
    final chartPoints = <ChartPoint>[];
    
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = data.length > 1 
          ? chartRect.left + (chartWidth / (data.length - 1)) * i
          : chartRect.left + chartWidth / 2;
      final y = chartRect.top + chartHeight - ((point.y - minY) / range) * chartHeight;
      
      // Check for NaN values and provide fallbacks
      final safeX = x.isNaN || x.isInfinite ? chartRect.left : x;
      final safeY = y.isNaN || y.isInfinite ? chartRect.bottom : y;
      
      points.add(Offset(safeX, safeY));
      chartPoints.add(point);
    }
    
    // Draw X-axis labels (dates)
    final maxLabels = 5; // Maximum number of date labels to show
    final labelInterval = math.max(1, (data.length / maxLabels).ceil());
    
    for (int i = 0; i < data.length; i += labelInterval) {
      if (i < points.length && i < chartPoints.length) {
        final point = points[i];
        final chartPoint = chartPoints[i];
        
        String dateLabel = '';
        if (chartPoint.date != null) {
          final date = chartPoint.date!;
          dateLabel = '${date.day}/${date.month}';
        } else {
          dateLabel = (i + 1).toString();
        }
        
        final textSpan = TextSpan(
          text: dateLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final labelX = point.dx - textPainter.width / 2;
        final labelY = chartHeight + 5;
        
        // Check for NaN values in label positioning
        final safeLabelX = labelX.isNaN || labelX.isInfinite ? 0.0 : labelX;
        final safeLabelY = labelY.isNaN || labelY.isInfinite ? chartHeight + 5 : labelY;
        
        textPainter.paint(
          canvas, 
          Offset(safeLabelX, safeLabelY)
        );
      }
    }
    
    // Animate points
    final animatedPointCount = (points.length * animation).round();
    final animatedPoints = points.take(animatedPointCount).toList();
    
    if (animatedPoints.length < 2) return;
    
    // Draw fill area
    final fillPath = Path();
    fillPath.moveTo(animatedPoints.first.dx, chartRect.bottom);
    fillPath.lineTo(animatedPoints.first.dx, animatedPoints.first.dy);
    
    for (int i = 1; i < animatedPoints.length; i++) {
      fillPath.lineTo(animatedPoints[i].dx, animatedPoints[i].dy);
    }
    
    fillPath.lineTo(animatedPoints.last.dx, chartRect.bottom);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw line
    final path = Path();
    path.moveTo(animatedPoints.first.dx, animatedPoints.first.dy);
    
    for (int i = 1; i < animatedPoints.length; i++) {
      path.lineTo(animatedPoints[i].dx, animatedPoints[i].dy);
    }
    
    canvas.drawPath(path, paint);
    
    // Draw points
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final pointBorderPaint = Paint()
      ..color = chartType == ChartType.quiz 
        ? const Color(0xFF6C63FF)
        : const Color(0xFFFF6B6B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    for (final point in animatedPoints) {
      canvas.drawCircle(point, 6, pointBorderPaint);
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
