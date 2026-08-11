import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/local_notification_service.dart';
import '../services/api_service.dart';
import '../Constants/constants.dart';

class NotificationController extends GetxController {
  final GetStorage box = GetStorage();
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  
  // Track shown notifications to prevent duplicates
  final Set<String> _shownNotificationIds = <String>{};
  DateTime? _lastFetchTime;
  Timer? _periodicTimer;

  @override
  void onInit() {
    super.onInit();
    print('📢 [NOTIFICATIONS] Controller initialized');
    
    // Initialize local notifications
    LocalNotificationService.initialize();
    
    // Delay API calls until app is fully initialized to avoid contextless navigation errors
    Future.delayed(const Duration(seconds: 2), () {
      fetchNotifications();
      // Set up periodic fetching every 2 minutes for foreground updates
      _startPeriodicFetching();
    });
  }

  /// Fetch notifications from REST API
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      print('📢 [NOTIFICATIONS] 🔄 Starting to fetch notifications...');
      
      final response = await apiService.get(
        Constants.notificationsGetAll,
        requiresAuth: true,
      );

      if (response.success) {
        print('📢 [NOTIFICATIONS] ═══ BACKEND RESPONSE DEBUG ═══');
        print('📢 [NOTIFICATIONS] 🔍 Full raw response: ${response.rawData}');
        
        // Check if response contains any quiz type data
        final responseStr = response.rawData.toString();
        if (responseStr.contains('HAM') || responseStr.contains('BDI')) {
          print('📢 [NOTIFICATIONS] ⚠️  QUIZ TYPE DETECTED IN RESPONSE');
          if (responseStr.contains('HAM_D')) print('📢 [NOTIFICATIONS] - Found HAM_D in response');
          if (responseStr.contains('HAM-D')) print('📢 [NOTIFICATIONS] - Found HAM-D in response');
          if (responseStr.contains('BDI')) print('📢 [NOTIFICATIONS] - Found BDI in response');
          if (responseStr.contains('BDI')) print('📢 [NOTIFICATIONS] - Found BDI in response');
        }
        
        // Handle nested data structure - API returns data.notifications array
        final responseData = response.rawData?['data'];
        final notificationsArray = responseData is Map ? responseData['notifications'] : responseData;
        
        print('📢 [NOTIFICATIONS] 🔍 Notifications array type: ${notificationsArray.runtimeType}');
        print('📢 [NOTIFICATIONS] 🔍 Notifications array: $notificationsArray');
        
        if (notificationsArray is List) {
          notifications.value = List<Map<String, dynamic>>.from(notificationsArray);
        } else {
          print('📢 [NOTIFICATIONS] ⚠️ Unexpected notifications data type: ${notificationsArray.runtimeType}');
          notifications.value = [];
        }
        
        // Count unread notifications
        unreadCount.value = notifications
            .where((notification) => notification['read'] == false)
            .length;
            
        print('📢 [NOTIFICATIONS] ✅ Fetched ${notifications.length} notifications');
        print('📢 [NOTIFICATIONS] 📊 Unread count: ${unreadCount.value}');
        
        // Debug: Show notification types and details with quiz type focus
        for (var i = 0; i < notifications.length && i < 3; i++) {
          final notification = notifications[i];
          print('📢 [NOTIFICATIONS] ═══ NOTIFICATION $i DEBUG ═══');
          print('   - ID: ${notification['_id']}');
          print('   - Type: ${notification['type']}');
          print('   - Title: ${notification['title']}');
          print('   - Message: ${notification['message']}');
          print('   - Read: ${notification['read']}');
          print('   - Priority: ${notification['priority']}');
          print('   - Created: ${notification['createdAt']}');
          
          // Check for quiz type in different possible locations
          if (notification['data'] != null) {
            print('   - Data keys: ${notification['data'].keys.toList()}');
            if (notification['data']['quizType'] != null) {
              print('   - Data.quizType: "${notification['data']['quizType']}"');
            }
          }
          if (notification['meta'] != null) {
            print('   - Meta keys: ${notification['meta'].keys.toList()}');
            if (notification['meta']['questionnaireType'] != null) {
              print('   - Meta.questionnaireType: "${notification['meta']['questionnaireType']}"');
            }
            if (notification['meta']['quizAttemptId'] != null) {
              print('   - Meta.quizAttemptId: "${notification['meta']['quizAttemptId']}"');
            }
            if (notification['meta']['assignedAt'] != null) {
              print('   - Meta.assignedAt: "${notification['meta']['assignedAt']}"');
            }
            // Show full meta for debugging
            print('   - Full Meta: ${notification['meta']}');
          }
          
          // Look for quiz type mentions in message
          final message = notification['message'] ?? '';
          if (message.contains('HAM') || message.contains('BDI')) {
            print('   - ⚠️  QUIZ TYPE IN MESSAGE: Found quiz type reference in message');
            final words = message.split(' ');
            for (String word in words) {
              if (word.contains('HAM') || word.contains('BDI')) {
                print('     - Quiz type word: "$word"');
              }
            }
          }
        }
        
        // Show notifications in UI immediately after fetch
        _processNewNotifications();
        
      } else {
        print('📢 [NOTIFICATIONS] ❌ Failed to fetch: ${response.message}');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error fetching: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Process new notifications and show local notifications
  void _processNewNotifications() {
    final unreadNotifications = getUnreadNotifications();
    print('📢 [NOTIFICATIONS] 🔔 Processing ${unreadNotifications.length} unread notifications');
    
    // Get stored shown notification IDs from persistent storage
    final storedShownIds = Set<String>.from(box.read('shownNotificationIds') ?? []);
    
    // Filter to only show NEW notifications (not previously shown)
    final newNotifications = unreadNotifications.where((notification) {
      final notificationId = notification['_id'] as String?;
      
      if (notificationId == null) return false;
      
      // Check if we've already shown this notification (from memory or storage)
      if (_shownNotificationIds.contains(notificationId) || 
          storedShownIds.contains(notificationId)) {
        return false;
      }
      
      // For first app load, show all unread notifications that haven't been shown
      // This ensures users see their pending notifications
      return true;
    }).toList();
    
    print('📢 [NOTIFICATIONS] 🆕 Found ${newNotifications.length} NEW notifications to show');
    
    for (var notification in newNotifications) {
      final notificationId = notification['_id'] as String?;
      if (notificationId != null) {
        _shownNotificationIds.add(notificationId);
        storedShownIds.add(notificationId);
        _showLocalNotificationForType(notification);
      }
    }
    
    // Update stored shown notification IDs
    if (newNotifications.isNotEmpty) {
      box.write('shownNotificationIds', storedShownIds.toList());
    }
    
    // Update last fetch time
    _lastFetchTime = DateTime.now();
  }

  /// Show local notification based on type
  void _showLocalNotificationForType(Map<String, dynamic> notification) {
    final type = notification['type'] as String?;
    final title = notification['title'] as String? ?? 'New Notification';
    final body = notification['body'] as String? ?? '';
    final meta = notification['meta'] as Map<String, dynamic>?;
    
    print('📢 [NOTIFICATIONS] 🔔 Showing local notification:');
    print('   - Type: $type');
    print('   - Title: $title');
    print('   - Body: ${body.length > 50 ? body.substring(0, 50) + '...' : body}');
    
    // Check if this is a quiz-related notification by examining title or meta
    final isQuizNotification = title.toLowerCase().contains('quiz') || meta?['questionnaireType'] != null;
    
    if (isQuizNotification) {
      print('📢 [NOTIFICATIONS] 📝 Detected quiz notification - processing with meta data');
      final quizType = meta?['questionnaireType'] ?? 'Quiz';
      print('   - Quiz Type from meta: $quizType');
      
      if (title.toLowerCase().contains('assigned')) {
        // This is a quiz assignment notification
        LocalNotificationService.showGeneralNotification(
          title: 'New Quiz Assigned',
          message: 'Your doctor has assigned you a $quizType quiz. Please complete it at your earliest convenience.',
        );
      } else if (title.toLowerCase().contains('completed')) {
        // This is a quiz completion notification
        _showQuizCompletionNotification(notification);
      } else {
        // Fallback for other quiz notifications
        LocalNotificationService.showGeneralNotification(
          title: title,
          message: body.isNotEmpty ? body : title,
        );
      }
    } else {
      // Handle non-quiz notifications
      switch (type) {
        case 'quiz_completion':
          _showQuizCompletionNotification(notification);
          break;
        case 'quiz_assigned':
          _showQuizAssignmentNotification(notification);
          break;
        default:
          LocalNotificationService.showGeneralNotification(
            title: title,
            message: body.isNotEmpty ? body : title,
          );
      }
    }
  }

  /// Show quiz completion notification (for DOCTORS)
  void _showQuizCompletionNotification(Map<String, dynamic> notification) {
    final meta = notification['meta'] as Map<String, dynamic>?;
    final score = meta?['score']?.toString() ?? 'Unknown';
    final quizType = meta?['questionnaireType'] ?? 'Quiz';
    final patientName = meta?['patientName'] ?? 'Patient';
    
    print('📢 [NOTIFICATIONS] 🎯 Quiz completion notification (FOR DOCTOR):');
    print('   - Patient: $patientName');
    print('   - Quiz Type: $quizType');
    print('   - Score: $score');
    print('   - Recipient: Doctor (patient completed quiz)');
    
    LocalNotificationService.showGeneralNotification(
      title: '🎯 Patient Quiz Completed',
      message: '$patientName scored $score on $quizType quiz. Please review.',
    );
  }

  /// Show quiz assignment notification (for PATIENTS)
  void _showQuizAssignmentNotification(Map<String, dynamic> notification) {
    final meta = notification['meta'] as Map<String, dynamic>?;
    final quizType = meta?['questionnaireType'] ?? 'Quiz';
    
    print('📢 [NOTIFICATIONS] 📝 Quiz assignment notification (FOR PATIENT):');
    print('   - Quiz Type: $quizType');
    print('   - Recipient: Patient (doctor assigned quiz)');
    
    LocalNotificationService.showGeneralNotification(
      title: '📝 New Quiz Assigned',
      message: 'Your doctor assigned you a $quizType quiz. Please complete it.',
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      print('📢 [NOTIFICATIONS] Marking notification as read: $notificationId');
      
      final response = await apiService.patch(
        Constants.notificationMarkAsRead(notificationId),
        requiresAuth: true,
      );

      if (response.success) {
        // Update local notification status
        final index = notifications.indexWhere((n) => n['_id'] == notificationId);
        if (index != -1) {
          notifications[index]['read'] = true;
          notifications.refresh();
          unreadCount.value = notifications
              .where((notification) => notification['read'] == false)
              .length;
        }
        print('📢 [NOTIFICATIONS] ✅ Marked as read');
      } else {
        print('📢 [NOTIFICATIONS] ❌ Failed to mark as read: ${response.message}');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error marking as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      print('📢 [NOTIFICATIONS] Marking all notifications as read');
      
      final response = await apiService.patch(
        Constants.notificationsMarkAllAsRead,
        requiresAuth: true,
      );

      if (response.success) {
        // Update all local notifications
        for (var notification in notifications) {
          notification['read'] = true;
        }
        notifications.refresh();
        unreadCount.value = 0;
        print('📢 [NOTIFICATIONS] ✅ All marked as read');
      } else {
        print('📢 [NOTIFICATIONS] ❌ Failed to mark all as read: ${response.message}');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error marking all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      print('📢 [NOTIFICATIONS] Deleting notification: $notificationId');
      
      final response = await apiService.delete(
        Constants.getNotificationDelete(notificationId),
        requiresAuth: true,
      );

      if (response.success) {
        // Remove from local list
        notifications.removeWhere((n) => n['_id'] == notificationId);
        notifications.refresh();
        
        // Update unread count
        unreadCount.value = notifications
            .where((notification) => notification['read'] == false)
            .length;
            
        print('📢 [NOTIFICATIONS] ✅ Notification deleted');
      } else {
        print('📢 [NOTIFICATIONS] ❌ Failed to delete: ${response.message}');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error deleting: $e');
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    print('📢 [NOTIFICATIONS] Refreshing notifications');
    await fetchNotifications();
  }


  /// Check notification permissions
  Future<bool> checkNotificationPermissions() async {
    return await LocalNotificationService.checkPermissions();
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    return await LocalNotificationService.requestPermissions();
  }

  /// Start periodic notification fetching every 2 minutes
  void _startPeriodicFetching() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      fetchNotifications();
    });
  }

  @override
  void onClose() {
    _periodicTimer?.cancel();
    super.onClose();
  }

  /// Get notification settings info
  String getNotificationInfo() {
    return '''
Notifications: ${notifications.length}
Unread: ${unreadCount.value}
''';
  }

  /// Clear all notifications locally
  void clearAllNotifications() {
    print('📢 [NOTIFICATIONS] Clearing all local notifications');
    notifications.clear();
    unreadCount.value = 0;
  }

  /// Load more notifications (pagination)
  void loadMoreNotifications() {
    final currentCount = notifications.length;
    // _webSocketService.requestNotificationHistory(
    //   limit: 20,
    //   skip: currentCount,
    // );
  }

  /// Get notifications by type
  List<Map<String, dynamic>> getNotificationsByType(String type) {
    return notifications.where((n) => n['type'] == type).toList();
  }

  /// Get unread notifications
  List<Map<String, dynamic>> getUnreadNotifications() {
    return notifications.where((n) => n['read'] == false).toList();
  }

  /// Check if there are any unread quiz assignments
  bool hasUnreadQuizAssignments() {
    return notifications.any((n) => 
      n['type'] == 'quiz_assigned' && n['read'] == false);
  }

  /// Get latest quiz assignment notification
  Map<String, dynamic>? getLatestQuizAssignment() {
    final quizNotifications = notifications
        .where((n) => n['type'] == 'quiz_assigned')
        .toList();
    
    if (quizNotifications.isNotEmpty) {
      return quizNotifications.first;
    }
    return null;
  }

}
