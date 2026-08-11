import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../Constants/constants.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class BrainSignalController extends GetxController {
  var brainSignalScores = <Map<String, dynamic>>[].obs;
  var latestScore = <String, dynamic>{}.obs;
  var isLoading = false.obs;
  var isCollecting = false.obs;
  var currentSessionId = ''.obs;
  final NotificationService notificationService = Get.put(NotificationService());

  @override
  void onInit() {
    super.onInit();
    // Don't automatically load brain signal scores
    // Let screens call loadBrainSignalScores() and loadLatestScore() when needed
  }

  /// Store brain signal score (typically called by IoT devices)
  Future<bool> storeBrainSignalScore(String userId, String deviceId, double score, {String? timestamp}) async {
    try {
      final payload = {
        'userId': userId,
        'deviceId': deviceId,
        'score': score,
        'timestamp': timestamp ?? DateTime.now().toIso8601String(),
      };
      
      final response = await apiService.post(
        Constants.brainSignalStore,
        body: payload,
        requiresAuth: false, // IoT device endpoint doesn't require auth
      );
      
      if (response.success) {
        await loadBrainSignalScores();
        await loadLatestScore();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('❌ [BRAIN_SIGNAL] Exception storing brain signal score: $e');
      return false;
    }
  }

  /// Get all brain signal scores for current user
  Future<void> loadBrainSignalScores({String? userId}) async {
    try {
      isLoading.value = true;
      
      // Use provided userId or get from storage
      final targetUserId = userId ?? _getCurrentUserId();
      if (targetUserId.isEmpty) {
        print('🧠 [BRAIN_SIGNAL] ❌ No user ID available');
        return;
      }

      print('🧠 [BRAIN_SIGNAL] Loading brain signal scores for user: $targetUserId');

      final response = await apiService.get(
        Constants.getBrainSignalScores(targetUserId),
        requiresAuth: true,
      );

      if (response.success) {
        print('🧠 [BRAIN_SIGNAL] ✅ Brain signal scores loaded successfully');
        brainSignalScores.value = List<Map<String, dynamic>>.from(
          response.rawData?['data']?['scores'] ?? []
        );
      } else {
        print('🧠 [BRAIN_SIGNAL] ❌ Failed to load brain signal scores: ${response.message}');
        Get.snackbar('Error', 'Failed to load brain signal data');
      }
    } catch (e) {
      print('❌ [BRAIN_SIGNAL] Error loading brain signal scores: $e');
      Get.snackbar('Error', 'Something went wrong while loading brain signal data');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get latest brain signal score for current user
  Future<void> loadLatestScore({String? userId}) async {
    try {
      // Use provided userId or get from storage
      final targetUserId = userId ?? _getCurrentUserId();
      if (targetUserId.isEmpty) {
        print('🧠 [BRAIN_SIGNAL] ❌ No user ID available for latest score');
        return;
      }

      print('🧠 [BRAIN_SIGNAL] Loading latest brain signal score for user: $targetUserId');

      final response = await apiService.get(
        Constants.getBrainSignalLatestScore(targetUserId),
        requiresAuth: true,
      );

      if (response.success) {
        print('🧠 [BRAIN_SIGNAL] ✅ Latest brain signal score loaded');
        latestScore.value = response.rawData ?? {};
      } else if (response.statusCode == 404) {
        print('🧠 [BRAIN_SIGNAL] ⚠️ Latest score endpoint not found (404) - backend may not implement this endpoint yet');
        // Try to get latest from the regular scores endpoint as fallback
        if (brainSignalScores.isNotEmpty) {
          latestScore.value = brainSignalScores.first;
          print('🧠 [BRAIN_SIGNAL] ✅ Using latest score from scores list as fallback');
        }
      } else {
        print('🧠 [BRAIN_SIGNAL] ❌ Failed to load latest score: ${response.message}');
      }
    } catch (e) {
      print('❌ [BRAIN_SIGNAL] Error loading latest score: $e');
      // Try fallback approach
      if (brainSignalScores.isNotEmpty) {
        latestScore.value = brainSignalScores.first;
        print('🧠 [BRAIN_SIGNAL] ✅ Using fallback latest score from existing data');
      }
    }
  }

  /// Start EEG data collection session
  Future<bool> startDataCollection({
    required String deviceId,
    String? sessionName,
  }) async {
    try {
      isCollecting.value = true;
      currentSessionId.value = DateTime.now().millisecondsSinceEpoch.toString();
      
      print('🧠 [BRAIN_SIGNAL] Starting EEG data collection session: ${currentSessionId.value}');
      
      // This would typically initialize the EEG device connection
      // For now, we'll simulate the start of collection
      
      Get.snackbar(
        'Collection Started', 
        'EEG data collection has begun',
        snackPosition: SnackPosition.TOP,
      );
      
      return true;
    } catch (e) {
      print('❌ [BRAIN_SIGNAL] Error starting data collection: $e');
      isCollecting.value = false;
      return false;
    }
  }

  /// Stop EEG data collection session
  Future<void> stopDataCollection() async {
    try {
      print('🧠 [BRAIN_SIGNAL] Stopping EEG data collection session: ${currentSessionId.value}');
      
      isCollecting.value = false;
      currentSessionId.value = '';
      
      // Refresh data after collection
      await loadBrainSignalScores();
      await loadLatestScore();
      
      // Send notification to doctor about EEG completion
      await _notifyDoctorEEGCompleted();
      
      // Send notification to relatives about EEG completion
      await _notifyRelativesEEGCompleted();
      
      Get.snackbar(
        'Collection Stopped', 
        'EEG data collection has ended',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      print('❌ [BRAIN_SIGNAL] Error stopping data collection: $e');
    }
  }

  /// Notify doctor about EEG test completion
  Future<void> _notifyDoctorEEGCompleted() async {
    try {
      final userInfo = _getCurrentUserInfo();
      if (userInfo == null) return;

      final patientName = _getCurrentUserName();
      
      // Format EEG score to 1 decimal place for notifications
      final rawScore = latestScore.value['score'];
      String latestScoreValue = 'N/A';
      if (rawScore != null) {
        if (rawScore is Map && rawScore.containsKey('\$numberDecimal')) {
          final scoreDouble = double.tryParse(rawScore['\$numberDecimal'].toString()) ?? 0.0;
          latestScoreValue = scoreDouble.toStringAsFixed(1);
        } else {
          final scoreDouble = double.tryParse(rawScore.toString()) ?? 0.0;
          latestScoreValue = scoreDouble.toStringAsFixed(1);
        }
      }

      // Get patient's assigned doctor (this would need to be implemented based on your data structure)
      final doctorId = userInfo['assignedDoctor'] ?? userInfo['doctorId'];
      
      if (doctorId != null) {
        await notificationService.notifyDoctorEEGCompleted(
          doctorId: doctorId,
          patientName: patientName,
          eegScore: latestScoreValue,
        );
      }
    } catch (e) {
      print('❌ [BRAIN_SIGNAL] Error notifying doctor: $e');
    }
  }

  /// Notify relatives about EEG test completion
  Future<void> _notifyRelativesEEGCompleted() async {
    try {
      final userInfo = _getCurrentUserInfo();
      if (userInfo == null) return;

      final patientName = _getCurrentUserName();
      final relatives = userInfo['relatives'] ?? [];

      for (final relative in relatives) {
        final relativeId = relative['_id'] ?? relative['id'];
        if (relativeId != null) {
          // Format EEG score for relatives notification
          final rawScore = latestScore.value['score'];
          String formattedScore = 'N/A';
          if (rawScore != null) {
            if (rawScore is Map && rawScore.containsKey('\$numberDecimal')) {
              final scoreDouble = double.tryParse(rawScore['\$numberDecimal'].toString()) ?? 0.0;
              formattedScore = scoreDouble.toStringAsFixed(1);
            } else {
              final scoreDouble = double.tryParse(rawScore.toString()) ?? 0.0;
              formattedScore = scoreDouble.toStringAsFixed(1);
            }
          }
          
          await notificationService.notifyRelativePatientActivity(
            relativeId: relativeId,
            patientName: patientName,
            activityType: 'eeg_completed',
            additionalData: {
              'eegScore': formattedScore,
            },
          );
        }
      }
    } catch (e) {
      print('❌ [BRAIN_SIGNAL] Error notifying relatives: $e');
    }
  }

  /// Simulate real-time EEG data collection (for testing)
  Future<void> simulateEEGData({
    required String deviceId,
    int durationSeconds = 30,
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId.isEmpty) return;

      print('🧠 [BRAIN_SIGNAL] Simulating EEG data collection for $durationSeconds seconds');
      
      await startDataCollection(deviceId: deviceId);
      
      // Simulate data collection over time
      for (int i = 0; i < durationSeconds; i++) {
        if (!isCollecting.value) break;
        
        // Generate random score for simulation
        final randomScore = (50 + (i * 2) + (DateTime.now().millisecond % 20)).toString();
        
        await storeBrainSignalScore(
          userId,
          deviceId,
          double.parse(randomScore),
        );
        
        await Future.delayed(const Duration(seconds: 1));
      }
      
      await stopDataCollection();
    } catch (e) {
      print('❌ [BRAIN_SIGNAL] Error in EEG simulation: $e');
      await stopDataCollection();
    }
  }

  /// Calculate severity level from raw score (0-3 scale)
  int calculateSeverityLevel(double rawScore) {
    // Normalize large scores using logarithmic scaling
    double normalizedScore;
    if (rawScore > 1000) {
      normalizedScore = (log(rawScore.clamp(1000, 10000)) - log(1000)) / (log(10000) - log(1000)) * 100;
    } else if (rawScore > 100) {
      normalizedScore = sqrt(rawScore.clamp(100, 1000)) / sqrt(1000) * 100;
    } else {
      normalizedScore = rawScore.clamp(0, 100);
    }
    
    // Convert to severity levels (0-3)
    if (normalizedScore <= 25) return 0; // Minimal
    if (normalizedScore <= 50) return 1; // Mild  
    if (normalizedScore <= 75) return 2; // Moderate
    return 3; // Severe
  }

  /// Get severity level description
  String getSeverityDescription(int level) {
    switch (level) {
      case 0: return 'Minimal Depression';
      case 1: return 'Mild Depression';
      case 2: return 'Moderate Depression';
      case 3: return 'Severe Depression';
      default: return 'Unknown';
    }
  }

  /// Get severity level color
  int getSeverityColor(int level) {
    switch (level) {
      case 0: return 0xFF4CAF50; // Green
      case 1: return 0xFF8BC34A; // Light Green
      case 2: return 0xFFFF9800; // Orange
      case 3: return 0xFFF44336; // Red
      default: return 0xFF9E9E9E; // Grey
    }
  }

  /// Get brain signal analysis with severity levels
  Map<String, dynamic> getBrainSignalAnalysis() {
    if (brainSignalScores.isEmpty) {
      return {
        'hasData': false,
        'severityLevel': 0,
        'severityDescription': 'No Data Available',
        'totalReadings': 0,
        'trend': 'No trend available',
      };
    }

    final scores = brainSignalScores
        .map((s) => double.tryParse(s['score']?.toString() ?? '0') ?? 0)
        .toList();

    // Calculate latest severity level
    final latestScore = scores.isNotEmpty ? scores.last : 0.0;
    final latestSeverity = calculateSeverityLevel(latestScore);
    
    // Calculate trend based on severity levels
    String trend = 'Stable';
    if (scores.length >= 2) {
      final previousScore = scores[scores.length - 2];
      final previousSeverity = calculateSeverityLevel(previousScore);
      
      if (latestSeverity > previousSeverity) {
        trend = 'Worsening';
      } else if (latestSeverity < previousSeverity) {
        trend = 'Improving';
      }
    }
    
    return {
      'hasData': true,
      'severityLevel': latestSeverity,
      'severityDescription': getSeverityDescription(latestSeverity),
      'severityColor': getSeverityColor(latestSeverity),
      'totalReadings': scores.length,
      'trend': trend,
    };
  }

  /// Get brain signal trend analysis (legacy method for backward compatibility)
  Map<String, dynamic> getBrainSignalTrends() {
    final analysis = getBrainSignalAnalysis();
    
    if (!analysis['hasData']) {
      return {
        'trend': 'No data available',
        'averageScore': '0',
        'improvement': '0',
        'totalReadings': 0,
        'latestScore': '0',
      };
    }
    
    return {
      'trend': analysis['trend'],
      'averageScore': analysis['severityDescription'],
      'improvement': '0',
      'totalReadings': analysis['totalReadings'],
      'latestScore': 'Level ${analysis['severityLevel']}',
    };
  }

  /// Refresh all brain signal data
  Future<void> refreshBrainSignalData() async {
    await Future.wait([
      loadBrainSignalScores(),
      loadLatestScore(),
    ]);
  }

  /// Get current user info for notifications
  Map<String, dynamic>? _getCurrentUserInfo() {
    final box = GetStorage();
    final loginDetails = box.read('loginDetails');
    return loginDetails?['user'];
  }

  /// Helper method to get current user ID
  String _getCurrentUserId() {
    final userInfo = _getCurrentUserInfo();
    return userInfo?['_id'] ?? '';
  }


  /// Get current user name
  String _getCurrentUserName() {
    final userInfo = _getCurrentUserInfo();
    return userInfo?['fullName'] ?? userInfo?['name'] ?? 'User';
  }
}
