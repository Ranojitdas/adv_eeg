import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'package:ADDvEEG/screens/patientScreens/collectingData.dart';
import 'package:ADDvEEG/screens/patientScreens/yogaScreen.dart';
import 'package:ADDvEEG/screens/patientScreens/musicPlayerScreen.dart';
import 'package:ADDvEEG/screens/patientScreens/patient_login.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_seria_changed/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../Constants/constants.dart';
import '../../screens/patientScreens/eegScreen.dart';
import '../../services/api_service.dart';
import '../../widgets/raw_signal_chart.dart';
// import 'package:tflite_flutter/tflite_flutter.dart' as tfl; // Commented out - using server prediction

class BrainSignalsController extends GetxController {
  @override
  void dispose() {
    _liveSignalTimer?.cancel();
    super.dispose();
    // Remove the direct access to EegScreen().connection
    // The connection should be managed by the EegScreen state
  }

  final valueReceived = 0.0.obs;
  final deviceId = ''.obs;
  final dataList = <double>[].obs;
  final liveDisplayData = <double>[].obs;
  final completedRawSignalTrace = <double>[].obs;
  final Queue<double> _liveSignalQueue = Queue<double>();
  Timer? _liveSignalTimer;
  final dio = Dio();
  final isLoading = false.obs;
  final isCollectingData = false.obs;
  final isSendingData = false.obs;
  final isProcessingResults = false.obs;
  final currentStatus = 'Ready'.obs;
  bool _sessionPredictionCompleted = false;
  bool _serverPredictionInProgress = false;
  
  // Depression classification properties
  final depressionLevel = ''.obs;
  final depressionSeverity = 0.obs; // 0-4 scale
  final normalizedScore = 0.0.obs;
  final recommendations = <String>[].obs;
  
  /// Reset session state for new EEG data collection
  void resetSession() {
    _sessionPredictionCompleted = false;
    _serverPredictionInProgress = false;
    _liveSignalTimer?.cancel();
    _liveSignalTimer = null;
    _liveSignalQueue.clear();
    dataList.clear();
    liveDisplayData.clear();
    completedRawSignalTrace.clear();
    valueReceived.value = 0.0;
    isLoading.value = false;
    isCollectingData.value = false;
    isSendingData.value = false;
    isProcessingResults.value = false;
    currentStatus.value = 'Ready';
    depressionLevel.value = '';
    depressionSeverity.value = 0;
    normalizedScore.value = 0.0;
    recommendations.clear();
    print('🧠 [BRAIN] 🔄 Session reset - ready for new data collection');
  }

  void enqueueLiveSamples(List<double> samples) {
    if (samples.isEmpty) {
      return;
    }

    _liveSignalQueue.addAll(samples);
    _ensureLiveSignalDrainer();
  }

  void _ensureLiveSignalDrainer() {
    if (_liveSignalTimer?.isActive == true) {
      return;
    }

    // Match the 20-second capture window so the trace grows at a natural pace.
    _liveSignalTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_liveSignalQueue.isEmpty) {
        timer.cancel();
        return;
      }

      liveDisplayData.add(_liveSignalQueue.removeFirst());

