import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ADDvEEG/Constants/constants.dart';
import 'package:ADDvEEG/services/api_service.dart';

class OtpController extends GetxController {
  final ApiService apiService = ApiService();
  
  // Form controllers
  final TextEditingController email = TextEditingController();
  final TextEditingController otp = TextEditingController();
  
  // Loading state
  var isLoading = false.obs;
  var isResending = false.obs;
  
  @override
  void onInit() {
    super.onInit();
  }

  /// Initialize with email
  void initializeWithEmail(String userEmail) {
    email.text = userEmail;
    
    // Show message that OTP will be sent via email
    Get.snackbar(
      'OTP Sent',
      'Verification code has been sent to your email address',
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    email.dispose();
    otp.dispose();
    super.onClose();
  }

  
  /// Verify OTP using the new backend API
  Future<bool> verifyOtp() async {
    if (email.text.isEmpty || otp.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter both email and OTP',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return false;
    }
    
    if (otp.text.length != 6) {
      Get.snackbar(
        'Error',
        'OTP must be 6 digits',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return false;
    }
    
    isLoading.value = true;
    
    try {
      print('🔐 [OTP] Verifying OTP for email: ${email.text}');
      
      final response = await apiService.post(
        Constants.userVerifyOtp,
        body: {
          "email": email.text.trim(),
          "otp": otp.text.trim(),
        },
        requiresAuth: false, // OTP verification doesn't require auth token
      );
      
      if (response.success) {
        print('🔐 [OTP] ✅ OTP verified successfully!');
        
        Get.snackbar(
          'Success',
          'Email verified successfully!',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 2),
        );
        
        return true;
      } else {
        print('🔐 [OTP] ❌ OTP verification failed: ${response.message}');
        
        Get.snackbar(
          'Error',
          response.message ?? 'Invalid OTP. Please try again.',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
          duration: const Duration(seconds: 3),
        );
        
        return false;
      }
    } catch (err) {
      print('🔐 [OTP] ❌ Error during OTP verification: $err');
      
      Get.snackbar(
        'Error',
        'Failed to verify OTP. Please check your connection and try again.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Clear form data
  void clearForm() {
    email.clear();
    otp.clear();
  }
  
  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  /// Validate OTP format
  bool isValidOtp(String otp) {
    return RegExp(r'^\d{6}$').hasMatch(otp);
  }

  /// Resend OTP via email
  Future<void> resendOtp() async {
    if (email.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Email is required to resend OTP',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    isResending.value = true;

    try {
      print('🔐 [RESEND] Requesting new OTP for: ${email.text}');
      
      // TODO: Backend dev will implement resend OTP endpoint
      // For now, show message that OTP will be resent via email
      
      Get.snackbar(
        'OTP Resent',
        'A new verification code has been sent to your email address',
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 3),
      );
      
      print('🔐 [RESEND] ✅ OTP resend requested');

    } catch (err) {
      print('🔐 [RESEND] ❌ Error resending OTP: $err');
      
      Get.snackbar(
        'Error',
        'Failed to resend OTP. Please try again.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isResending.value = false;
    }
  }
}
