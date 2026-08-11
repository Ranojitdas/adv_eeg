import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:ADDvEEG/models/allDoctorModel.dart';
import 'package:ADDvEEG/screens/auth/emaillogin.dart';
import 'package:ADDvEEG/screens/auth/otp_verification.dart';
import 'package:ADDvEEG/screens/patientScreens/patient_info_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../Constants/constants.dart';
import '../../services/api_service.dart';

class SignUpController extends GetxController {
  SignUpController({required this.role});
  final role;

  // Note: OTP verification only applies to doctors and relatives, not patients

  // Local notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    developer.log('SignUpController initialized with role: $role');
    _initializeNotifications();
    // Reset relationship selection to prevent dropdown errors
    selectedRelationship.value = '';
    relationshipToPatient.clear();
    if (role != 'DOCTOR') {
      fetchRole();
    }
  }

  /// Initialize local notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
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
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Show OTP notification
  Future<void> _showOtpNotification(String otp) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'otp_channel',
      'OTP Notifications',
      channelDescription: 'Notifications for OTP verification codes',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      autoCancel: false,
      ongoing: false,
      styleInformation: BigTextStyleInformation(''),
    );
    
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    
    await flutterLocalNotificationsPlugin.show(
      0,
      'EEG App - Verification Code',
      'Your OTP is: $otp',
      notificationDetails,
    );
  }

  TextEditingController firstName = TextEditingController();
  TextEditingController lastName = TextEditingController();
  TextEditingController age = TextEditingController();
  var isLoading = false.obs;
  var isVerifying = false.obs;
  var verificationCode = ''.obs;
  var isEmailVerified = false.obs;
  
  // Debouncing variables
  DateTime? _lastSignupTime;
  static const int _debounceTimeMs = 3000; // 3 seconds between signup attempts
  TextEditingController verificationCodeController = TextEditingController();

  TextEditingController email = TextEditingController();
  TextEditingController phoneNo = TextEditingController();
  var bloodGroup = "A_POSITIVE".obs;
  var doctor = ''.obs;
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;
  var passwordError = ''.obs;
  var confirmPasswordError = ''.obs;
  var emailError = ''.obs;
  var phoneError = ''.obs;
  var gender = "Male".obs;
  var userList = AllDoctorModel().obs;

  // New fields for relative registration
  TextEditingController invitationCode = TextEditingController();
  TextEditingController relationshipToPatient = TextEditingController();
  var selectedRelationship = ''.obs; // For dropdown selection
  TextEditingController specialization = TextEditingController();
  
  // Additional fields to match database structure
  var selectedPatientId = ''.obs; // For relatives - patient ObjectId reference
  var defaultAvatar = 'https://example.com/default-avatar.png'.obs;
  var notificationPreferences = {
    'email': true,
    'inApp': true,
    'isOnline': false
  }.obs;

  // Real-time password validation
  void validatePassword() {
    String pwd = password.text;
    if (pwd.isEmpty) {
      passwordError.value = '';
      return;
    }
    
    if (pwd.length < 8) {
      passwordError.value = 'Password must be at least 8 characters';
      return;
    }
    
    bool hasLetter = pwd.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = pwd.contains(RegExp(r'[0-9]'));
    
    if (!hasLetter || !hasNumber) {
      passwordError.value = 'Password must contain both letters and numbers';
      return;
    }
    
    passwordError.value = '';
  }
  
  // Real-time confirm password validation
  void validateConfirmPassword() {
    if (confirmPassword.text.isEmpty) {
      confirmPasswordError.value = '';
      return;
    }
    
    if (password.text != confirmPassword.text) {
      confirmPasswordError.value = 'Passwords do not match';
      return;
    }
    
    confirmPasswordError.value = '';
  }
  
  // Real-time email validation
  void validateEmail() {
    String emailText = email.text;
    if (emailText.isEmpty) {
      emailError.value = '';
      return;
    }
    
    // Email regex pattern
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(pattern);
    
    if (!regex.hasMatch(emailText)) {
      emailError.value = 'Please enter a valid email address';
      return;
    }
    
    emailError.value = '';
  }
  
  // Real-time phone validation
  void validatePhone() {
    String phoneText = phoneNo.text;
    if (phoneText.isEmpty) {
      phoneError.value = '';
      return;
    }
    
    // Remove any spaces, dashes, or parentheses
    String cleanPhone = phoneText.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it contains only digits and has appropriate length
    if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      phoneError.value = 'Phone number should contain only digits';
      return;
    }
    
    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      phoneError.value = 'Phone number should be 10-15 digits';
      return;
    }
    
    phoneError.value = '';
  }

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    age.dispose();
    email.dispose();
    phoneNo.dispose();
    password.dispose();
    confirmPassword.dispose();
    verificationCodeController.dispose();
    invitationCode.dispose();
    relationshipToPatient.dispose();
    specialization.dispose();
    super.onClose();
  }

  Future<void> fetchRole() async {
    try {
      isLoading(true);
      String? url;
      if (role == 'PATIENT') {
        // For patients, fetch doctors to assign
        url = Constants.doctorGetAllDoctors;
      } else if (role == 'RELATIVE') {
        // For relatives, we might need a different approach
        // For now, skip this as relatives don't need to select patients during signup
        isLoading(false);
        return;
      }

      if (url == null) {
        isLoading(false);
        return;
      }

      final response = await apiService.get(
        url,
        requiresAuth: false,
        fromJson: (json) => allDoctorModelFromJson(jsonEncode(json)),
      );

      if (response.success) {
        userList.value = response.data!;
      } else {
        Get.snackbar(
          'Error',
          'Failed to fetch roles: ${response.message}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch roles: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading(false);
    }
  }

  /// Generate and show OTP notification for testing
  /// In production, OTP should be sent via email by the backend
  Future<void> generateTestOtp() async {
    try {
      // Generate a 6-digit OTP for testing
      String testOtp = (100000 + Random().nextInt(900000)).toString();
      verificationCode.value = testOtp;
      
      print('🔐 [OTP] Generated test OTP: $testOtp');
      
      // Show local notification with OTP for testing
      await _showOtpNotification(testOtp);
      
      Get.snackbar(
        'OTP Generated',
        'Check your notifications for the verification code (Test Mode)',
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        colorText: Colors.blue,
        duration: const Duration(seconds: 3),
      );
    } catch (err) {
      print('🔐 [OTP] ❌ Error generating test OTP: $err');
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      isVerifying(true);
      developer.log('Starting email verification process');

      if (email.text.isEmpty) {
        throw Exception('Email is empty');
      }

      // All roles now require OTP verification
      await createUser();
    } catch (e) {
      developer.log('Error sending verification email: ${e.toString()}');
      Get.snackbar(
        'Error',
        'Failed to send verification email: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isVerifying(false);
    }
  }

  Future<void> verifyEmail(String code) async {
    try {
      developer.log('Verifying email with code: $code');
      if (code == verificationCode.value) {
        isEmailVerified.value = true;
        developer.log('Email verified successfully');
        Get.snackbar(
          'Success',
          'Email verified successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
      } else {
        developer.log('Invalid verification code');
        Get.snackbar(
          'Error',
          'Invalid verification code',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      developer.log('Error verifying email: ${e.toString()}');
      Get.snackbar(
        'Error',
        'Failed to verify email: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

  // Create user with exact API documentation structure
  Future<void> createUser() async {
    // Prevent multiple rapid signup attempts
    if (isLoading.value) {
      print('🚫 [REGISTER] Signup already in progress, ignoring');
      return;
    }
    
    // Check debounce time
    final now = DateTime.now();
    if (_lastSignupTime != null && 
        now.difference(_lastSignupTime!).inMilliseconds < _debounceTimeMs) {
      Get.snackbar(
        'Please Wait',
        'Please wait a moment before trying again',
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        colorText: Colors.orange,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    try {
      isLoading.value = true;
      _lastSignupTime = now; // Update last signup time
      print('🔐 [REGISTER] Starting user creation process for role: $role');

      // Skip email verification check for doctors and relatives during initial creation
      // They will verify OTP after user creation

      // Validate required fields based on role
      if (!_validateRequiredFields()) {
        return;
      }

      // Build request body based on exact API documentation
      final Map<String, dynamic> requestBody = _buildRequestBody();

      print('🔐 [REGISTER] Request Body: ${jsonEncode(requestBody)}');
      print('🔐 [REGISTER] API URL: ${Constants.userRegister}');

      final response = await apiService.post(
        Constants.userRegister,
        body: requestBody,
        requiresAuth: false,
      );

      print('🔐 [REGISTER] Response Status: ${response.statusCode}');
      print('🔐 [REGISTER] Response Body: ${response.rawData}');

      if (response.success) {
        print('🔐 [REGISTER] ✅ User created successfully!');
        
        // Save credentials for easy login after OTP verification
        GetStorage box = GetStorage();
        await box.write('signup_email', email.text);
        await box.write('signup_password', password.text);
        
        // All roles now require OTP verification
        Get.snackbar(
          'Success',
          'Account created! Check your email for OTP verification.',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 3),
        );

        await Future.delayed(const Duration(seconds: 2));
        
        // Navigate to OTP verification screen for all roles
        Get.offAll(() => OtpVerificationScreen(email: email.text));
      } else {
        // Handle different signup error scenarios with user-friendly messages
        String errorMessage = _getSignupErrorMessage(response.statusCode, response.message);
        Get.snackbar('Registration Failed', errorMessage,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ [REGISTER] Error creating user: $e');
      
      // Handle network and other errors
      String errorMessage = _getNetworkErrorMessage(e);
      Get.snackbar('Registration Error', errorMessage,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Validate required fields based on role
  bool _validateRequiredFields() {
    // Common required fields
    if (firstName.text.isEmpty || lastName.text.isEmpty || email.text.isEmpty || password.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all required fields',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return false;
    }

    // Password validation - minimum 8 characters and alphanumeric
    if (password.text.length < 8) {
      Get.snackbar(
        'Error',
        'Password must be at least 8 characters',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return false;
    }

    // Check if password contains both letters and numbers (alphanumeric)
    bool hasLetter = password.text.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = password.text.contains(RegExp(r'[0-9]'));
    
    if (!hasLetter || !hasNumber) {
      Get.snackbar(
        'Error',
        'Password must contain both letters and numbers',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return false;
    }

    // Role-specific validations
    if (role == 'PATIENT') {
      if (doctor.value.isEmpty) {
        Get.snackbar(
          'Error',
          'Please select a doctor',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
        return false;
      }
    } else if (role == 'RELATIVE') {
      if (invitationCode.text.isEmpty || relationshipToPatient.text.isEmpty) {
        Get.snackbar(
          'Error',
          'Please fill invitation code and relationship',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
        return false;
      }
    } else if (role == 'DOCTOR') {
      if (specialization.text.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter specialization',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
        return false;
      }
    }

    return true;
  }

  // Build request body based on exact API documentation
  Map<String, dynamic> _buildRequestBody() {
    // Use separate firstName and lastName fields
    final Map<String, dynamic> baseBody = {
      "firstName": firstName.text,
      "lastName": lastName.text,
      "email": email.text,
      "password": password.text,
      "role": role,
    };

    // Add role-specific fields according to API documentation
    if (role == 'PATIENT') {
      baseBody["doctorId"] = doctor.value;
    } else if (role == 'RELATIVE') {
      baseBody["invitationCode"] = invitationCode.text;
      baseBody["relationshipToPatient"] = relationshipToPatient.text;
      // Note: patient field will be set by backend based on invitationCode
    } else if (role == 'DOCTOR') {
      baseBody["specialization"] = specialization.text;
    }

    return baseBody;
  }

  // Clear all form fields
  void _clearFormFields() {
    firstName.clear();
    lastName.clear();
    age.clear();
    email.clear();
    phoneNo.clear();
    password.clear();
    confirmPassword.clear();
    verificationCodeController.clear();
    invitationCode.clear();
    relationshipToPatient.clear();
    selectedRelationship.value = '';
    specialization.clear();

    isEmailVerified.value = false;
    verificationCode.value = '';
    doctor.value = '';
    gender.value = 'Male';
    bloodGroup.value = 'A_POSITIVE';
    selectedPatientId.value = '';
    defaultAvatar.value = 'https://example.com/default-avatar.png';
    notificationPreferences.value = {
      'email': true,
      'inApp': true,
      'isOnline': false
    };
  }

  // Get user-friendly error message for signup failures
  String _getSignupErrorMessage(int? statusCode, String? serverMessage) {
    switch (statusCode) {
      case 400:
        if (serverMessage?.toLowerCase().contains('email') == true) {
          if (serverMessage!.toLowerCase().contains('already exists') || 
              serverMessage.toLowerCase().contains('already taken')) {
            return 'This email is already registered. Please use a different email or try logging in';
          } else if (serverMessage.toLowerCase().contains('invalid') || 
                     serverMessage.toLowerCase().contains('format')) {
            return 'Please enter a valid email address';
          }
          return 'Please check your email address';
        } else if (serverMessage?.toLowerCase().contains('password') == true) {
          if (serverMessage!.toLowerCase().contains('weak') || 
              serverMessage.toLowerCase().contains('short')) {
            return 'Password is too weak. Please use at least 8 characters with letters and numbers';
          }
          return 'Please check your password requirements';
        } else if (serverMessage?.toLowerCase().contains('all fields are required') == true) {
          return 'Please fill in all required fields';
        } else if (serverMessage?.toLowerCase().contains('invitation') == true) {
          return 'Invalid invitation code. Please check with your doctor or patient';
        } else if (serverMessage?.toLowerCase().contains('doctor') == true) {
          return 'Please select a valid doctor';
        }
        return 'Please check all your information and try again';
      case 409:
        return 'This email is already registered. Please use a different email or try logging in';
      case 422:
        if (serverMessage?.toLowerCase().contains('email') == true) {
          return 'Please enter a valid email address';
        } else if (serverMessage?.toLowerCase().contains('password') == true) {
          return 'Password must be at least 8 characters long';
        }
        return 'Please check your information and try again';
      case 500:
        return 'Server error. Please try again in a few minutes';
      default:
        if (serverMessage?.isNotEmpty == true) {
          // Clean up common server error messages
          if (serverMessage!.toLowerCase().contains('email already exists') ||
              serverMessage.toLowerCase().contains('user already exists')) {
            return 'This email is already registered. Please use a different email or try logging in';
          } else if (serverMessage.toLowerCase().contains('invalid email')) {
            return 'Please enter a valid email address';
          } else if (serverMessage.toLowerCase().contains('password too short') ||
                     serverMessage.toLowerCase().contains('password must be')) {
            return 'Password must be at least 8 characters long';
          } else if (serverMessage.toLowerCase().contains('invitation code') ||
                     serverMessage.toLowerCase().contains('invalid invitation')) {
            return 'Invalid invitation code. Please check with your doctor or patient';
          } else if (serverMessage.toLowerCase().contains('doctor not found')) {
            return 'Selected doctor not found. Please choose a different doctor';
          } else if (serverMessage.toLowerCase().contains('all fields are required')) {
            return 'Please fill in all required fields';
          }
        }
        return 'Registration failed. Please check your information and try again';
    }
  }

  // Get user-friendly error message for network issues
  String _getNetworkErrorMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socketexception') || 
        errorStr.contains('failed host lookup') ||
        errorStr.contains('no address associated with hostname')) {
      return 'No internet connection. Please check your network and try again';
    } else if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Connection timeout. Please check your internet and try again';
    } else if (errorStr.contains('connection refused') || 
               errorStr.contains('connection failed')) {
      return 'Unable to connect to server. Please try again later';
    } else if (errorStr.contains('certificate') || errorStr.contains('ssl')) {
      return 'Security error. Please check your internet connection';
    } else if (errorStr.contains('format exception') || 
               errorStr.contains('json')) {
      return 'Server response error. Please try again';
    } else {
      return 'Registration error. Please check your information and try again';
    }
  }
}
