import 'dart:convert';

import 'package:ADDvEEG/models/quiz/new_quiz_models.dart';
import 'package:get/get.dart';

import '../../Constants/constants.dart';
import '../../services/api_service.dart';
import '../../models/chart_data.dart';
import '../../models/profile_model.dart';
import '../../models/brainScoreModel.dart';

class RelativeDetailedController extends GetxController {
  RelativeDetailedController({required this.data});
  String data;

  @override
  Future onInit() async {
    await fetchProfile().whenComplete(() async =>
        await fetchQuiz().whenComplete(() async => await fetchBrainScore()));
    super.onInit();
  }

  var isLoading = false.obs;
  RxList<ChartData> chartData = <ChartData>[].obs;
  RxList<ChartData> brainScore = <ChartData>[].obs;
  var profile = Profile().obs;

  fetchProfile() async {
    isLoading.value = true;

    try {
      print('👤 [PROFILE] Fetching profile for patient: $data');

      final response = await apiService.get(
        Constants.getUserById(data),
        requiresAuth: true,
      );

      if (response.success) {
        print('👤 [PROFILE] ✅ Profile fetched successfully!');
        profile.value = profileFromJson(jsonEncode(response.rawData));
      } else {
        print('👤 [PROFILE] ❌ Failed to fetch profile: ${response.message}');
      }
    } catch (err) {
      print('❌ [PROFILE] Error fetching profile: $err');
    }
  }

  var quiz = QuizHistoryResponse(success: false, statusCode: 0, message: '', data: []).obs;

  fetchQuiz() async {
    try {
      isLoading(true);
      print('📋 [QUIZ] Fetching quiz data for patient: $data');

      final response = await apiService.get(
        Constants.getQuizHistory(data),
        requiresAuth: true,
      );

      if (response.success) {
        print('📋 [QUIZ] ✅ Quiz data fetched successfully!');
        quiz.value = QuizHistoryResponse.fromJson(response.rawData ?? {});
        chartData.addAll(quiz.value.data.map((e) => ChartData(
            DateTime.now(), // Placeholder since API doesn't return createdAt
            e.score,
            e.questionnaireType)));
      } else {
        print('📋 [QUIZ] ❌ Failed to fetch quiz data: ${response.message}');
      }
    } catch (err) {
      print('❌ [QUIZ] Error fetching quiz: $err');
    }
  }

  var brainScores = <BrainScoreModel>[].obs;

  fetchBrainScore() async {
    try {
      print('🧠 [BRAIN] Fetching brain score data for patient: $data');

      // Using new API endpoint for brain signal scores
      final response = await apiService.get(
        Constants.getBrainSignalScores(data),
        requiresAuth: true,
      );

      if (response.success) {
        print('🧠 [BRAIN] ✅ Brain score data fetched successfully!');
        
        // Parse brain signal scores from new API response structure
        if (response.rawData != null && response.rawData!['data'] != null) {
          var scoresData = response.rawData!['data']['scores'] as List<dynamic>? ?? [];
          print('🧠 [BRAIN] Scores data: $scoresData');
          
          List<BrainScoreModel> parsedScores = [];
          for (var scoreItem in scoresData) {
            try {
              parsedScores.add(BrainScoreModel.fromJson(scoreItem));
            } catch (e) {
              print('🧠 [BRAIN] Error parsing score item: $e');
            }
          }
          
          brainScores.value = parsedScores;
          print('🧠 [BRAIN] Processed ${parsedScores.length} brain signal scores');
          
          // Convert to chart data
          brainScore.clear();
          brainScore.addAll(parsedScores.map((e) => ChartData(
              DateTime(e.createdAt!.year, e.createdAt!.month, e.createdAt!.day,
                  e.createdAt!.hour, e.createdAt!.minute, e.createdAt!.second),
              double.parse(e.score!).toInt(),
              e.deviceId)));
        }
      } else {
        print(
            '🧠 [BRAIN] ❌ Failed to fetch brain score data: ${response.message}');
      }
    } catch (err) {
      Get.snackbar('Error', 'Something went wrong');
      print('❌ [BRAIN] Error fetching brain score: $err');
    } finally {
      isLoading(false);
    }
  }
}
