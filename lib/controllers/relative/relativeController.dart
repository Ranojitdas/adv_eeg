import 'package:ADDvEEG/Constants/constants.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // Added for jsonEncode

import '../../models/allRelatedUsers.dart';
import '../../models/quiz/new_quiz_models.dart';
import '../../services/api_service.dart'; // Added for apiService

class RelativeController extends GetxController {
  @override
  Future onInit() async {
    await getRelative();
    super.onInit();
  }

  Rx<AllRelatedUser> data = AllRelatedUser().obs;
  var quiz = QuizHistoryResponse(success: false, statusCode: 0, message: '', data: []).obs;
  var isLoading = false.obs;

  getRelative() async {
    try {
      isLoading(true);
      final loginDetails = GetStorage().read('loginDetails');
      final uid =
          loginDetails?['user']?['_id'] ?? loginDetails?['user']?['uid'];

      if (uid == null) {
        throw Exception('User not logged in or UID not found');
      }

      print('👨‍👩‍👧‍👦 [RELATIVE] Fetching monitored patient...');

      // Use new API endpoint from documentation
      final response = await apiService.get(
        Constants.relativeGetMonitoredPatient,
        requiresAuth: true,
      );

      print(
          '👨‍👩‍👧‍👦 [RELATIVE] API Response Status: ${response.statusCode}');
      print('👨‍👩‍👧‍👦 [RELATIVE] API Response Body: ${response.rawData}');

      if (response.success) {
        // Transform API response to match AllRelatedUser model structure
        final apiData = response.rawData;
        final transformedData = {
          "message": {
            "patient": apiData?['data'] ?? []
          }
        };
        
        data.value = allRelatedUserFromJson(jsonEncode(transformedData));
        print('👨‍👩‍👧‍👦 [RELATIVE] Parsed data: ${data.value}');
      } else {
        throw Exception(
            'Failed to fetch monitored patient: ${response.message}');
      }
    } catch (err) {
      print('❌ [RELATIVE] Error in getRelative: $err');
      // Keep existing fallback logic for demo purposes
      // MOCK DATA FOR DEMO PURPOSES
      // data.value = AllRelatedUser(
      //   message: Message(
      //     patient: [
      //       Patient(
      //         uid: 'demo_uid_01',
      //         username: 'user01',
      //         email: 'user01@example.com',
      //         name: 'Demo User',
      //         role: 'USER',
      //         age: 25,
      //         bloodGroup: 'A_POSITIVE',
      //         address: '123 Demo Street',
      //         contact: '1234567890',
      //         gender: 'Male',
      //         relatedTo: ['demo_relative_01'],
      //       ),
      //     ],
      //   ),
      // );
      // Get.snackbar(
      //   'Demo Mode',
      //   'Showing demo patient data for relative.',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.orange.withValues(alpha: 0.1),
      //   colorText: Colors.orange,
      //   duration: const Duration(seconds: 3),
      // );
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchQuiz(String uid) async {
    try {
      print('📋 [QUIZ] Fetching quiz for patient: $uid');

      final response = await apiService.get(
        Constants.getQuizHistory(uid),
        requiresAuth: true,
      );

      if (response.success) {
        print('📋 [QUIZ] ✅ Quiz fetched successfully!');
        quiz.value = QuizHistoryResponse.fromJson(response.rawData ?? {});
      } else {
        print('📋 [QUIZ] ❌ Failed to fetch quiz: ${response.message}');
        throw Exception(response.message ?? 'Failed to fetch quiz data');
      }
    } catch (err) {
      print('❌ [QUIZ] Error in fetchQuiz: $err');
      Get.snackbar(
        'Error',
        'Failed to fetch quiz data: ${err.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
