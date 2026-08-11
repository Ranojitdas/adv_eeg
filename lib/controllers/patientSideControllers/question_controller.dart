import 'dart:convert';

import 'package:ADDvEEG/screens/patientScreens/patient_login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Constants/constants.dart';
import '../../models/patients/questions_model.dart';
import '../../models/quiz/new_quiz_models.dart';
import '../../services/api_service.dart';

class QuestionController extends GetxController {
  String type;
  var question = baseResp(questions: []).obs;
  var options = <int>[].obs;
  var isLoading = false.obs;
  var quizResponse = ''.obs;
  String? currentQuizAttemptId;

  QuestionController(this.type);
  @override
  void onInit() async {
    // Only auto-load questions if not being managed by quiz controller
    if (currentQuizAttemptId == null) {
      await getQuestions();
    }
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
    question = baseResp(questions: []).obs;
    options = <int>[].obs;
    isLoading = false.obs;
  }

  getQuestions() async {
    isLoading(true);
    try {
      String quizAttemptId;
      
      // Check if we already have a quiz attempt ID from the quiz controller
      if (currentQuizAttemptId != null && currentQuizAttemptId!.isNotEmpty) {
        print('📝 [QUIZ] Using existing quiz attempt ID: $currentQuizAttemptId');
        quizAttemptId = currentQuizAttemptId!;
      } else {
        print('📝 [QUIZ] Starting quiz self-initiate workflow for type: $type');

        // Step 1: Self-initiate quiz using the proper API workflow
        print('📝 [QUIZ] Step 1: Self-initiating quiz...');
        
        // Use quiz type directly (HAM_D or BDI)
        String backendType = type;
        print('📝 [QUIZ] Using quiz type: $backendType');
        
        final selfInitiateResponse = await apiService.post(
          Constants.quizSelfInitiate,
          body: {"questionnaireType": backendType},
          requiresAuth: true,
        );

        if (!selfInitiateResponse.success) {
          throw Exception('Failed to initiate quiz: ${selfInitiateResponse.message}');
        }

        final quizData = selfInitiateResponse.rawData;
        if (quizData != null) {
          final extractedQuizAttemptId = quizData['quizAttemptId'];
          currentQuizAttemptId = extractedQuizAttemptId; // Store in the property
          final totalQuestions = quizData['totalQuestions'] ?? 0;

          print('📝 [QUIZ] Self-initiate response: ${selfInitiateResponse.statusCode}');
          print('📝 [QUIZ] Self-initiate body: ${selfInitiateResponse.rawData}');
          print('📝 [QUIZ] ✅ Quiz self-initiated successfully!');
          print('📝 [QUIZ] Quiz Attempt ID: $currentQuizAttemptId');
          print('📝 [QUIZ] Total Questions: $totalQuestions');
        } else {
          throw Exception('Failed to parse self-initiate response');
        }
      }

      // Step 2: Fetch quiz details including questions
      print('📝 [QUIZ] Step 3: Fetching quiz details with questions...');
      final quizDetailsResponse = await apiService.get(
        '${Constants.apiUrl}/quiz/get-quiz-by-id/$currentQuizAttemptId',
        requiresAuth: true,
      );

      print('📝 [QUIZ] Quiz details response: ${quizDetailsResponse.statusCode}');
      print('📝 [QUIZ] Quiz details body: ${quizDetailsResponse.rawData}');

      if (quizDetailsResponse.success && quizDetailsResponse.rawData != null) {
        final quizDetails = quizDetailsResponse.rawData!;
        
        if (quizDetails['data'] != null && quizDetails['data']['responses'] != null) {
          print('📝 [QUIZ] ✅ Questions found in quiz responses!');
          
          final responses = quizDetails['data']['responses'] as List;
          final questionsData = {
            'questions': responses.map((response) {
              final questionObj = response['question'];
              return {
                'question': {
                  'question': questionObj['question'],
                  '_id': questionObj['_id'], // Move _id inside question object
                  'description': questionObj['description'], // Include description field
                },
                'options': questionObj['options'],
              };
            }).toList(),
            'questionare': {'type': type},
            'quizAttemptId': currentQuizAttemptId,
            'totalQuestions': responses.length,
          };
          
          question.value = baseResp.fromJson(questionsData);
          quizResponse.value = jsonEncode(questionsData);
          final questionsList = questionsData['questions'] as List?;
          options.value = List.filled(questionsList?.length ?? 0, -1);
          
          print('📝 [QUIZ] ✅ Quiz ready with ${questionsList?.length ?? 0} questions');
          return;
        }
      }
      
      throw Exception('Quiz initiated but could not fetch questions. Response: ${quizDetailsResponse.message}');
    } catch (err) {
      print('📝 [QUESTION] ❌ Error fetching questions: $err');
      Get.rawSnackbar(
          message: 'Failed to load quiz. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          margin: EdgeInsets.all(20),
          borderRadius: 10,
          duration: Duration(seconds: 3));
      // Don't redirect to login, just stay on current screen
    } finally {
      isLoading(false);
    }
  }
}
