import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HelperNotification {
  static Future initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotifications) async {
    // Android Initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // General Initialization (for Android only)
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Initialize the FlutterLocalNotificationsPlugin
    await flutterLocalNotifications.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap action
      if (response.payload != null && response.payload!.isNotEmpty) {
        print('Notification tapped! Payload: ${response.payload}');
      }
    });

    // Firebase Cloud Messaging: Set foreground notification presentation options
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for incoming messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received message: ${message.notification!.title}");
      HelperNotification.showNotification(flutterLocalNotifications, message);
    });

    // Handle notification when the app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.notification!.title}');
    });
  }

  // Function to display the notification
  static void showNotification(
      FlutterLocalNotificationsPlugin flutterLocalNotifications,
      RemoteMessage message) async {
    // Big Text style notification
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      message.notification!.body.toString(),
      htmlFormatBigText: true,
      contentTitle: message.notification!.title,
      htmlFormatContentTitle: true,
      summaryText: message.notification!.title,
      htmlFormatSummaryText: true,
    );

    // Android-specific notification settings
    AndroidNotificationDetails androidNotificationChannel =
        AndroidNotificationDetails(
      'channel_id', // Unique channel ID
      'channel_name', // Channel name
      importance: Importance.max,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    // Platform-specific notification details (only for Android in this case)
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidNotificationChannel);

    // Show notification with a unique ID (0 here, but you can make it dynamic)
    await flutterLocalNotifications.show(
      0, // Notification ID
      message.notification!.title, // Title of the notification
      message.notification!.body, // Body of the notification
      platformChannelSpecifics, // Platform-specific details
      payload: json.encode(message.data), // Payload (e.g., additional data)
    );
  }
}
