import 'dart:convert';

import 'package:ADDvEEG/models/quiz/new_quiz_models.dart';
import 'package:get/get.dart';

import '../../Constants/constants.dart';
import '../../services/api_service.dart';
import '../../models/chart_data.dart';

// Initialize API service
final ApiService apiService = ApiService();

class GetQuizController extends GetxController {
  GetQuizController(this.uid);
  final String uid;
  RxList<ChartData> chartData = <ChartData>[].obs;
  RxList<ChartData> brainScore = <ChartData>[].obs;
  
  // Period selection for charts
  RxString quizSelectedPeriod = 'Weekly'.obs;
  RxString eegSelectedPeriod = 'Weekly'.obs;

  @override
  void onInit() async {
    await fetchQuiz();
    await fetchBrainScore();
    super.onInit();
  }

  var brainScores = <Map<String, dynamic>>[].obs;
  var quiz = QuizHistoryResponse(success: false, statusCode: 0, message: '', data: []).obs;
  var isLoading = false.obs;

  fetchQuiz() async {
    try {
      isLoading(true);
      print('📋 [QUIZ] Fetching quiz history for patient: $uid');

      // Use new quiz history endpoint
      final response = await apiService.get(
        Constants.getQuizHistory(uid),
        requiresAuth: true,
      );

      if (response.success) {
        print('📋 [QUIZ] ✅ Quiz history fetched successfully!');
        print('📋 [QUIZ] Raw response: ${response.rawData}');
        
        // Clear existing data
        chartData.clear();
        
        // Handle new API response format
        final quizData = response.rawData?['data'] ?? response.rawData;
        if (quizData != null && quizData is List) {
          print('📋 [QUIZ] Processing ${quizData.length} quiz records');
          
          for (var quizItem in quizData) {
            try {
              // Extract quiz data with proper null checking
              final createdAt = quizItem['createdAt'] ?? quizItem['completedAt'] ?? quizItem['updatedAt'];
              final score = quizItem['score'];
              final type = quizItem['questionnaireType'] ?? 'Unknown';
              
              // Debug print to see what fields are available
              print('📋 [QUIZ] Processing item: ${quizItem.keys.toList()}');
              print('📋 [QUIZ] Score: $score, Type: $type, CreatedAt: $createdAt');
              
              // Include all quizzes that have a score and type (no status field check)
              if (score != null && type != 'Unknown') {
                DateTime? dateTime;
                
                // Try to parse date or use current time as fallback
                if (createdAt != null) {
                  try {
                    dateTime = DateTime.parse(createdAt);
                  } catch (e) {
                    print('📋 [QUIZ] Date parse error: $e, using current time');
                    dateTime = DateTime.now();
                  }
                } else {
                  dateTime = DateTime.now();
                }
                
                final scoreValue = (score is String) ? int.tryParse(score) ?? 0 : score;
                
                chartData.add(ChartData(dateTime, scoreValue, type));
                print('📋 [QUIZ] ✅ Added quiz: $type, Score: $scoreValue, Date: $dateTime');
              } else {
                print('📋 [QUIZ] ⚠️ Skipped quiz - Score: $score, Type: $type');
              }
            } catch (e) {
              print('📋 [QUIZ] ⚠️ Error parsing quiz item: $e');
              print('📋 [QUIZ] Item data: $quizItem');
            }
          }
          
          // Sort by date (oldest first)
          chartData.sort((a, b) => a.x.compareTo(b.x));
          
          // Update quiz model for compatibility
          try {
            quiz.value = QuizHistoryResponse.fromJson({
              'success': true, 
              'statusCode': 200, 
              'message': 'Success', 
              'data': quizData
            });
          } catch (e) {
            print('📋 [QUIZ] ⚠️ Could not parse with legacy model: $e');
          }
          
          print('📋 [QUIZ] Final chart data count: ${chartData.length}');
        } else {
          print('📋 [QUIZ] ⚠️ No quiz data found or invalid format');
        }
      } else {
        print('📋 [QUIZ] ❌ Failed to fetch quiz history: ${response.message}');
      }
    } catch (err) {
      print('❌ [QUIZ] Error fetching quiz history: $err');
    } finally {
      isLoading(false);
    }
  }

  fetchBrainScore() async {
    try {
      print('🧠 [BRAIN] Fetching brain score data for patient: $uid');
      print('🧠 [BRAIN] API URL: ${Constants.getBrainSignalScores(uid)}');

      // Using new API endpoint for brain signal scores
      final response = await apiService.get(
        Constants.getBrainSignalScores(uid),
        requiresAuth: true,
      );

      if (response.success) {
        print('🧠 [BRAIN] ✅ Brain score data fetched successfully!');
        print('🧠 [BRAIN] Raw response: ${response.rawData}');
        
        // Clear existing data
        brainScore.clear();
        brainScores.clear();
        
        // Handle the new API response structure: {"data":{"scores":[],"pagination":{...}}}
        final scoresData = response.rawData?['data']?['scores'] ?? 
                          response.rawData?['data'] ?? 
                          response.rawData;
        
        if (scoresData is List && scoresData.isNotEmpty) {
          print('🧠 [BRAIN] Processing ${scoresData.length} brain signal scores');
          
          for (var scoreData in scoresData) {
            try {
              final timestamp = scoreData['timestamp'] ?? scoreData['createdAt'];
              final score = scoreData['score'];
              final deviceId = scoreData['device_id'] ?? scoreData['deviceId'] ?? 'Unknown';
              
              if (timestamp != null && score != null) {
                DateTime dateTime = DateTime.parse(timestamp);
                
                // Handle MongoDB $numberDecimal format
                double scoreValue = 0.0;
                if (score is Map && score.containsKey('\$numberDecimal')) {
                  scoreValue = double.tryParse(score['\$numberDecimal'].toString()) ?? 0.0;
                } else {
                  scoreValue = double.tryParse(score.toString()) ?? 0.0;
                }
                
                // Add to chart data (convert to int for display)
                brainScore.add(ChartData(dateTime, scoreValue.toInt(), deviceId));
                
                // Add to raw scores for other uses
                brainScores.add({
                  'timestamp': timestamp,
                  'score': scoreValue,
                  'deviceId': deviceId,
                  'createdAt': timestamp,
                });
                
                print('🧠 [BRAIN] Added score: $scoreValue, Device: $deviceId, Date: $dateTime');
                print('🧠 [BRAIN] Raw score object: $score');
              }
            } catch (e) {
              print('🧠 [BRAIN] Error processing score data: $e');
            }
          }
          
          // Sort by date (oldest first)
          brainScore.sort((a, b) => a.x.compareTo(b.x));
          
          print('🧠 [BRAIN] Final brain score count: ${brainScore.length}');
        } else {
          print('🧠 [BRAIN] ⚠️ No scores data found or invalid format');
        }
      } else {
        print('🧠 [BRAIN] ❌ Failed to fetch brain score data: ${response.message}');
        if (response.statusCode == 404) {
          print('🧠 [BRAIN] No brain signal data found for this patient');
        }
      }
    } catch (err) {
      print('❌ [BRAIN] Error fetching brain score: $err');
      // Don't show snackbar for every error, just log it
    }
  }
}
