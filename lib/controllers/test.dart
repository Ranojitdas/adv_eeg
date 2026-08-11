import 'dart:convert';

import 'package:ADDvEEG/Constants/constants.dart';
import 'package:ADDvEEG/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class TestId extends GetxController {
  final ApiService apiService = Get.find<ApiService>();

  onInit() async {
    await getNotification();
    super.onInit();
  }

  getNotification() async {
    var token = ''.obs;
    await FirebaseMessaging.instance
        .getToken()
        .then((value) => token.value = value!);
    try {
      // Using ApiService instead of direct HTTP calls
      final response = await apiService.post(
        '${Constants.apiUrl}/devices/',
        body: {'registration_id': token.value, "type": "android"},
        requiresAuth: false,
      );
      
      if (response.success) {
        print('🔔 [FCM] Device registered successfully');
      } else {
        print('🔔 [FCM] Failed to register device: ${response.message}');
      }
    } catch (er) {
      print('🔔 [FCM] Error registering device: $er');
    }
  }
}
