import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../Constants/constants.dart';
import '../../models/patientSideModels/quiz_model.dart';
import '../../controllers/patientSideControllers/question_controller.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../models/quiz/new_quiz_models.dart';

class QuizController extends GetxController {
  String type;
  late QuestionController questionController;
  final LocationService locationService = Get.put(LocationService());
  final NotificationService notificationService = Get.put(NotificationService());
  var isLoading = false.obs;

  QuizController(this.type);
  @override
  void onInit() async {
    questionController = Get.put(QuestionController(type));
    super.onInit();
  }

  var options = <String, int>{}.obs;

  // Location methods now handled by LocationService

  mergeScoreAndQuestion() {
    print('📋 [QUIZ] ========== MERGE SCORES DEBUG ==========');
    print('📋 [QUIZ] questionController.options: ${questionController.options}');
    print('📋 [QUIZ] questionController.options.value: ${questionController.options.value}');
    print('📋 [QUIZ] questionController.options.length: ${questionController.options.length}');
    print('📋 [QUIZ] Questions length: ${questionController.question.value.questions.length}');
    
    // Ensure we have the quiz attempt ID from questionController
    if (questionController.currentQuizAttemptId != null && questionController.currentQuizAttemptId!.isNotEmpty) {
      currentQuizAttemptId.value = questionController.currentQuizAttemptId!;
      print('📋 [QUIZ] ✅ Updated quiz attempt ID: ${currentQuizAttemptId.value}');
    }
    
    // Clear existing options first
    options.clear();
    
    for (int i = 0; i < questionController.question.value.questions.length; i++) {
      final questionText = questionController.question.value.questions[i].question?.question ?? '';
      final selectedValue = i < questionController.options.length ? questionController.options[i] : -1;
      options[questionText] = selectedValue;
      print('📋 [QUIZ] Question $i: "$questionText" -> $selectedValue');
    }
    
    print('📋 [QUIZ] Final options map: $options');
    print('📋 [QUIZ] ========================================');
  }

  // Profile functionality moved to dedicated ProfileController

  var score = 0.obs;
  var currentQuizAttemptId = ''.obs;

  // Step 1: Self-initiate quiz using new backend API
  Future<String?> selfInitiateQuiz() async {
    try {
      print('📋 [QUIZ] Self-initiating quiz for type: $type');

      print('📋 [QUIZ] Step 2: Sending self-initiate request to backend...');
      print('📋 [QUIZ] API Endpoint: ${Constants.quizSelfInitiate}');
      final payload = {
        "questionnaireType": type,
      };
      print('📋 [QUIZ] Payload: ${jsonEncode(payload)}');
      
      final response = await apiService.post(
        Constants.quizSelfInitiate,
        body: payload,
        requiresAuth: true,
        fromJson: (json) => QuizSelfInitiateResponse.fromJson(json),
      );
      
      print('📋 [QUIZ] Step 2 completed: Backend response received');

      print('📋 [QUIZ] Step 3: Processing backend response...');
      
      if (response.success) {
        // Extract quizAttemptId directly from response body since it's not nested under data
        final quizAttemptId = response.rawData?['quizAttemptId'] ?? '';
        currentQuizAttemptId.value = quizAttemptId;
        print('📋 [QUIZ] ✅ Quiz initiated successfully! ID: $quizAttemptId');
        print('📋 [QUIZ] Response Data: ${response.rawData}');
        
        print('📋 [QUIZ] Step 4: Loading questions for quiz type: $type');
        // Set the quizAttemptId before calling getQuestions to avoid duplicate self-initiate calls
        questionController.currentQuizAttemptId = quizAttemptId;
        currentQuizAttemptId.value = quizAttemptId;
        await questionController.getQuestions();
        print('📋 [QUIZ] Step 4 completed: Questions loaded successfully');
        
        print('📋 [QUIZ] ==================== SELF-INITIATE QUIZ SUCCESS ====================');
        return quizAttemptId;
      } else {
        print('📋 [QUIZ] ❌ Self-initiate quiz failed');
        print('📋 [QUIZ] Error message: ${response.message}');
        print('📋 [QUIZ] Status code: ${response.statusCode}');
        print('📋 [QUIZ] Response data: ${response.rawData}');
        Get.snackbar('Error', response.message ?? 'Failed to start quiz');
        print('📋 [QUIZ] ==================== SELF-INITIATE QUIZ FAILED ====================');
        return null;
      }
    } catch (err) {
      print('❌ [QUIZ] Error initiating quiz: $err');
      return null;
    }
  }

