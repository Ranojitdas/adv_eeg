import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth/forgot_password_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ForgotPasswordController controller = Get.put(ForgotPasswordController());
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/bg2.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.7),
                  BlendMode.darken,
                ),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 20.0 : 32.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 
                             MediaQuery.of(context).padding.top - 
                             MediaQuery.of(context).padding.bottom - 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                      ),
                      
                      SizedBox(height: size.height * 0.05),
                      
                      // Header
                      _buildHeader(),
                      
                      SizedBox(height: size.height * 0.05),
                      
                      // Form content
                      Obx(() => controller.emailSent.value 
                          ? _buildSuccessMessage(controller, isSmallScreen)
                          : _buildEmailStep(controller, isSmallScreen)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forgot Password?',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep(ForgotPasswordController controller, bool isSmallScreen) {
    return Column(
      children: [
        // Email input
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              hintText: 'Enter your email address',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Send reset email button
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.requestPasswordReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isLoading.value 
                    ? Colors.grey.withValues(alpha: 0.5)
                    : const Color(0xFF0850FD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: controller.isLoading.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sending...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Send Reset Email',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Back to login
        Center(
          child: TextButton(
            onPressed: () => Get.back(),
            child: RichText(
              text: TextSpan(
                text: 'Remember your password? ',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'Sign In',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0850FD),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessMessage(ForgotPasswordController controller, bool isSmallScreen) {
    return Column(
      children: [
        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.email_outlined,
            color: Colors.green,
            size: 40,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Success title
        Text(
          'Email Sent!',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Success message
        Text(
          'We\'ve sent a password reset link to ${controller.emailController.text.trim()}. Click the link in your email to reset your password.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Resend email button
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () {
                controller.emailSent.value = false;
                controller.requestPasswordReset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isLoading.value
                    ? Colors.grey.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: controller.isLoading.value
                        ? Colors.grey.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                elevation: 0,
              ),
              child: controller.isLoading.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sending...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Resend Email',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Back to login
        Center(
          child: TextButton(
            onPressed: () => Get.back(),
            child: RichText(
              text: TextSpan(
                text: 'Back to ',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'Sign In',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0850FD),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

}
