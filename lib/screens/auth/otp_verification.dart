import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ADDvEEG/controllers/auth/otp_controller.dart';
import 'package:ADDvEEG/screens/auth/emailLogin.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  
  const OtpVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with WidgetsBindingObserver {
  final OtpController otpController = Get.put(OtpController());
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    // Initialize with email
    otpController.initializeWithEmail(widget.email);
    // Save OTP flow state to prevent redirect on app switch
    _saveOtpFlowState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App goes to background - reinforce OTP state
        _saveOtpFlowState();
        print('🔐 [OTP] App paused - OTP state saved');
        break;
      case AppLifecycleState.resumed:
        // App comes back to foreground - ensure we're still in OTP flow
        _saveOtpFlowState();
        print('🔐 [OTP] App resumed - OTP state reinforced');
        break;
      default:
        break;
    }
  }

  void _saveOtpFlowState() async {
    final storage = GetStorage();
    await storage.write('otp_flow_active', true);
    await storage.write('otp_email', widget.email);
    print('🔐 [OTP] Saved OTP flow state for email: ${widget.email}');
  }

  void _clearOtpFlowState() async {
    final storage = GetStorage();
    await storage.remove('otp_flow_active');
    await storage.remove('otp_email');
    print('🔐 [OTP] Cleared OTP flow state');
  }

  @override
  void dispose() {
    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Update OTP in controller
    String otp = _otpControllers.map((controller) => controller.text).join();
    otpController.otp.text = otp;
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: _focusNodes[index].hasFocus 
              ? const Color(0xFF0850FD) 
              : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) => _onOtpChanged(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Obx(
        () => ModalProgressHUD(
          inAsyncCall: otpController.isLoading.value,
          progressIndicator: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0850FD)),
          ),
          child: Container(
            height: screenHeight,
            width: screenWidth,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: isSmallScreen ? 40 : 60),
                    
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          _clearOtpFlowState();
                          Get.back();
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 20 : 40),
                    
                    // Title
                    Text(
                      'Verify Your Email',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 28 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // Subtitle
                    Text(
                      'We\'ve sent a 6-digit verification code to',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Email display
                    Text(
                      widget.email,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0850FD),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: isSmallScreen ? 40 : 60),
                    
                    // OTP input fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) => _buildOtpField(index)),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 40 : 60),
                    
                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (otpController.otp.text.length == 6) {
                            bool success = await otpController.verifyOtp();
                            if (success) {
                              // Clear OTP flow state on successful verification
                              _clearOtpFlowState();
                              Get.offAll(() => UsernameLogin());
                              Get.snackbar(
                                'Success',
                                'Email verified successfully! Please login with your credentials.',
                                backgroundColor: Colors.green.withValues(alpha: 0.1),
                                colorText: Colors.green,
                                duration: const Duration(seconds: 3),
                              );
                            }
                          } else {
                            Get.snackbar(
                              'Error',
                              'Please enter the complete 6-digit OTP',
                              backgroundColor: Colors.red.withValues(alpha: 0.1),
                              colorText: Colors.red,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0850FD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Verify Email',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Resend OTP
                    Obx(() => TextButton(
                      onPressed: otpController.isResending.value 
                          ? null 
                          : () async {
                              await otpController.resendOtp();
                            },
                      child: otpController.isResending.value
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFF0850FD),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Resending...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF0850FD),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Didn\'t receive the code? Resend',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF0850FD),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    )),
                    
                    SizedBox(height: isSmallScreen ? 20 : 40),
                    
                    // Help text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Check your email inbox and spam folder for the verification code',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
