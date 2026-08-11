import 'package:ADDvEEG/utils/notifications/Helper.dart';
import 'package:ADDvEEG/screens/adminScreens/adminSide.dart';
import 'package:ADDvEEG/screens/doctorScreens/doctorView.dart';
import 'package:ADDvEEG/screens/landing.dart';
import 'package:ADDvEEG/screens/patientScreens/patient_login.dart';
import 'package:ADDvEEG/screens/patientScreens/patient_info_form.dart';
import 'package:ADDvEEG/screens/relativeScreens/relativeSide.dart';
import 'package:ADDvEEG/screens/auth/otp_verification.dart';
import 'package:ADDvEEG/theme/app_theme.dart';
import 'package:ADDvEEG/translations/app_translations.dart';
import 'package:ADDvEEG/controllers/patientSideControllers/getProfileController.dart';
import 'package:ADDvEEG/services/notification_service.dart';
import 'package:ADDvEEG/controllers/notification_controller.dart';
import 'package:ADDvEEG/controllers/language_controller.dart';
import 'package:ADDvEEG/controllers/theme_controller.dart';
import 'package:ADDvEEG/services/location_service.dart';
import 'package:ADDvEEG/services/api_service.dart';
import 'package:ADDvEEG/controllers/patientSideControllers/bluetoothConnection_controller.dart';
import 'package:ADDvEEG/services/background_notification_service.dart';
import 'package:ADDvEEG/Constants/constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/landing.dart';
import 'services/local_notification_service.dart';
// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';


import 'firebase_options.dart';

Future myBackgroundMessageHandler(RemoteMessage message) async {
  if (message.notification != null) {
    print('Handling a background message ${message.notification}');
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotifications =
    FlutterLocalNotificationsPlugin();
var role;

Future main() async {
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize controllers
  final languageController = Get.put(LanguageController());
  final themeController = Get.put(ThemeController());
  
  // Initialize services
  Get.put(ApiService());
  Get.put(LocationService());
  Get.put(NotificationController());
  Get.put(BluetoothController());


  if (!GetPlatform.isWeb) {
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });
    try {
      if (GetPlatform.isMobile) {
        await FirebaseMessaging.instance.getInitialMessage();
        await HelperNotification.initialize(flutterLocalNotifications);
        FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
        
        // Initialize local notifications
        await LocalNotificationService.initialize();
        
        // Initialize background notification service
        await BackgroundNotificationService.initialize();
      }
    } catch (er) {
      print(er);
    }
  }

  if (await GetStorage().read('timestamp') != null &&
      (DateTime.fromMillisecondsSinceEpoch(GetStorage().read('timestamp'))
              .difference(DateTime.now())
              .inDays
              .abs()) >=
          3) {
    GetStorage().erase();
  }

  // Normal role detection
  role = await GetStorage().read('loginDetails') != null
      ? await GetStorage().read('loginDetails')['user']['role']
      : null;

  // Print API configuration for debugging
  Constants.printConfig();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();

    return Obx(() => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.theme,
          translations: AppTranslations(),
          locale: languageController.currentLocale.value,
          fallbackLocale: const Locale('en'),
          title: 'EEG Mental Health App',
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () {
              // Check if user is in OTP verification flow
              final isInOtpFlow = GetStorage().read('otp_flow_active') ?? false;
              final otpEmail = GetStorage().read('otp_email');
              
              if (isInOtpFlow && otpEmail != null) {
                print('🔐 [APP_INIT] Restoring OTP verification flow for: $otpEmail');
                return OtpVerificationScreen(email: otpEmail);
              }
              
              return role == null
                  ? const LandingPage()
                  : role == 'USER' || role == 'PATIENT'
                      ? PatientLogin()
                      : role == 'DOCTOR'
                          ? DoctorView()
                          : role == 'RELATIVE'
                              ? RelativeSide()
                              : AdminMain();
            }),
            GetPage(name: '/PatientLogin', page: () => PatientLogin()),
            GetPage(name: '/PatientInfoForm', page: () => const PatientInfoForm()),
            GetPage(name: '/LandingPage', page: () => const LandingPage()),
            GetPage(name: '/DoctorView', page: () => DoctorView()),
            GetPage(name: '/RelativeSide', page: () => RelativeSide()),
            GetPage(name: '/AdminMain', page: () => AdminMain()),
          ],
        ));
  }
}