      const maxDisplayPoints = 180;
      if (liveDisplayData.length > maxDisplayPoints) {
        liveDisplayData.removeRange(0, liveDisplayData.length - maxDisplayPoints);
      }
    });
  }

  // Extract 6 EEG frequency band features from raw EEG data for ML model
  List<double> _extractEEGFeatures(List<double> rawData) {
    if (rawData.isEmpty) {
      return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    }

    print('🧠 [BRAIN] Extracting EEG frequency band features from ${rawData.length} raw data points...');
    
    // Calculate power in different EEG frequency bands
    // Note: This is a simplified approach for demonstration
    // In practice, you'd use FFT for proper frequency analysis
    
    // Delta band (0.5-4 Hz) - deep sleep, unconscious processes
    double deltaPower = _calculateBandPower(rawData, 0, 0.1);
    
    // Theta band (4-8 Hz) - drowsiness, meditation, creativity
    double thetaPower = _calculateBandPower(rawData, 0.1, 0.2);
    
    // Alpha band (8-13 Hz) - relaxed awareness, closed eyes
    double alphaPower = _calculateBandPower(rawData, 0.2, 0.35);
    
    // Beta band (13-30 Hz) - active concentration, alertness
    double betaPower = _calculateBandPower(rawData, 0.35, 0.6);
    
    // Gamma band (30-100 Hz) - high-level cognitive processing
    double gammaPower = _calculateBandPower(rawData, 0.6, 1.0);
    
    // Overall signal power
    double totalPower = rawData.map((x) => x * x).reduce((a, b) => a + b) / rawData.length;
    
    List<double> features = [deltaPower, thetaPower, alphaPower, betaPower, gammaPower, totalPower];
    
    print('🧠 [BRAIN] EEG frequency band analysis complete:');
    print('🧠 [BRAIN] - Delta Power: ${deltaPower.toStringAsFixed(2)}');
    print('🧠 [BRAIN] - Theta Power: ${thetaPower.toStringAsFixed(2)}');
    print('🧠 [BRAIN] - Alpha Power: ${alphaPower.toStringAsFixed(2)}');
    print('🧠 [BRAIN] - Beta Power: ${betaPower.toStringAsFixed(2)}');
    print('🧠 [BRAIN] - Gamma Power: ${gammaPower.toStringAsFixed(2)}');
    print('🧠 [BRAIN] - Total Power: ${totalPower.toStringAsFixed(2)}');
    
    return features;
  }

  // Calculate power in a specific frequency band (simplified approach)
  double _calculateBandPower(List<double> data, double startRatio, double endRatio) {
    int startIdx = (data.length * startRatio).floor();
    int endIdx = (data.length * endRatio).floor();
    
    if (startIdx >= endIdx || endIdx > data.length) {
      return 0.0;
    }
    
    List<double> bandData = data.sublist(startIdx, endIdx);
    return bandData.map((x) => x * x).reduce((a, b) => a + b) / bandData.length;
  }

  Future<void> getPrediction() async {
    try {
      // Check if prediction already completed for this session
      if (_sessionPredictionCompleted) {
        return;
      }
      
      // Check if we have enough data for prediction
      if (dataList.length < 256) {
        print('🧠 [BRAIN] ❌ Insufficient data: ${dataList.length} points (minimum 256 required)');
        Get.snackbar(
          'Insufficient Data',
          'Need more EEG data points for analysis (${dataList.length}/256). Please continue data collection.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange,
        );
        isLoading.value = false;
        isCollectingData.value = false;
        isSendingData.value = false;
        isProcessingResults.value = false;
        currentStatus.value = 'Insufficient data';
        return;
      }
      
      print('🧠 [BRAIN] ✅ Sufficient data collected: ${dataList.length} points (minimum 256 required)');
      isLoading.value = true;
      isSendingData.value = true;
      currentStatus.value = 'Preparing data for analysis...';
      

      // Use Railway server for prediction instead of local model
      await getServerPrediction();
      
      // Update status for result processing
      completedRawSignalTrace.assignAll(dataList);
      currentStatus.value = 'Saving results...';
      isProcessingResults.value = true;
      isSendingData.value = false;
      
      await postPrediction();
      
      // Clear data after successful prediction to prevent accumulation
      dataList.clear();
      
      // Show completion feedback
      Get.snackbar(
        'Analysis Complete',
        'Your brain signal analysis is ready!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Analysis Failed',
        'Unable to process brain signals. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      // Reset all loading states
      isLoading.value = false;
      isCollectingData.value = false;
      isSendingData.value = false;
      isProcessingResults.value = false;
      currentStatus.value = 'Ready';
    }
  }

  /// Get prediction from Railway server
  Future<void> getServerPrediction() async {
    try {
      print('🧠 [BRAIN] ==================== SERVER PREDICTION START ====================');
      
      // Check if server prediction is already in progress
      if (_serverPredictionInProgress) {
        print('🧠 [BRAIN] 🔒 SERVER PREDICTION ALREADY IN PROGRESS - BLOCKING DUPLICATE CALL');
        print('🧠 [BRAIN] ==================== SERVER PREDICTION BLOCKED ====================');
        return;
      }
      
      // Set flag to prevent multiple server calls
      _serverPredictionInProgress = true;
      
      // Update user with current progress
      currentStatus.value = 'Sending data to analysis server...';
      
      final timestamp = DateTime.now().toIso8601String();
      
      // Take only 200 most recent data points for processing
      List<double> limitedData = dataList.toList();
      
      if (limitedData.length > 200) {
        limitedData = limitedData.skip(limitedData.length - 200).take(200).toList();
      }
      
      // Minimal logging for reduced data usage
      
      // Keep raw data for server prediction
      // Frequency analysis will be done locally for depression classification
      
      final requestData = {
        'data': limitedData,
        'device_id': deviceId.value.isNotEmpty ? deviceId.value : 'mobile_app',
        'timestamp': timestamp,
      };
      
      // Validate data before sending
      if (limitedData.isEmpty) {
        print('⚠️ [BRAIN] Warning: Data list is empty, using sample data');
        requestData['data'] = [10.5, 8.2, 12.1, 15.3, 9.8, 11.4]; // 6 sample EEG features
      }
      
      // Reduced logging for data efficiency
      
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status! < 500,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      );
      
      // Update status for server communication
      currentStatus.value = 'Connecting to analysis server...';
      await Future.delayed(const Duration(seconds: 1));
      
      currentStatus.value = 'Analyzing brain patterns...';
      await Future.delayed(const Duration(seconds: 2));
      
      final response = await dio.post(
        '${predictionUrl}predict_multiclass',
        data: requestData,
        options: options,
      );
      
      // Additional processing delay with status update
      currentStatus.value = 'Processing analysis results...';
      await Future.delayed(const Duration(seconds: 2));
      
      // Server response received

      if (response.statusCode == 200) {
        final result = response.data;
        print('🧠 [BRAIN] ✅ Server returned success (200)');
        print('🧠 [BRAIN] Processing server response...');
        
        // Extract prediction value from server response
        print('🧠 [BRAIN] Checking response format...');
        if (result is Map && result.containsKey('prediction')) {
          print('🧠 [BRAIN] Found \'prediction\' key in response');
          final predictionValue = result['prediction'];
          print('🧠 [BRAIN] Raw prediction value: $predictionValue (${predictionValue.runtimeType})');
          valueReceived.value = double.tryParse(predictionValue.toString()) ?? 0.0;
          print('🧠 [BRAIN] ✅ Parsed prediction from \'prediction\' key: ${valueReceived.value}');
        } else if (result is Map && result.containsKey('score')) {
          print('🧠 [BRAIN] Found \'score\' key in response');
          final scoreValue = result['score'];
          print('🧠 [BRAIN] Raw score value: $scoreValue (${scoreValue.runtimeType})');
          valueReceived.value = double.tryParse(scoreValue.toString()) ?? 0.0;
          print('🧠 [BRAIN] ✅ Parsed prediction from \'score\' key: ${valueReceived.value}');
        } else if (result is List && result.isNotEmpty) {
          print('🧠 [BRAIN] Response is a list with ${result.length} items');
          final firstValue = result[0];
          print('🧠 [BRAIN] First list item: $firstValue (${firstValue.runtimeType})');
          valueReceived.value = double.tryParse(firstValue.toString()) ?? 0.0;
          print('🧠 [BRAIN] ✅ Parsed prediction from list[0]: ${valueReceived.value}');
        } else {
          print('🧠 [BRAIN] ⚠️ Unknown response format, using fallback calculation');
          print('🧠 [BRAIN] Response type: ${result.runtimeType}');
          print('🧠 [BRAIN] Response content: $result');
          // Fallback: use a calculated value based on data
          if (dataList.isNotEmpty) {
            valueReceived.value = dataList.reduce((a, b) => a + b) / dataList.length;
            print('🧠 [BRAIN] ✅ Fallback calculation (average): ${valueReceived.value}');
          } else {
            valueReceived.value = 0.0;
            print('🧠 [BRAIN] ⚠️ No data available, using 0.0');
          }
        }
        
        // Classify depression based on the prediction score
        currentStatus.value = 'Interpreting results...';
        _classifyDepression(valueReceived.value);
        
        _serverPredictionInProgress = false;
      } else {
        _serverPredictionInProgress = false;
        throw Exception('Server analysis failed. Please try again.');
      }
    } catch (e) {
      print('❌ [BRAIN] ==================== SERVER PREDICTION ERROR ====================');
      print('❌ [BRAIN] Error type: ${e.runtimeType}');
      print('❌ [BRAIN] Error message: $e');
      print('❌ [BRAIN] Stack trace: ${StackTrace.current}');
      print('❌ [BRAIN] Original data sent: ${dataList.length} points');
      print('❌ [BRAIN] First 10 original data: ${dataList.take(10).toList()}');
      
      if (e is DioException) {
        print('❌ [BRAIN] Dio error type: ${e.type}');
        print('❌ [BRAIN] Dio error message: ${e.message}');
        print('❌ [BRAIN] Dio response: ${e.response}');
        print('❌ [BRAIN] Dio status code: ${e.response?.statusCode}');
        print('❌ [BRAIN] Dio response data: ${e.response?.data}');
        print('❌ [BRAIN] Request URL: ${e.requestOptions.uri}');
        print('❌ [BRAIN] Request method: ${e.requestOptions.method}');
        print('❌ [BRAIN] Request headers: ${e.requestOptions.headers}');
        print('❌ [BRAIN] Request data: ${e.requestOptions.data}');
      }
      
      // Fallback: calculate a simple prediction locally if server fails
      print('🧠 [BRAIN] ⚠️ Using fallback prediction calculation...');
      if (dataList.isNotEmpty) {
        final sum = dataList.reduce((a, b) => a + b);
        valueReceived.value = sum / dataList.length;
        print('🧠 [BRAIN] Data sum: $sum');
        print('🧠 [BRAIN] Data count: ${dataList.length}');
        print('🧠 [BRAIN] ✅ Fallback prediction (average): ${valueReceived.value}');
        
        // Classify depression even with fallback prediction
        _classifyDepression(valueReceived.value);
      } else {
        valueReceived.value = 0.0;
        print('🧠 [BRAIN] ⚠️ No data available, using default value: 0.0');
        _classifyDepression(0.0);
      }
      
      print('❌ [BRAIN] 🔓 Resetting server prediction flag due to exception');
      _serverPredictionInProgress = false;
      print('❌ [BRAIN] ==================== SERVER PREDICTION ERROR END ====================');
    }
  }

  /// Classify depression based on standardized score ranges
  void _classifyDepression(double rawScore) {
    print('🧠 [BRAIN] ==================== DEPRESSION CLASSIFICATION START ====================');
    print('🧠 [BRAIN] Raw prediction score: $rawScore');
    
    // Use standardized score-based classification for consistency
    // This ensures both server and local predictions use the same severity mapping
    double scoreValue = rawScore.abs().clamp(0.0, 100.0);
    
    // Classification based on standardized score ranges
    String level;
    int severity;
    List<String> recs = [];
    
    if (scoreValue <= 20) {
      level = 'Excellent Mental State';
      severity = 0;
      recs = [
        'Your brain signals show excellent mental wellness',
        'Strong patterns indicate good relaxation response',
        'Continue your current healthy lifestyle',
        'Consider sharing your wellness practices with others'
      ];
    } else if (scoreValue <= 35) {
      level = 'Good Mental State';
      severity = 0;
      recs = [
        'Your brain signals indicate good mental health',
        'Minor stress indicators detected but within normal range',
        'Maintain regular exercise and good sleep habits',
        'Practice mindfulness or meditation for optimization'
      ];
    } else if (scoreValue <= 50) {
      level = 'Mild Stress/Anxiety';
      severity = 1;
      recs = [
        'Brain patterns show mild stress or anxiety indicators',
        'Consider stress management techniques',
        'Regular physical activity can help normalize patterns',
        'Monitor your sleep quality and stress levels',
        'Consider talking to someone if stress persists'
      ];
    } else if (scoreValue <= 65) {
      level = 'Moderate Depression Risk';
      severity = 2;
      recs = [
        'Brain patterns suggest moderate depression risk',
        'Recommend consultation with a mental health professional',
        'Consider therapy or counseling services',
        'Maintain social connections and daily routines',
        'Avoid alcohol and focus on sleep hygiene'
      ];
    } else if (scoreValue <= 80) {
      level = 'High Depression Risk';
      severity = 3;
      recs = [
        'Brain signals indicate high risk for depression',
        'Strongly recommend immediate professional consultation',
        'Consider evaluation for therapy or medication',
        'Engage family and friends for support',
        'Focus on basic self-care and avoid major decisions'
      ];
    } else {
      level = 'Severe Depression Indicators';
      severity = 4;
      recs = [
        'Brain patterns show severe depression indicators',
        'URGENT: Seek immediate mental health professional care',
        'Contact your doctor or mental health crisis line',
        'These patterns require professional attention',
        'Ensure you have support from family or friends'
      ];
    }
    
    // Update observable values
    depressionLevel.value = level;
    depressionSeverity.value = severity;
    normalizedScore.value = scoreValue;
    recommendations.clear();
    recommendations.addAll(recs);
    
    print('🧠 [BRAIN] ✅ Standardized Depression Classification:');
    print('🧠 [BRAIN] - Raw Score: ${rawScore.toStringAsFixed(2)}');
    print('🧠 [BRAIN] - Normalized Score: ${scoreValue.toStringAsFixed(1)}');
    print('🧠 [BRAIN] - Level: $level');
    print('🧠 [BRAIN] - Severity (0-4): $severity');
    print('🧠 [BRAIN] - Recommendations: ${recs.length} items');
    print('🧠 [BRAIN] ==================== DEPRESSION CLASSIFICATION END ====================');
  }
  
  /// Set default classification when no data is available
  void _setDefaultClassification() {
    depressionLevel.value = 'Insufficient Data';
    depressionSeverity.value = 0;
    normalizedScore.value = 0.0;
    recommendations.clear();
    recommendations.addAll([
      'Insufficient EEG data for reliable analysis',
      'Please ensure proper electrode contact',
      'Try collecting data for a longer duration',
      'Consult with a healthcare provider for proper assessment'
    ]);
  }

  Future<void> postPrediction() async {
    try {
      print('🧠 [BRAIN] ==================== POST PREDICTION START ====================');
      print('🧠 [BRAIN] Reading login details from storage...');
      
      final loginDetails = GetStorage().read('loginDetails');
      print('🧠 [BRAIN] Login details type: ${loginDetails.runtimeType}');
      print('🧠 [BRAIN] Login details: $loginDetails');
      
      // Enhanced user ID extraction with multiple fallback options
      String? userId;
      if (loginDetails != null) {
        // Try different possible user ID fields
        userId = loginDetails['user']?['_id'] ?? 
                 loginDetails['user']?['uid'] ?? 
                 loginDetails['user']?['id'] ??
                 loginDetails['data']?['_id'] ??
                 loginDetails['data']?['uid'] ??
                 loginDetails['data']?['id'] ??
                 loginDetails['_id'] ??
                 loginDetails['uid'] ??
                 loginDetails['id'];
      }
      
      print('🧠 [BRAIN] Extracted user ID: $userId');
      
      // Also check if we have user email for debugging
      final userEmail = loginDetails?['user']?['email'] ?? 
                       loginDetails['data']?['email'] ?? 
                       loginDetails['email'];
      print('🧠 [BRAIN] User email: $userEmail');
      
      // Check JWT token
      final token = loginDetails?['token'];
      print('🧠 [BRAIN] JWT token present: ${token != null ? 'YES' : 'NO'}');
      if (token != null) {
        print('🧠 [BRAIN] Token preview: ${token.toString().substring(0, 20)}...');
      }

      if (userId == null) {
        print('❌ [BRAIN] User ID is null - cannot proceed');
        throw Exception('User ID not found');
      }

      print('🧠 [BRAIN] ✅ User ID found: $userId');
      print('🧠 [BRAIN] Posting prediction for user: $userId');
      print('🧠 [BRAIN] Prediction value to post: ${valueReceived.value}');
      print('🧠 [BRAIN] Device ID: ${deviceId.value.isNotEmpty ? deviceId.value : "mobile_app"}');
      
      final timestamp = DateTime.now().toIso8601String();
      print('🧠 [BRAIN] Timestamp: $timestamp');
      
      final requestBody = {
        "user": userId,
        "device_id": deviceId.value.isNotEmpty ? deviceId.value : "mobile_app",
        "score": valueReceived.value,
        "timestamp": timestamp,
      };
      print('🧠 [BRAIN] Request body: ${jsonEncode(requestBody)}');
      print('🧠 [BRAIN] API endpoint: ${Constants.brainSignalStore}');

      // Debug authentication before making the request
      print('🧠 [BRAIN] Checking authentication status...');
      print('🧠 [BRAIN] Is authenticated: ${apiService.isAuthenticated}');
      print('🧠 [BRAIN] Current token: ${apiService.currentToken != null ? 'PRESENT' : 'MISSING'}');
      
      // Print auth headers that will be sent
      Constants.printAuthHeader();

      // Using new API endpoint for brain signal score creation
      print('🧠 [BRAIN] Making API call to store brain signal score...');
      final response = await apiService.post(
        Constants.brainSignalStore,
        body: requestBody,
        requiresAuth: true,
      );
      
      print('🧠 [BRAIN] ✅ API response received');
      print('🧠 [BRAIN] Response success: ${response.success}');
      print('🧠 [BRAIN] Response status code: ${response.statusCode}');
      print('🧠 [BRAIN] Response message: ${response.message}');
      print('🧠 [BRAIN] Response data: ${response.rawData}');

      if (response.success) {
        print('🧠 [BRAIN] ✅ Prediction posted successfully!');
        print('🧠 [BRAIN] Showing results bottom sheet...');
        
        // Ensure UI state is properly set before showing results
        isProcessingResults.value = false;
        currentStatus.value = 'Analysis complete';
        
        // Small delay to ensure UI updates are processed
        await Future.delayed(Duration(milliseconds: 100));
        
        _showResultsBottomSheet();
        print('🧠 [BRAIN] ✅ Results bottom sheet displayed');
        print('🧠 [BRAIN] ==================== POST PREDICTION SUCCESS ====================');
      } else {
        print('🧠 [BRAIN] ❌ Failed to post prediction');
        print('🧠 [BRAIN] Error message: ${response.message}');
        print('🧠 [BRAIN] Error status code: ${response.statusCode}');
        print('🧠 [BRAIN] Error data: ${response.rawData}');
        
        // Still show results even if backend storage failed
        print('🧠 [BRAIN] ⚠️ Showing results despite backend error...');
        isProcessingResults.value = false;
        currentStatus.value = 'Analysis complete (storage failed)';
        await Future.delayed(Duration(milliseconds: 100));
        _showResultsBottomSheet();
        
        throw Exception('Failed to post prediction: ${response.message}');
      }
    } catch (e) {
      print('❌ [BRAIN] ==================== POST PREDICTION ERROR ====================');
      print('❌ [BRAIN] Error type: ${e.runtimeType}');
      print('❌ [BRAIN] Error message: $e');
      print('❌ [BRAIN] Stack trace: ${StackTrace.current}');
      print('❌ [BRAIN] Current value received: ${valueReceived.value}');
      print('❌ [BRAIN] Current device ID: ${deviceId.value}');
      
      // Still show results even if there was an error
      print('❌ [BRAIN] ⚠️ Showing results despite error...');
      isProcessingResults.value = false;
      currentStatus.value = 'Analysis complete (with errors)';
      
      try {
        await Future.delayed(Duration(milliseconds: 100));
        _showResultsBottomSheet();
        print('❌ [BRAIN] ✅ Results shown despite error');
      } catch (dialogError) {
        print('❌ [BRAIN] Failed to show results dialog: $dialogError');
      }
      
      print('❌ [BRAIN] ==================== POST PREDICTION ERROR END ====================');

      Get.snackbar(
        'Error',
        'Failed to save results: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

  void _showResultsBottomSheet() {
    print('🧠 [BRAIN] ==================== SHOW RESULTS START ====================');
    print('🧠 [BRAIN] Preparing to show enhanced result screen...');
    print('🧠 [BRAIN] Current depression level: ${depressionLevel.value}');
    print('🧠 [BRAIN] Current severity: ${depressionSeverity.value}');
    print('🧠 [BRAIN] Current normalized score: ${normalizedScore.value}');
    print('🧠 [BRAIN] Recommendations count: ${recommendations.length}');
    
    // Use the new enhanced result screen instead of bottom sheet
    try {
      print('🧠 [BRAIN] Calling showEnhancedResultScreen()...');
      showEnhancedResultScreen();
      print('🧠 [BRAIN] ✅ showEnhancedResultScreen() called successfully');
    } catch (e) {
      print('❌ [BRAIN] Error showing result screen: $e');
      print('❌ [BRAIN] Error type: ${e.runtimeType}');
    }
    print('🧠 [BRAIN] ==================== SHOW RESULTS END ====================');
  }

  void _showOldResultsBottomSheet() {
    // Get severity color
    Color getSeverityColor(int severity) {
      switch (severity) {
        case 0: return Colors.green;
        case 1: return Colors.lightGreen;
        case 2: return Colors.orange;
        case 3: return Colors.deepOrange;
        case 4: return Colors.red;
        default: return Colors.grey;
      }
    }

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with depression level
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Brain Signal Analysis',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Depression Level
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: getSeverityColor(depressionSeverity.value).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: getSeverityColor(depressionSeverity.value),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        depressionLevel.value.isNotEmpty ? depressionLevel.value : 'Processing...',
                        style: GoogleFonts.poppins(
                          color: getSeverityColor(depressionSeverity.value),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                    
                    const SizedBox(height: 16),
                    
                    // Normalized Score Display
                    Obx(() => Column(
                      children: [
                        Text(
                          'Depression Score',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${normalizedScore.value.toStringAsFixed(1)}',
                          style: GoogleFonts.poppins(
                            color: getSeverityColor(depressionSeverity.value),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Progress bar
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: normalizedScore.value / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: getSeverityColor(depressionSeverity.value),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
              ),
              
              // Recommendations Section
              Obx(() => recommendations.isNotEmpty ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommendations',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: getSeverityColor(depressionSeverity.value),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rec,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ) : const SizedBox()),
              
              // Technical Details (Collapsible)
              ExpansionTile(
                title: Text(
                  'Technical Details',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                iconColor: Colors.white70,
                collapsedIconColor: Colors.white70,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Raw Server Score:',
                              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              valueReceived.value.toStringAsFixed(2),
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Data Points Analyzed:',
                              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '${dataList.length}',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Continue to Yoga Button
                    Material(
                      color: const Color(0xFF0850FD),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          Get.back();
                          Get.off(() => YogaScreen());
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Continue to Yoga Therapy',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Close Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Get.back(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Close',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showExpandedRawTrace() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Expanded Raw EEG Trace',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                Expanded(
                  child: Obx(() {
                    final trace = completedRawSignalTrace.isNotEmpty
                        ? completedRawSignalTrace.toList(growable: false)
                        : liveDisplayData.isNotEmpty
                            ? liveDisplayData.toList(growable: false)
                            : dataList.toList(growable: false);

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                        child: RawSignalChart(
                          samples: trace,
                          title: 'EEG Waveform',
                          subtitle: 'Drag left and right to inspect the trace',
                          height: MediaQuery.of(Get.context!).size.height * 0.56,
                          chartWidth: 1400,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void showEnhancedResultScreen() {
    print('🧠 [BRAIN] ==================== ENHANCED RESULT SCREEN START ====================');
    print('🧠 [BRAIN] Creating dialog with Get.dialog()...');
    print('🧠 [BRAIN] Depression level for display: "${depressionLevel.value}"');
    print('🧠 [BRAIN] Severity for display: ${depressionSeverity.value}');
    print('🧠 [BRAIN] Normalized score for display: ${normalizedScore.value}');
    
    try {
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF0D1117),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header with fade-in animation
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, -20 * (1 - value)),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Get.offAll(() => PatientLogin());
                                },
                                icon: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close, color: Colors.white),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'EEG Assessment Results',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(width: 48), // Balance the close button
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Main Result Card with slide-up animation
                        TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 1000),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Brain Signal Analysis',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      
                                      // Depression Level Badge with scale animation
                                      TweenAnimationBuilder<double>(
                                        duration: Duration(milliseconds: 1200),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, scaleValue, child) {
                                          return Transform.scale(
                                            scale: 0.5 + (0.5 * scaleValue),
                                            child: Obx(() => Container(
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: _getResultColor().withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _getResultColor(),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                depressionLevel.value,
                                                style: GoogleFonts.poppins(
                                                  color: _getResultColor(),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )),
                                          );
                                        },
                                      ),
                              
                              SizedBox(height: 20),

                                Stack(
                                  children: [
                                    Obx(() => RawSignalChart(
                                      samples: completedRawSignalTrace
                                        .toList(growable: false),
                                      title: 'Live Raw Signal Trace',
                                      subtitle:
                                        'Captured during the 20-second collection window',
                                      height: 190,
                                    )),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _showExpandedRawTrace,
                                          borderRadius: BorderRadius.circular(20),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.35),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.14),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.open_in_full_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 20),
                              
                              // Severity Level Display
                              Text(
                                'Severity Level',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 1500),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, animValue, child) {
                                  return Obx(() {
                                    final animatedSeverity = (depressionSeverity.value * animValue).toInt();
                                    return Text(
                                      '$animatedSeverity',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  });
                                },
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Progress Bar - Based on Severity Level (0-4)
                              Obx(() => Container(
                                width: double.infinity,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: depressionSeverity.value / 4.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _getResultColor(),
                                    ),
                                  ),
                                ),
                              )),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Recommendations Section - Original Style with Background
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A), // Dark gray background like original
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommendations',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16),
                              Obx(() {
                                return Column(
                                  children: recommendations.map((rec) => 
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            margin: EdgeInsets.only(top: 8, right: 12),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF4CAF50), // Match the green color
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              rec,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.white.withValues(alpha: 0.7),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ).toList(),
                                );
                              }),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Wellness Activities Section
                        Text(
                          'Recommended Wellness Activities',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Activity Cards
                        _buildWellnessActivityCard(
                          'Meditation & Mindfulness',
                          'Guided meditation sessions to calm your mind',
                          Icons.self_improvement_rounded,
                          Colors.purple,
                          () => Get.to(() => YogaScreen(initialSection: 'meditation')),
                        ),
                        SizedBox(height: 12),
                        
                        _buildWellnessActivityCard(
                          'Relaxing Music',
                          'Soothing sounds and music for stress relief',
                          Icons.music_note_rounded,
                          Colors.blue,
                          () => Get.to(() => YogaScreen(initialSection: 'music')),
                        ),
                        SizedBox(height: 12),
                        
                        _buildWellnessActivityCard(
                          'Yoga & Breathing',
                          'Gentle yoga poses and breathing exercises',
                          Icons.fitness_center_rounded,
                          Colors.green,
                          () => Get.to(() => YogaScreen()),
                        ),
                        SizedBox(height: 12),
                        
                        _buildWellnessActivityCard(
                          'Nature Sounds',
                          'Calming forest, ocean, and rain sounds',
                          Icons.nature_rounded,
                          Colors.teal,
                          () => Get.to(() => MusicPlayerScreen(
                            title: 'Nature Sounds',
                            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
                          )),
                        ),
                        
                        SizedBox(height: 32),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Get.offAll(() => PatientLogin());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Close',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Get.offAll(() => PatientLogin());
                                  Get.to(() => YogaScreen());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0850FD),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Start Wellness',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
    
    print('🧠 [BRAIN] ✅ Enhanced result screen dialog created successfully');
    print('🧠 [BRAIN] ==================== ENHANCED RESULT SCREEN END ====================');
    } catch (e) {
      print('❌ [BRAIN] Error creating enhanced result screen: $e');
      print('❌ [BRAIN] Error type: ${e.runtimeType}');
      print('❌ [BRAIN] Falling back to simple snackbar notification...');
      
      // Fallback to simple notification if dialog fails
      Get.snackbar(
        'EEG Analysis Complete',
        'Depression Level: ${depressionLevel.value}\nSeverity: ${depressionSeverity.value}/4',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _getResultColor().withValues(alpha: 0.1),
        colorText: _getResultColor(),
        duration: Duration(seconds: 5),
      );
    }
  }

  Widget _buildWellnessActivityCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getResultGradientColors() {
    final severity = depressionSeverity.value;
    switch (severity) {
      case 0: // Excellent/Good
        return [Color(0xFF10B981), Color(0xFF059669)];
      case 1: // Mild
        return [Color(0xFF84CC16), Color(0xFF65A30D)];
      case 2: // Moderate
        return [Color(0xFFF59E0B), Color(0xFFD97706)];
      case 3: // Moderately Severe
        return [Color(0xFFEF4444), Color(0xFFDC2626)];
      case 4: // Severe
        return [Color(0xFFDC2626), Color(0xFFB91C1C)];
      default:
        return [Color(0xFF6B7280), Color(0xFF4B5563)];
    }
  }

  Color _getResultColor() {
    final severity = depressionSeverity.value;
    switch (severity) {
      case 0: return Color(0xFF4CAF50); // Original green color
      case 1: return Color(0xFF8BC34A);
      case 2: return Color(0xFFF59E0B);
      case 3: return Color(0xFFEF4444);
      case 4: return Color(0xFFDC2626);
      default: return Color(0xFF6B7280);
    }
  }
}
