import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService extends GetxController {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize local notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_brain_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();
    
    _initialized = true;
    print('🔔 [LOCAL_NOTIFICATION] Initialized successfully');
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    print('🔔 [LOCAL_NOTIFICATION] Notification tapped with payload: $payload');
    
    // Handle navigation based on notification type
    if (payload != null) {
      _handleNotificationNavigation(payload);
    }
  }

  /// Handle navigation when notification is tapped
  static void _handleNotificationNavigation(String payload) {
    try {
      // Parse payload to determine navigation
      if (payload.contains('quiz')) {
        // Navigate to quiz screen
        Get.toNamed('/quiz');
      } else if (payload.contains('result')) {
        // Navigate to results screen
        Get.toNamed('/results');
      } else if (payload.contains('eeg')) {
        // Navigate to EEG screen
        Get.toNamed('/eeg');
      }
    } catch (e) {
      print('❌ [LOCAL_NOTIFICATION] Error handling navigation: $e');
    }
  }

  /// Show quiz assignment notification for patients
  static Future<void> showQuizAssignmentNotification({
    required String doctorName,
    required String quizType,
    String? message,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'New Quiz Assigned',
      body: message ?? 'Dr. $doctorName has assigned you a $quizType assessment. Complete it to track your mental health progress.',
      payload: 'quiz_assignment',
    );
  }

  /// Show general notification (for WebSocket notifications)
  static Future<void> showGeneralNotification({
    required String title,
    required String message,
    String? payload,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      payload: payload ?? 'general',
    );
  }

  /// Show quiz completion notification for doctors
  static Future<void> showQuizCompletionNotification({
    required String patientName,
    required String quizType,
    required String score,
    String? message,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Patient Assessment Complete',
      body: message ?? '$patientName completed their $quizType assessment (Score: $score). Review results in patient dashboard.',
      payload: 'quiz_completion',
    );
  }

  /// Show EEG test notification for doctors and relatives
  static Future<void> showEEGTestNotification({
    required String patientName,
    required String eegScore,
    String? message,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Brain Signal Analysis Complete',
      body: message ?? '$patientName completed EEG brain signal analysis. Depression score: $eegScore. View detailed results in dashboard.',
      payload: 'eeg_test',
    );
  }

  /// Show relative notification with professional styling
  static Future<void> showRelativeNotification({
    required String patientName,
    required String activityType,
    String? message,
  }) async {
    String professionalTitle = 'Family Member Update';
    String professionalMessage = '$patientName has a new health update';

    switch (activityType.toLowerCase()) {
      case 'quiz_completed':
        professionalTitle = 'Assessment Completed';
        professionalMessage = '$patientName completed their mental health assessment. View their progress and support their wellness journey.';
        break;
      case 'eeg_completed':
        professionalTitle = 'Brain Analysis Complete';
        professionalMessage = '$patientName completed EEG brain signal analysis. Review their mental health insights and depression assessment results.';
        break;
      case 'appointment_scheduled':
        professionalTitle = 'Medical Appointment Scheduled';
        professionalMessage = '$patientName has scheduled a new healthcare appointment. Stay informed about their treatment schedule.';
        break;
      case 'medication_reminder':
        professionalTitle = 'Medication Update';
        professionalMessage = '$patientName has important medication information. Help ensure they maintain their treatment plan.';
        break;
      case 'progress_update':
        professionalTitle = 'Health Progress Update';
        professionalMessage = '$patientName has made progress in their mental health journey. View their latest achievements and milestones.';
        break;
    }

    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: professionalTitle,
      body: message ?? professionalMessage,
      payload: 'relative_$activityType',
    );
  }

  /// Show notification based on type with professional styling
  static Future<void> showNotificationForType(Map<String, dynamic> notification) async {
    final type = notification['type'] as String? ?? 'general';
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final meta = notification['meta'] as Map<String, dynamic>?;
    
    String professionalTitle;
    String professionalMessage;
    
    switch (type.toLowerCase()) {
      case 'quiz_assigned':
        final quizType = meta?['questionnaireType'] ?? 'Mental Health Assessment';
        final doctorName = meta?['doctorName'] ?? 'Your healthcare provider';
        professionalTitle = 'New Assessment Available';
        professionalMessage = '$doctorName has assigned you a $quizType. Complete it to monitor your mental health progress and receive personalized care.';
        break;
      case 'quiz_completed':
        final quizType = meta?['questionnaireType'] ?? 'Assessment';
        final patientName = meta?['patientName'] ?? 'Patient';
        final score = meta?['score']?.toString() ?? 'N/A';
        professionalTitle = 'Patient Assessment Complete';
        professionalMessage = '$patientName completed their $quizType (Score: $score). Review detailed results and recommendations in the patient dashboard.';
        break;
      case 'eeg_completed':
        final patientName = meta?['patientName'] ?? 'Patient';
        final score = meta?['score']?.toString() ?? 'N/A';
        professionalTitle = 'Brain Analysis Complete';
        professionalMessage = '$patientName completed EEG brain signal analysis. Depression assessment score: $score. View comprehensive analysis and treatment recommendations.';
        break;
      case 'relative_update':
        final patientName = meta?['patientName'] ?? 'Your family member';
        final updateType = meta?['updateType'] ?? 'health update';
        professionalTitle = 'Family Member Update';
        professionalMessage = '$patientName has a new $updateType. Stay informed about their mental health journey and progress.';
        break;
      default:
        professionalTitle = title;
        professionalMessage = body;
        break;
    }

    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: professionalTitle,
      body: professionalMessage,
      payload: type,
    );
  }

  /// Core method to show notification
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? icon,
  }) async {
    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'eeg_app_channel',
        'EEG Brain Health',
        channelDescription: 'Mental health assessments and EEG notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: icon ?? '@drawable/ic_brain_notification',
        color: const Color(0xFF00ACC1),
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      print('🔔 [LOCAL_NOTIFICATION] Notification shown: $title');
    } catch (e) {
      print('❌ [LOCAL_NOTIFICATION] Error showing notification: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Schedule a notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'eeg_scheduled_channel',
        'EEG Scheduled Notifications',
        channelDescription: 'Scheduled notifications for EEG app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        platformChannelSpecifics,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('🔔 [LOCAL_NOTIFICATION] Notification scheduled for: $scheduledTime');
    } catch (e) {
      print('❌ [LOCAL_NOTIFICATION] Error scheduling notification: $e');
    }
  }

  /// Check notification permissions
  static Future<bool> checkPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.areNotificationsEnabled();
      return granted ?? false;
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final NotificationsEnabledOptions? permissions = await iosImplementation.checkPermissions();
      return permissions?.isEnabled ?? false;
    }

    return false;
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

}
