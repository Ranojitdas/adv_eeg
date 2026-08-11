import 'package:workmanager/workmanager.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ADDvEEG/services/local_notification_service.dart';
import 'package:ADDvEEG/services/api_service.dart';
import 'package:ADDvEEG/controllers/notification_controller.dart';
import 'package:ADDvEEG/Constants/constants.dart';

class BackgroundNotificationService {
  static const String taskName = "fetchNotificationsTask";
  static bool _isAppInForeground = true;
  
  /// Initialize background service
  static Future<void> initialize() async {
    // Force complete cleanup first
    try {
      await Workmanager().cancelAll();
      print('🔄 [BACKGROUND] Cancelled all existing background tasks');
    } catch (e) {
      print('⚠️ [BACKGROUND] Error cancelling tasks: $e');
    }
    
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Disable debug mode in production
    );
    
    // Start background task for all builds
    await startBackgroundTask();
    
    print('Background notification service initialized and started');
  }
  
  /// Start background task when app goes to background
  static Future<void> startBackgroundTask() async {
    try {
      // Cancel any existing task first
      await Workmanager().cancelByUniqueName(taskName);
      
      _isAppInForeground = false;
      
      // Register periodic task to fetch notifications every 15 minutes
      await Workmanager().registerPeriodicTask(
        taskName,
        taskName,
        frequency: const Duration(minutes: 15), // Minimum allowed frequency
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(milliseconds: 10000),
      );
      
      print('✅ [BACKGROUND] Background notification task registered successfully');
      print('   - Periodic task: runs every 15 minutes');
      print('   - Backoff policy: exponential with 10s delay');
    } catch (e) {
      print('❌ [BACKGROUND] Failed to register background task: $e');
    }
  }
  
  /// Stop background task when app comes to foreground
  static Future<void> stopBackgroundTask() async {
    if (_isAppInForeground) return; // Already stopped
    
    _isAppInForeground = true;
    
    // Cancel the background task since app is in foreground
    await Workmanager().cancelByUniqueName(taskName);
    
    print('Background notification task stopped - app in foreground');
  }
}

/// Background callback function (runs when app is closed)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('🔄 [BACKGROUND] Starting background notification fetch...');
      print('🔄 [BACKGROUND] Task name: $task');
      
      // Initialize GetStorage for background context
      await GetStorage.init();
      final box = GetStorage();
      
      // Get stored login details
      final loginDetails = box.read('loginDetails');
      if (loginDetails == null) {
        print('❌ [BACKGROUND] No login details found');
        return Future.value(true);
      }
      
      final token = loginDetails['token'];
      if (token == null) {
        print('❌ [BACKGROUND] No auth token found');
        return Future.value(true);
      }
      
      // Fetch notifications from backend
      final apiService = ApiService();
      const notificationsEndpoint = 'https://eeg-node-backend-production.up.railway.app/api/v1/notification/get-notifications';
      
      final response = await apiService.get(
        notificationsEndpoint,
        requiresAuth: true,
      );
      
      if (response.success && response.rawData != null) {
        // Handle the nested response structure correctly
        final responseData = response.rawData!['data'];
        final notifications = responseData is Map<String, dynamic> 
            ? (responseData['notifications'] as List<dynamic>? ?? [])
            : (responseData as List<dynamic>? ?? []);
        print('🔄 [BACKGROUND] Fetched ${notifications.length} notifications');
        
        // Get last shown notification timestamp
        final lastShownTime = box.read('lastNotificationTime') ?? 0;
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        
        // Filter new notifications - show unread notifications that haven't been shown before
        final shownNotificationIds = Set<String>.from(box.read('shownNotificationIds') ?? []);
        final newNotifications = notifications.where((notification) {
          final notificationId = notification['_id'] as String?;
          final isRead = notification['read'] as bool? ?? notification['isRead'] as bool? ?? false;
          
          // Show unread notifications that we haven't shown before
          return notificationId != null && 
                 !isRead && 
                 !shownNotificationIds.contains(notificationId);
        }).toList();
        
        // Show local notifications for new ones
        for (final notification in newNotifications) {
          final notificationId = notification['_id'] as String?;
          final title = notification['title'] as String? ?? 'New Notification';
          final body = notification['body'] as String? ?? '';
          final meta = notification['meta'] as Map<String, dynamic>?;
          
          // Customize notification based on type
          String notificationTitle = title;
          String notificationBody = body;
          
          if (title.toLowerCase().contains('quiz')) {
            final quizType = meta?['questionnaireType'] ?? 'Quiz';
            if (title.toLowerCase().contains('completed')) {
              notificationTitle = '🎯 Patient Quiz Completed';
              notificationBody = 'A patient completed $quizType quiz. Check results.';
            } else if (title.toLowerCase().contains('assigned')) {
              notificationTitle = '📝 New Quiz Assigned';
              notificationBody = 'You have been assigned a $quizType quiz.';
            }
          }
          
          // Show device notification for all builds
          await LocalNotificationService.showGeneralNotification(
            title: notificationTitle,
            message: notificationBody,
          );
          
          // Mark this notification as shown
          if (notificationId != null) {
            shownNotificationIds.add(notificationId);
          }
        }
        
        // Update tracking data
        if (newNotifications.isNotEmpty) {
          box.write('lastNotificationTime', currentTime);
          box.write('shownNotificationIds', shownNotificationIds.toList());
        }
        
        print('✅ [BACKGROUND] Notification fetch completed');
      } else {
        print('❌ [BACKGROUND] Failed to fetch notifications: ${response.message}');
      }
      
      return Future.value(true);
    } catch (e) {
      print('❌ [BACKGROUND] Error in background task: $e');
      return Future.value(false);
    }
  });
}