  // Step 2: Submit quiz using new backend API
  Future<int> submitQuiz(String quizAttemptId) async {
    try {
      print('📋 [QUIZ] Submitting quiz with ID: $quizAttemptId');
      print('📋 [QUIZ] Current stored quiz attempt ID: ${currentQuizAttemptId.value}');

      // First merge the selected answers from UI into options map
      mergeScoreAndQuestion();
      print('📋 [QUIZ] Options after merge: $options');

      // Convert options to responses format matching API documentation
      List<QuizResponse> responses = [];
      
      // Use the parsed question data from questionController
      final questions = questionController.question.value.questions;
      print('📋 [QUIZ] Processing ${questions.length} questions for response mapping...');
      
      for (int i = 0; i < questions.length; i++) {
        final questionItem = questions[i];
        final questionText = questionItem.question?.question ?? '';
        final questionId = questionItem.question?.uid ?? '';
        
        print('📋 [QUIZ] Question $i: "$questionText" (ID: $questionId)');
        
        if (questionId.isNotEmpty && options.containsKey(questionText)) {
          final selectedIndex = options[questionText] ?? -1;
          print('📋 [QUIZ] Selected index for "$questionText": $selectedIndex');
          
          if (selectedIndex != -1) { // Only add if an answer was selected
            // Convert array index to option_id (backend expects option_id, not index)
            final questionOptions = questionItem.options;
            if (questionOptions != null && selectedIndex < questionOptions.length) {
              final optionId = questionOptions[selectedIndex].optionId ?? (selectedIndex + 1);
              responses.add(QuizResponse(
                questionId: questionId,
                selectedOption: optionId,
              ));
              print('📋 [QUIZ] ✅ Added response: "$questionText" -> option_id: $optionId (index: $selectedIndex)');
            } else {
              print('📋 [QUIZ] ❌ Invalid option index $selectedIndex for question "$questionText"');
            }
          } else {
            print('📋 [QUIZ] ⚠️ No selection for question "$questionText"');
          }
        } else {
          print('📋 [QUIZ] ❌ Question not found in options: "$questionText" (ID: $questionId)');
        }
      }
      
      print('📋 [QUIZ] Built ${responses.length} responses from ${options.length} options');

      // Backend expects: question as plain ObjectId string and selectedOptionId as integer
      final backendResponses = responses.map((r) => {
        "question": r.questionId, // Question ID as plain string
        "selectedOptionId": r.selectedOption, // Option ID as integer
      }).toList();
      
      // Try the correct backend format
      final payload = {
        "responses": backendResponses,
      };
      
      final payloadJson = jsonEncode(payload);
      print('📋 [QUIZ] Payload size: ${payloadJson.length} characters');
      print('📋 [QUIZ] First response: ${responses.isNotEmpty ? responses.first.toJson() : 'None'}');
      print('📋 [QUIZ] Last response: ${responses.isNotEmpty ? responses.last.toJson() : 'None'}');
      print('📋 [QUIZ] Sample payload (first 200 chars): ${payloadJson.length > 200 ? payloadJson.substring(0, 200) + '...' : payloadJson}');
      print('📋 [QUIZ] Backend response format: ${backendResponses.take(2).toList()}');

      // Submit with correct backend format
      final response = await apiService.post(
        Constants.getQuizSubmit(quizAttemptId),
        body: payload,
        requiresAuth: true,
        fromJson: (json) => QuizSubmissionResponse.fromJson(json),
      );

      print('📋 [QUIZ] Response status: ${response.statusCode}');
      print('📋 [QUIZ] Response body: ${response.rawData}');

      // Check if backend returned HTML error page instead of JSON
      if (response.statusCode == 400 && response.rawData != null && 
          response.rawData.toString().contains('<!DOCTYPE html>')) {
        print('📋 [QUIZ] ❌ Backend returned HTML error page instead of JSON');
        print('📋 [QUIZ] This indicates a server-side validation or routing issue');
        print('📋 [QUIZ] Client payload is correctly formatted - backend issue');
        Get.snackbar(
          'Quiz Submission Error', 
          'Server validation error. Please contact support.',
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return -1;
      }

      if (response.success && response.data != null) {
        print('📋 [QUIZ] ✅ Quiz submitted successfully!');
        // Backend returns score directly in response body, not nested under data.data
        final responseBody = response.rawData ?? {};
        score.value = responseBody['score'] ?? 0;
        print('📋 [QUIZ] Score extracted from response: ${score.value}');
        
        // Send notification to doctor about quiz completion
        await _notifyDoctorQuizCompleted(response.rawData ?? {});
        
        // Send notification to relatives about quiz completion
        await _notifyRelativesQuizCompleted(response.rawData ?? {});
        
        return response.statusCode ?? 200;
      } else {
        print('📋 [QUIZ] ❌ Failed to submit quiz: ${response.message}');
        return response.statusCode ?? 500;
      }
    } catch (err) {
      print('❌ [QUIZ] Error submitting quiz: $err');
      return 500;
    }
  }

  // New method for complete quiz workflow
  Future<bool> submitQuizNewWorkflow() async {
    isLoading.value = true;
    try {
      // Update location when attempting quiz
      await locationService.updateLocationOnQuizAttempt();

      print('📋 [QUIZ] Submitting existing quiz...');
      print('📋 [QUIZ] Using existing quiz attempt ID: ${currentQuizAttemptId.value}');

      // Use the existing quiz attempt ID - don't create a new quiz!
      final quizAttemptId = currentQuizAttemptId.value;
      if (quizAttemptId.isEmpty) {
        throw Exception('No active quiz found. Please start a quiz first.');
      }

      // Submit quiz responses using existing quiz
      final statusCode = await submitQuiz(quizAttemptId);
      return statusCode == 200;

    } catch (err) {
      print('❌ [QUIZ] Error in quiz workflow: $err');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Legacy method - kept for backward compatibility
  Future<int> postData(String uid) async {
    isLoading.value = true;
    try {
      // Update location when attempting quiz
      await locationService.updateLocationOnQuizAttempt();

      print('📋 [QUIZ] Starting new quiz workflow...');

      // Step 1: Self-initiate quiz
      final quizAttemptId = await selfInitiateQuiz();
      if (quizAttemptId == null) {
        throw Exception('Failed to initiate quiz');
      }

      // Step 2: Submit quiz responses
      final statusCode = await submitQuiz(quizAttemptId);
      return statusCode;

    } catch (e) {
      print('❌ [QUIZ] Exception in self-initiate quiz: $e');
      print('❌ [QUIZ] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', 'Something went wrong while starting the quiz');
      print('📋 [QUIZ] ==================== SELF-INITIATE QUIZ EXCEPTION ====================');
      return 0;
    } finally {
      isLoading.value = false;
      print('📋 [QUIZ] Self-initiate quiz process completed, loading state reset');
    }
  }

  // Get user's quiz history using new backend API
  Future<List<QuizHistoryItem>> getQuizHistory(String patientId) async {
    try {
      print('📋 [QUIZ] Fetching quiz history for patient: $patientId');

      final response = await apiService.get(
        Constants.getQuizHistory(patientId),
        requiresAuth: true,
        fromJson: (json) => QuizHistoryResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        print('📋 [QUIZ] ✅ Quiz history fetched successfully!');
        return response.data!.data;
      } else {
        print('📋 [QUIZ] ❌ Failed to fetch quiz history: ${response.message}');
        return [];
      }
    } catch (err) {
      print('❌ [QUIZ] Error fetching quiz history: $err');
      return [];
    }
  }

  // Get all user's quizzes using new backend API
  Future<List<Map<String, dynamic>>> getAllMyQuizzes() async {
    try {
      print('📋 [QUIZ] Fetching all my quizzes...');

      final response = await apiService.get(
        Constants.quizMyAllQuizzes,
        requiresAuth: true,
      );

      if (response.success) {
        print('📋 [QUIZ] ✅ All quizzes fetched successfully!');
        return List<Map<String, dynamic>>.from(response.rawData?['data'] ?? []);
      } else {
        print('📋 [QUIZ] ❌ Failed to fetch all quizzes: ${response.message}');
        return [];
      }
    } catch (err) {
      print('❌ [QUIZ] Error fetching all quizzes: $err');
      return [];
    }
  }

  // Get assigned quizzes for patient using new backend API
  Future<List<Map<String, dynamic>>> getMyAssignedQuizzes() async {
    try {
      print('📋 [QUIZ] Fetching my assigned quizzes...');

      final response = await apiService.get(
        Constants.quizMyAssignedQuiz,
        requiresAuth: true,
      );

      if (response.success) {
        print('📋 [QUIZ] ✅ Assigned quizzes fetched successfully!');
        return List<Map<String, dynamic>>.from(response.rawData?['data'] ?? []);
      } else {
        print('📋 [QUIZ] ❌ Failed to fetch assigned quizzes: ${response.message}');
        return [];
      }
    } catch (err) {
      print('❌ [QUIZ] Error fetching assigned quizzes: $err');
      return [];
    }
  }

  // Get specific quiz by ID using new backend API
  Future<Map<String, dynamic>?> getQuizById(String quizAttemptId) async {
    try {
      print('📋 [QUIZ] Fetching quiz by ID: $quizAttemptId');

      final response = await apiService.get(
        Constants.getQuizById(quizAttemptId),
        requiresAuth: true,
      );

      if (response.success) {
        print('📋 [QUIZ] ✅ Quiz fetched successfully!');
        return response.rawData?['data'] ?? response.rawData;
      } else {
        print('📋 [QUIZ] ❌ Failed to fetch quiz: ${response.message}');
        return null;
      }
    } catch (err) {
      print('❌ [QUIZ] Error fetching quiz by ID: $err');
      return null;
    }
  }

  // Self-initiate quiz using new backend API
  Future<Map<String, dynamic>> selfInitiateQuizNew(String quizType) async {
    try {
      print('📋 [QUIZ] Self-initiating quiz: $quizType');

      // Update location when attempting quiz
      await locationService.updateLocationOnQuizAttempt();

      final payload = {
        'type': quizType,
      };

      final response = await apiService.post(
        Constants.quizSelfInitiate,
        body: payload,
        requiresAuth: true,
      );

      if (response.success) {
        print('📋 [QUIZ] ✅ Quiz self-initiated successfully!');
        return response.rawData?['data'] ?? {};
      } else {
        print('📋 [QUIZ] ❌ Failed to self-initiate quiz: ${response.message}');
        return {};
      }
    } catch (err) {
      print('❌ [QUIZ] Error self-initiating quiz: $err');
      return {};
    }
  }

  /// Notify doctor about quiz completion
  Future<void> _notifyDoctorQuizCompleted(Map<String, dynamic> quizData) async {
    try {
      final userInfo = _getCurrentUserInfo();
      if (userInfo == null) return;

      final patientName = userInfo['fullName'] ?? userInfo['name'] ?? 'Patient';
      final scoreValue = quizData['data']?['score']?.toString() ?? score.value.toString();
      final quizType = quizData['data']?['questionnaireType'] ?? type;

      // Backend automatically sends notifications to doctor when quiz is completed
      // No need to send duplicate notification from client side
    } catch (e) {
      print('❌ [QUIZ] Error notifying doctor: $e');
    }
  }

  /// Notify relatives about quiz completion
  Future<void> _notifyRelativesQuizCompleted(Map<String, dynamic> quizData) async {
    try {
      final userInfo = _getCurrentUserInfo();
      if (userInfo == null) return;

      final patientName = userInfo['fullName'] ?? userInfo['name'] ?? 'Patient';
      final relatives = userInfo['relatives'] ?? [];

      for (final relative in relatives) {
        final relativeId = relative['_id'] ?? relative['id'];
        if (relativeId != null) {
          await notificationService.notifyRelativePatientActivity(
            relativeId: relativeId,
            patientName: patientName,
            activityType: 'quiz_completed',
            additionalData: {
              'quizType': quizData['data']?['questionnaireType'] ?? type,
              'score': quizData['data']?['score']?.toString() ?? score.value.toString(),
            },
          );
        }
      }
    } catch (e) {
      print('❌ [QUIZ] Error notifying relatives: $e');
    }
  }

  /// Get current user info
  Map<String, dynamic>? _getCurrentUserInfo() {
    final box = GetStorage();
    final loginDetails = box.read('loginDetails');
    return loginDetails?['user'];
  }
}
