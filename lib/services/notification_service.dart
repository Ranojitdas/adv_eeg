import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../Constants/constants.dart';
import '../controllers/notification_controller.dart';
import '../services/api_service.dart';
import 'local_notification_service.dart';

class NotificationService extends GetxController {
  final GetStorage box = GetStorage();
  final NotificationController notificationController = Get.put(NotificationController());

  /// Send notification when doctor assigns quiz to patient
  Future<bool> notifyPatientQuizAssigned({
    required String patientId,
    required String doctorName,
    required String quizType,
    String? message,
  }) async {
    try {
      print('🔔 [NOTIFICATION] ═══ NOTIFICATION SERVICE DEBUG ═══');
      print('🔔 [NOTIFICATION] Starting quiz assignment notification process');
      print('🔔 [NOTIFICATION] Patient ID: $patientId');
      print('🔔 [NOTIFICATION] Doctor Name: $doctorName');
      print('🔔 [NOTIFICATION] Quiz Type received: "$quizType"');
      print('🔔 [NOTIFICATION] Quiz Type length: ${quizType.length}');
      print('🔔 [NOTIFICATION] Quiz Type bytes: ${quizType.codeUnits}');
      print('🔔 [NOTIFICATION] Custom Message: ${message ?? "None"}');
      
      print('🔔 [NOTIFICATION] Building notification payload...');

      final payload = {
        'recipientId': patientId,
        'type': 'quiz',
        'title': 'New Quiz Assigned',
        'message': message ?? 'Dr. $doctorName has assigned you a $quizType quiz. Please complete it at your earliest convenience.',
        'data': {
          'doctorName': doctorName,
          'quizType': quizType,
          'assignedAt': DateTime.now().toIso8601String(),
        },
      };
      
      print('🔔 [NOTIFICATION] Payload created:');
      print('🔔 [NOTIFICATION] - recipientId: ${payload['recipientId']}');
      print('🔔 [NOTIFICATION] - type: ${payload['type']}');
      print('🔔 [NOTIFICATION] - title: ${payload['title']}');
      print('🔔 [NOTIFICATION] - message: ${payload['message']}');
      final payloadData = payload['data'] as Map<String, dynamic>?;
      print('🔔 [NOTIFICATION] - data.quizType: "${payloadData?['quizType']}"');
      print('🔔 [NOTIFICATION] - data.doctorName: ${payloadData?['doctorName']}');

      final response = await apiService.post(
        Constants.notificationCreate,
        body: payload,
        requiresAuth: true,
      );

      print('🔔 [NOTIFICATION] API call completed, processing response...');
      
      if (response.success) {
        print('🔔 [NOTIFICATION] ✅ Backend notification created successfully');
        print('🔔 [NOTIFICATION] Response data: ${response.rawData}');
        
        print('🔔 [NOTIFICATION] Triggering local notification...');
        // Also show local notification
        await LocalNotificationService.showQuizAssignmentNotification(
          doctorName: doctorName,
          quizType: quizType,
          message: message,
        );
        print('🔔 [NOTIFICATION] ✅ Local notification triggered successfully');
        
        return true;
      } else {
        print('🔔 [NOTIFICATION] ❌ Backend notification failed');
        print('🔔 [NOTIFICATION] Error message: ${response.message}');
        print('🔔 [NOTIFICATION] Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [NOTIFICATION] Exception in quiz assignment notification: $e');
      print('❌ [NOTIFICATION] Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Send notification when patient completes quiz
  Future<bool> notifyDoctorQuizCompleted({
    required String doctorId,
    required String patientName,
    required String quizType,
    required String score,
    String? message,
  }) async {
    try {
      print('🔔 [NOTIFICATION] Starting quiz completion notification process');
      print('🔔 [NOTIFICATION] Doctor ID: $doctorId');
      print('🔔 [NOTIFICATION] Patient Name: $patientName');
      print('🔔 [NOTIFICATION] Quiz Type: $quizType');
      print('🔔 [NOTIFICATION] Score: $score');
      print('🔔 [NOTIFICATION] Custom Message: ${message ?? "None"}');
      
      print('🔔 [NOTIFICATION] Building quiz completion payload...');

      final payload = {
        'recipientId': doctorId,
        'type': 'result',
        'title': 'Quiz Completed',
        'message': message ?? '$patientName has completed the $quizType quiz with a score of $score.',
        'data': {
          'patientName': patientName,
          'quizType': quizType,
          'score': score,
          'completedAt': DateTime.now().toIso8601String(),
        },
      };

      final response = await apiService.post(
        Constants.notificationCreate,
        body: payload,
        requiresAuth: true,
      );

      print('🔔 [NOTIFICATION] Quiz completion API call completed, processing response...');
      
      if (response.success) {
        print('🔔 [NOTIFICATION] ✅ Quiz completion backend notification created');
        print('🔔 [NOTIFICATION] Response data: ${response.rawData}');
        
        print('🔔 [NOTIFICATION] Triggering local quiz completion notification...');
        // Also show local notification
        await LocalNotificationService.showQuizCompletionNotification(
          patientName: patientName,
          quizType: quizType,
          score: score,
          message: message,
        );
        print('🔔 [NOTIFICATION] ✅ Local quiz completion notification triggered');
        
        return true;
      } else {
        print('🔔 [NOTIFICATION] ❌ Quiz completion backend notification failed');
        print('🔔 [NOTIFICATION] Error message: ${response.message}');
        print('🔔 [NOTIFICATION] Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [NOTIFICATION] Exception in quiz completion notification: $e');
      print('❌ [NOTIFICATION] Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Send notification when patient completes EEG test
  Future<bool> notifyDoctorEEGCompleted({
    required String doctorId,
    required String patientName,
    required String eegScore,
    String? message,
  }) async {
    try {
      print('🔔 [NOTIFICATION] Sending EEG completion notification to doctor: $doctorId');

      final payload = {
        'recipientId': doctorId,
        'type': 'result',
        'title': 'EEG Test Completed',
        'message': message ?? '$patientName has completed an EEG test. Brain signal score: $eegScore.',
        'data': {
          'patientName': patientName,
          'eegScore': eegScore,
          'testType': 'EEG',
          'completedAt': DateTime.now().toIso8601String(),
        },
      };

      final response = await apiService.post(
        Constants.notificationCreate,
        body: payload,
        requiresAuth: true,
      );

      if (response.success) {
        print('🔔 [NOTIFICATION] ✅ EEG completion notification sent successfully');
        
        // Also show local notification
        await LocalNotificationService.showEEGTestNotification(
          patientName: patientName,
          eegScore: eegScore,
          message: message,
        );
        
        return true;
      } else {
        print('🔔 [NOTIFICATION] ❌ Failed to send EEG completion notification: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ [NOTIFICATION] Error sending EEG completion notification: $e');
      return false;
    }
  }

  /// Send notification to relatives about patient activity
  Future<bool> notifyRelativePatientActivity({
    required String relativeId,
    required String patientName,
    required String activityType, // 'quiz_completed', 'eeg_completed', 'appointment', etc.
    String? message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('🔔 [NOTIFICATION] Sending patient activity notification to relative: $relativeId');

      String title = 'Patient Update';
      String defaultMessage = '$patientName has completed an activity.';

      switch (activityType) {
        case 'quiz_completed':
          title = 'Quiz Completed';
          defaultMessage = '$patientName has completed a mental health assessment.';
          break;
        case 'eeg_completed':
          title = 'EEG Test Completed';
          defaultMessage = '$patientName has completed an EEG brain signal test.';
          break;
        case 'appointment':
          title = 'Appointment Update';
          defaultMessage = '$patientName has an upcoming appointment.';
          break;
        case 'medication_reminder':
          title = 'Medication Reminder';
          defaultMessage = 'Reminder: $patientName needs to take medication.';
          break;
      }

      final payload = {
        'recipientId': relativeId,
        'type': 'reminder',
        'title': title,
        'message': message ?? defaultMessage,
        'data': {
          'patientName': patientName,
          'activityType': activityType,
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalData,
        },
      };

      final response = await apiService.post(
        Constants.notificationCreate,
        body: payload,
        requiresAuth: true,
      );

      if (response.success) {
        print('🔔 [NOTIFICATION] ✅ Relative notification sent successfully');
        
        // Also show local notification
        await LocalNotificationService.showRelativeNotification(
          patientName: patientName,
          activityType: activityType,
          message: message,
        );
        
        return true;
      } else {
        print('🔔 [NOTIFICATION] ❌ Failed to send relative notification: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ [NOTIFICATION] Error sending relative notification: $e');
      return false;
    }
  }

  /// Send general notification to any user
  Future<bool> sendGeneralNotification({
    required String recipientId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      print('🔔 [NOTIFICATION] Sending general notification to: $recipientId');

      final payload = {
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'message': message,
        'data': data ?? {},
      };

      final response = await apiService.post(
        Constants.notificationCreate,
        body: payload,
        requiresAuth: true,
      );

      if (response.success) {
        print('🔔 [NOTIFICATION] ✅ General notification sent successfully');
        return true;
      } else {
        print('🔔 [NOTIFICATION] ❌ Failed to send general notification: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ [NOTIFICATION] Error sending general notification: $e');
      return false;
    }
  }

  /// Get current user info for notifications
  Map<String, dynamic>? _getCurrentUserInfo() {
    final loginDetails = box.read('loginDetails');
    return loginDetails?['user'];
  }

  /// Get current user ID
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
