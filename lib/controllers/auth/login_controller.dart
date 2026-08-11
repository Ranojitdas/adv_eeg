import 'dart:convert';
import 'dart:io';

import 'package:ADDvEEG/screens/adminScreens/adminSide.dart';
import 'package:ADDvEEG/screens/doctorScreens/doctorView.dart';
import 'package:ADDvEEG/screens/relativeScreens/relativeSide.dart';
import 'package:ADDvEEG/screens/landing.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../Constants/constants.dart';
import '../../models/auth/loginModel.dart';
import '../../screens/patientScreens/patient_login.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class LoginController extends GetxController {
  var loginDetails = Login().obs;
  var isLoading = false.obs;
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  GetStorage box = GetStorage();
  final LocationService locationService = Get.put(LocationService());

  @override
  void onInit() {
    super.onInit();
    // Pre-fill with signup credentials if available
    loadSignupCredentials();
  }

  // Load signup credentials for easy login after OTP verification
  void loadSignupCredentials() {
    // Only load credentials if they exist and user hasn't successfully logged in before
    String? savedEmail = box.read('signup_email');
    String? savedPassword = box.read('signup_password');
    
    // Check if user has successfully logged in before
    bool hasLoggedInBefore = box.read('has_logged_in_before') ?? false;
    
    // Only auto-fill if user hasn't logged in before (fresh signup scenario)
    if (!hasLoggedInBefore && savedEmail != null && savedEmail.isNotEmpty) {
      username.text = savedEmail;
      if (savedPassword != null && savedPassword.isNotEmpty) {
        password.text = savedPassword;
      }
      
      // Clear credentials after loading to prevent future auto-fill
      box.remove('signup_email');
      box.remove('signup_password');
    }
  }

  // Clear login form
  void clearForm() {
    username.clear();
    password.clear();
  }

  // Register device for notifications
  getNotification() async {
    var token = ''.obs;
    await FirebaseMessaging.instance
        .getToken()
        .then((value) => token.value = value!);

    // Device registration endpoint doesn't exist in current backend
    // This feature will be implemented later
  }

  // Login user with exact API documentation structure
  login({bool rememberMe = false}) async {
    isLoading.value = true;
    if (!GetPlatform.isWeb) await getNotification();

    try {
      // Exact payload structure from API documentation
      final requestBody = {
        "email": username.text,
        "password": password.text,
      };

      final response = await apiService.post(
        Constants.userLogin,
        body: requestBody,
        requiresAuth: false,
        fromJson: (json) => Login.fromJson(json),
      );

      if (response.success) {
        loginDetails.value = response.data!;

        // Store login details with new structure
        final responseData = response.rawData!;
        final accessToken = responseData['data']['accessToken'];
        final refreshToken = responseData['data']['refreshToken'];
        final loggedInUser = responseData['data']['loggedInUser'];

        final loginDetailsToStore = {
          "token": accessToken,
          "refreshToken": refreshToken,
          "user": loggedInUser,
        };

        await box.write("loginDetails", loginDetailsToStore);
        await box.write("timestamp", DateTime.now().millisecondsSinceEpoch);
        
        // Mark that user has successfully logged in to prevent auto-fill on future app opens
        await box.write("has_logged_in_before", true);

        // Save credentials if rememberMe is true
        if (rememberMe) {
          List accounts = box.read('saved_accounts') ?? [];
          accounts.removeWhere((acc) => acc['email'] == username.text);
          accounts.add({'email': username.text, 'password': password.text});
          await box.write('saved_accounts', accounts);
        }

        // Update location on successful login
        await locationService.updateLocationOnLogin();

        // Navigate based on user role
        final userRole = loggedInUser['role'];

        if (userRole == 'USER' || userRole == 'PATIENT') {
          Get.offAll(() => PatientLogin());
        } else if (userRole == 'DOCTOR') {
          Get.offAll(() => DoctorView());
        } else if (userRole == 'RELATIVE') {
          Get.off(() => RelativeSide());
        } else if (userRole == 'ADMIN') {
          Get.off(() => AdminMain());
        } else {
          Get.snackbar('Error', 'Unknown user role: $userRole');
        }
      } else {
        // Handle different error scenarios with user-friendly messages
        String errorMessage = _getLoginErrorMessage(response.statusCode, response.message);
        Get.snackbar('Login Failed', errorMessage,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
      return response.statusCode;
    } catch (err) {
      // Handle network and other errors
      String errorMessage = _getNetworkErrorMessage(err);
      Get.snackbar('Connection Error', errorMessage,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Logout user
  logout() async {
    isLoading.value = true;

    try {
      final response = await apiService.post(
        Constants.userLogout,
        requiresAuth: true,
      );
    } catch (err) {
      // Handle logout error silently
    } finally {
      // Always clear local data regardless of API response
      apiService.clearAuth();
      box.remove('saved_accounts');

      Get.offAll(() => const LandingPage());
      isLoading.value = false;
    }
  }

  // Get current user details
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await apiService.get(
        Constants.userMe,
        requiresAuth: true,
      );

      if (response.success) {
        return response.rawData;
      } else {
        return null;
      }
    } catch (err) {
      return null;
    }
  }

  // Update user location
  Future<bool> updateLocation(double latitude, double longitude) async {
    print('📍 [LOCATION] Updating user location: $latitude, $longitude');

    try {
      final response = await apiService.patch(
        Constants.userUpdateLocation,
        body: {
          "coordinates": [latitude, longitude]
        },
        requiresAuth: true,
      );

      if (response.success) {
        print('📍 [LOCATION] ✅ Location updated successfully!');
        return true;
      } else {
        print('📍 [LOCATION] ❌ Failed to update location: ${response.message}');
        return false;
      }
    } catch (err) {
      print('📍 [LOCATION] ❌ Error updating location: $err');
      return false;
    }
  }

  // Get user-friendly error message for login failures
  String _getLoginErrorMessage(int? statusCode, String? serverMessage) {
    switch (statusCode) {
      case 400:
        if (serverMessage?.toLowerCase().contains('email') == true) {
          return 'Please enter a valid email address';
        } else if (serverMessage?.toLowerCase().contains('password') == true) {
          return 'Password is required';
        }
        return 'Please check your email and password';
      case 401:
        return 'Invalid email or password. Please try again';
      case 403:
        return 'Your account has been suspended. Please contact support';
      case 404:
        return 'Account not found. Please check your email or sign up';
      case 422:
        return 'Please enter valid email and password';
      case 429:
        return 'Too many login attempts. Please try again later';
      case 500:
        return 'Server error. Please try again in a few minutes';
      default:
        if (serverMessage?.isNotEmpty == true) {
          // Clean up technical error messages
          if (serverMessage!.toLowerCase().contains('invalid credentials') ||
              serverMessage.toLowerCase().contains('wrong password') ||
              serverMessage.toLowerCase().contains('incorrect password')) {
            return 'Invalid email or password. Please try again';
          } else if (serverMessage.toLowerCase().contains('user not found') ||
                     serverMessage.toLowerCase().contains('email not found')) {
            return 'Account not found. Please check your email or sign up';
          }
        }
        return 'Login failed. Please check your credentials and try again';
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
    } else {
      return 'Connection error. Please check your internet and try again';
    }
  }
}
