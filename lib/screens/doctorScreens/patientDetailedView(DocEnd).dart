import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../Constants/constants.dart';

import '../../controllers/doctor/getQuizData.dart';
import '../../models/doctor_model.dart';
import '../../models/chart_data.dart';

class PatientDetailedViewForDoc extends StatefulWidget {
  final PatientInfo patientInfo;
  const PatientDetailedViewForDoc(this.patientInfo, {super.key});

  @override
  State<PatientDetailedViewForDoc> createState() =>
      _PatientDetailedViewForDocState();
}

class _PatientDetailedViewForDocState extends State<PatientDetailedViewForDoc>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Method to show confirmation dialog and open Google Maps
  void _showOpenMapsDialog(BuildContext context, double lat, double lon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.map_outlined,
                color: const Color(0xFF0850FD),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Open in Google Maps',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Do you want to open this patient\'s location in Google Maps for detailed navigation?',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openGoogleMaps(lat, lon);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0850FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Open Maps',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to open Google Maps with the patient's location
  Future<void> _openGoogleMaps(double lat, double lon) async {
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
    final Uri uri = Uri.parse(googleMapsUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to generic maps URL
        final String fallbackUrl = 'geo:$lat,$lon';
        final Uri fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri);
        } else {
          // Show error message
          Get.snackbar(
            'Error',
            'Could not open maps application',
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
      Get.snackbar(
        'Error',
        'Could not open maps application',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // Fetch patient location from backend API
  Future<Map<String, dynamic>?> _getPatientLocationFromBackend(String patientId) async {
    try {
      print('📍 [DOCTOR] Fetching location for patient: $patientId');
      final apiService = ApiService();
      
      final response = await apiService.get(
        Constants.getUserById(patientId),
        requiresAuth: true,
      );

      if (response.success && response.rawData != null) {
        print('📍 [DOCTOR] Location API response: ${response.rawData}');
        final userData = response.rawData!['data'] ?? response.rawData;
        return userData;
      } else {
        print('📍 [DOCTOR] Failed to fetch location: ${response.message}');
        return null;
      }
    } catch (e) {
      print('📍 [DOCTOR] Error fetching location: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientId = widget.patientInfo.patient!.uid.toString();
    print('🏥 [DOCTOR_VIEW] Patient ID being used: $patientId');
    print('🏥 [DOCTOR_VIEW] Patient name: ${widget.patientInfo.patient?.name}');
    
    GetQuizController getQuizController =
        Get.put(GetQuizController(patientId));

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Obx(
      () => ModalProgressHUD(
        inAsyncCall: getQuizController.isLoading.value,
        progressIndicator: Container(
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0850FD)),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Patient Data',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1A1A1A),
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Patient Details',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Scrollbar(
                  radius: const Radius.circular(5),
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPatientHeader(
                            context, getQuizController, isSmallScreen),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Quiz Scores', isSmallScreen),
                        const SizedBox(height: 16),
                        _buildQuizChart(
                            context, getQuizController, isSmallScreen),
                        const SizedBox(height: 24),
                        _buildSectionTitle('EEG Scores', isSmallScreen),
                        const SizedBox(height: 16),
                        _buildEegChart(
                            context, getQuizController, isSmallScreen),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Patient Location', isSmallScreen),
                        const SizedBox(height: 16),
                        _buildLocationCard(
                            context, getQuizController, isSmallScreen),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context,
      GetQuizController getQuizController, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
        vertical: 16.0,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF0850FD).withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0850FD).withValues(alpha: 0.8),
                  const Color(0xFF6C63FF).withValues(alpha: 0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0850FD).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A1A1A),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=3'),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientInfo.patient?.name ?? 'Unknown Patient',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => _buildInfoRow(
                  'Recent Quiz Score',
                  getQuizController.chartData.isNotEmpty
                      ? getQuizController.chartData.last.y.toString()
                      : 'No Quiz Data',
                  Icons.quiz_outlined,
                )),
                const SizedBox(height: 8),
                Obx(() => _buildInfoRow(
                  'Recent EEG Score',
                  getQuizController.brainScore.isNotEmpty
                      ? getQuizController.brainScore.last.y.toString()
                      : 'No EEG Data',
                  Icons.psychology_outlined,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0850FD).withValues(alpha: 0.2),
                  const Color(0xFF6C63FF).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF0850FD).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF64B5F6),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
        vertical: 8.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0850FD).withValues(alpha: 0.1),
            const Color(0xFF6C63FF).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0850FD).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0850FD),
                  Color(0xFF6C63FF),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0850FD).withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizChart(BuildContext context,
      GetQuizController getQuizController, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFF0850FD).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0850FD).withValues(alpha: 0.2),
                      const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  color: Color(0xFF81C784),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quiz Score History',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Obx(() {
              if (getQuizController.chartData.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.quiz_outlined,
                            size: 48,
                            color: const Color(0xFF0850FD).withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Quiz Data Available',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Patient hasn\'t completed any quizzes yet',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  dateFormat: DateFormat('MMM dd'),
                  intervalType: DateTimeIntervalType.days,
                  autoScrollingDelta: 7,
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: MajorGridLines(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                plotAreaBorderWidth: 0,
                backgroundColor: Colors.transparent,
                series: <CartesianSeries<dynamic, dynamic>>[
                  LineSeries<ChartData, DateTime>(
                    dataSource: getQuizController.chartData,
                    pointColorMapper: (ChartData data, _) {
                      // Color based on quiz type and score
                      if (data.type == 'HAM_D') {
                        return data.y! >= 19 ? Colors.red : data.y! >= 14 ? Colors.orange : Colors.green;
                      } else {
                        return data.y! >= 20 ? Colors.red : data.y! >= 13 ? Colors.orange : Colors.green;
                      }
                    },
                    name: 'Quiz Score',
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      borderWidth: 2,
                      borderColor: Colors.white,
                    ),
                    dataLabelMapper: (datum, index) =>
                        '${datum.type}: ${datum.y}',
                  )
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPeriodButton('Weekly', getQuizController.quizSelectedPeriod.value == 'Weekly', () {
                getQuizController.quizSelectedPeriod.value = 'Weekly';
              }),
              const SizedBox(width: 8),
              _buildPeriodButton('Monthly', getQuizController.quizSelectedPeriod.value == 'Monthly', () {
                getQuizController.quizSelectedPeriod.value = 'Monthly';
              }),
              const SizedBox(width: 8),
              _buildPeriodButton('Yearly', getQuizController.quizSelectedPeriod.value == 'Yearly', () {
                getQuizController.quizSelectedPeriod.value = 'Yearly';
              }),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildEegChart(BuildContext context,
      GetQuizController getQuizController, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFF0850FD).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0850FD).withValues(alpha: 0.2),
                      const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFF64B5F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'EEG Score History',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Obx(() {
              if (getQuizController.brainScore.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.psychology_outlined,
                            size: 48,
                            color: const Color(0xFF0850FD).withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No EEG Data Available',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Patient hasn\'t recorded any brain signals yet',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat('MMM dd'),
                  intervalType: DateTimeIntervalType.days,
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: MajorGridLines(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                plotAreaBorderWidth: 0,
                backgroundColor: Colors.transparent,
                series: <CartesianSeries<dynamic, dynamic>>[
                  LineSeries<ChartData, DateTime>(
                    dataSource: getQuizController.brainScore,
                    pointColorMapper: (ChartData data, _) {
                      // Color based on EEG score ranges
                      if (data.y! >= 75) return Colors.red;        // Severe
                      if (data.y! >= 60) return Colors.orange;     // Moderate-Severe
                      if (data.y! >= 45) return Colors.yellow;     // Moderate
                      if (data.y! >= 30) return Colors.lightGreen; // Mild
                      return Colors.green;                          // Normal
                    },
                    name: 'EEG Score',
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      borderWidth: 2,
                      borderColor: Colors.white,
                    ),
                    dataLabelMapper: (datum, index) =>
                        '${datum.y}',
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPeriodButton('Weekly', getQuizController.eegSelectedPeriod.value == 'Weekly', () {
                getQuizController.eegSelectedPeriod.value = 'Weekly';
              }),
              const SizedBox(width: 8),
              _buildPeriodButton('Monthly', getQuizController.eegSelectedPeriod.value == 'Monthly', () {
                getQuizController.eegSelectedPeriod.value = 'Monthly';
              }),
              const SizedBox(width: 8),
              _buildPeriodButton('Yearly', getQuizController.eegSelectedPeriod.value == 'Yearly', () {
                getQuizController.eegSelectedPeriod.value = 'Yearly';
              }),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF0850FD).withValues(alpha: 0.8),
                    const Color(0xFF6C63FF).withValues(alpha: 0.6),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0850FD).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context,
      GetQuizController getQuizController, bool isSmallScreen) {
    final patientUid = widget.patientInfo.patient!.uid.toString();
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16.0 : 24.0, vertical: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patient Location',
              style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _getPatientLocationFromBackend(patientUid),
                builder: (context, snapshot) {
                  print('📍 [DOCTOR] Location data for $patientUid: ${snapshot.data}');
                  double? lat;
                  double? lon;
                  if (snapshot.hasData && snapshot.data != null) {
                    final locationData = snapshot.data!;
                    if (locationData['currentLocation'] != null && 
                        locationData['currentLocation']['coordinates'] != null) {
                      final coords = locationData['currentLocation']['coordinates'] as List;
                      if (coords.length >= 2) {
                        lat = (coords[0] as num?)?.toDouble();
                        lon = (coords[1] as num?)?.toDouble();
                      }
                    }
                  }
                  if (lat != null && lon != null) {
                    return FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lon),
                        initialZoom: 13,
                        onTap: (tapPosition, point) {
                          if (lat != null && lon != null) {
                            _showOpenMapsDialog(context, lat, lon);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 40,
                              height: 40,
                              point: LatLng(lat, lon),
                              child: const Icon(Icons.location_pin,
                                  color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Center(
                      child: Text(
                        'Location not available',
                        style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>?>(
            future: _getPatientLocationFromBackend(patientUid),
            builder: (context, snapshot) {
              double? lat;
              double? lon;
              if (snapshot.hasData && snapshot.data != null) {
                final locationData = snapshot.data!;
                if (locationData['currentLocation'] != null && 
                    locationData['currentLocation']['coordinates'] != null) {
                  final coords = locationData['currentLocation']['coordinates'] as List;
                  if (coords.length >= 2) {
                    lat = (coords[0] as num?)?.toDouble();
                    lon = (coords[1] as num?)?.toDouble();
                  }
                }
              }
              if (lat != null && lon != null) {
                return FutureBuilder<List<Placemark>>(
                  future: placemarkFromCoordinates(lat, lon),
                  builder: (context, placeSnapshot) {
                    if (placeSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (placeSnapshot.hasError ||
                        placeSnapshot.data == null ||
                        placeSnapshot.data!.isEmpty) {
                      return Text(
                        'Place name not available',
                        style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7)),
                      );
                    } else {
                      final placemark = placeSnapshot.data!.first;
                      final placeName = [
                        placemark.locality,
                        placemark.subLocality,
                        placemark.administrativeArea,
                        placemark.country
                      ].where((e) => e != null && e.isNotEmpty).join(', ');
                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place,
                                color: Color(0xFF0850FD), size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                placeName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          const SizedBox(height: 16),
          // Add Google Maps button
          FutureBuilder<Map<String, dynamic>?>(
            future: _getPatientLocationFromBackend(patientUid),
            builder: (context, snapshot) {
              double? lat;
              double? lon;
              if (snapshot.hasData && snapshot.data != null) {
                final locationData = snapshot.data!;
                if (locationData['currentLocation'] != null && 
                    locationData['currentLocation']['coordinates'] != null) {
                  final coords = locationData['currentLocation']['coordinates'] as List;
                  if (coords.length >= 2) {
                    lat = (coords[0] as num?)?.toDouble();
                    lon = (coords[1] as num?)?.toDouble();
                  }
                }
              }
              if (lat != null && lon != null) {
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 24.0,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (lat != null && lon != null) {
                        _openGoogleMaps(lat, lon);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0850FD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.map_outlined, size: 20),
                    label: Text(
                      'Open in Google Maps',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}

