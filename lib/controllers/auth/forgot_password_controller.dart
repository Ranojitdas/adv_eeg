import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Constants/constants.dart';
import '../../services/api_service.dart';

class ForgotPasswordController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();
  
  // Text controllers
  final emailController = TextEditingController();
  
  // Observable variables
  var isLoading = false.obs;
  var emailSent = false.obs; // Track if email was sent successfully
  
  // Debouncing variables
  DateTime? _lastRequestTime;
  static const int _debounceTimeMs = 3000; // 3 seconds between requests
  
  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
  
  
  // Request password reset
  Future<void> requestPasswordReset() async {
    // Prevent multiple rapid requests
    if (isLoading.value) {
      print('🚫 [FORGOT_PASSWORD] Request already in progress, ignoring');
      return;
    }
    
    // Check debounce time
    final now = DateTime.now();
    if (_lastRequestTime != null && 
        now.difference(_lastRequestTime!).inMilliseconds < _debounceTimeMs) {
      _showErrorMessage('Please wait a moment before requesting another email');
      return;
    }
    
    if (emailController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your email address');
      return;
    }
    
    if (!GetUtils.isEmail(emailController.text.trim())) {
      _showErrorMessage('Please enter a valid email address');
      return;
    }
    
    try {
      isLoading.value = true;
      _lastRequestTime = now; // Update last request time
      
      print('🔐 [FORGOT_PASSWORD] Requesting password reset for: ${emailController.text.trim()}');
      
      final response = await apiService.post(
        Constants.userForgotPassword,
        body: {
          'email': emailController.text.trim(),
        },
        requiresAuth: false,
        fromJson: (json) => json,
      );
      
      if (response.success) {
        print('🔐 [FORGOT_PASSWORD] ✅ Password reset email sent successfully');
        
        // Mark email as sent (this will trigger the success screen)
        emailSent.value = true;
        
      } else {
        print('🔐 [FORGOT_PASSWORD] ❌ Failed to send reset email: ${response.message}');
        _showErrorMessage(_getForgotPasswordErrorMessage(response));
      }
      
    } catch (e) {
      print('🔐 [FORGOT_PASSWORD] ❌ Exception: $e');
      _showErrorMessage(_getNetworkErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }
  
  
  // Show error message
  void _showErrorMessage(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
      titleText: Text(
        'Error',
        style: GoogleFonts.poppins(
          color: Colors.red,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          color: Colors.red,
          fontSize: 14,
        ),
      ),
    );
  }
  
  // Get user-friendly error message for forgot password
  String _getForgotPasswordErrorMessage(dynamic response) {
    final statusCode = response.statusCode ?? 0;
    final message = response.message?.toString().toLowerCase() ?? '';
    
    if (statusCode == 404 || message.contains('not found') || message.contains('user does not exist')) {
      return 'No account found with this email address. Please check your email or sign up for a new account.';
    } else if (statusCode == 429 || message.contains('too many')) {
      return 'Too many reset requests. Please wait a few minutes before trying again.';
    } else if (statusCode == 500) {
      return 'Server error. Please try again in a few minutes.';
    } else {
      return 'Failed to send reset email. Please try again.';
    }
  }
  
  
  // Get network error message
  String _getNetworkErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socketexception') || errorString.contains('failed host lookup')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Connection timeout. Please check your internet and try again.';
    } else if (errorString.contains('connection refused')) {
      return 'Unable to connect to server. Please try again later.';
    } else {
      return 'Network error. Please check your connection and try again.';
    }
  }
  
  // Reset form to initial state
  void resetForm() {
    emailController.clear();
    emailSent.value = false;
  }
}
