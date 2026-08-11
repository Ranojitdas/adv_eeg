// ignore_for_file: unnecessary_null_comparison, must_be_immutable

import 'package:ADDvEEG/controllers/auth/signUpController.dart';
import 'package:ADDvEEG/screens/auth/emailLogin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class SignUpPage extends StatefulWidget {
  SignUpPage({super.key, required this.role});
  final String role;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with WidgetsBindingObserver {
  late SignUpController signUpController;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    signUpController = Get.put(SignUpController(role: widget.role));
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Prevent automatic redirects when app goes to background/foreground
    if (state == AppLifecycleState.paused || state == AppLifecycleState.resumed) {
      print('📱 [SIGNUP] App lifecycle changed to $state - maintaining signup screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            // Ensure we always go back to login screen
            Get.off(() => const UsernameLogin());
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/bg2.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: Obx(
          () => ModalProgressHUD(
            inAsyncCall: signUpController.isLoading.value,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in your details to get started',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildTextField(
                              label: 'First Name*',
                              hint: 'Enter your first name',
                              controller: signUpController.firstName,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Last Name*',
                              hint: 'Enter your last name',
                              controller: signUpController.lastName,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Age*',
                              hint: 'Enter your age',
                              controller: signUpController.age,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            Obx(() => _buildValidatedTextField(
                              label: 'Email*',
                              hint: 'Enter your email',
                              controller: signUpController.email,
                              keyboardType: TextInputType.emailAddress,
                              errorText: signUpController.emailError.value,
                              onChanged: (value) => signUpController.validateEmail(),
                            )),
                            // Email verification removed - OTP verification happens after user creation
                            const SizedBox(height: 16),
                            Obx(() => _buildPasswordField(
                              label: 'Password*',
                              hint: 'Enter password (min 8 chars, letters & numbers)',
                              controller: signUpController.password,
                              isVisible: signUpController.isPasswordVisible.value,
                              onVisibilityToggle: () => signUpController.isPasswordVisible.toggle(),
                              errorText: signUpController.passwordError.value,
                              onChanged: (value) => signUpController.validatePassword(),
                            )),
                            const SizedBox(height: 16),
                            Obx(() => _buildPasswordField(
                              label: 'Confirm Password*',
                              hint: 'Confirm your password',
                              controller: signUpController.confirmPassword,
                              isVisible: signUpController.isConfirmPasswordVisible.value,
                              onVisibilityToggle: () => signUpController.isConfirmPasswordVisible.toggle(),
                              errorText: signUpController.confirmPasswordError.value,
                              onChanged: (value) => signUpController.validateConfirmPassword(),
                            )),
                            const SizedBox(height: 16),
                            Obx(() => _buildValidatedTextField(
                              label: 'Phone No.',
                              hint: 'Enter your phone no.',
                              controller: signUpController.phoneNo,
                              keyboardType: TextInputType.phone,
                              errorText: signUpController.phoneError.value,
                              onChanged: (value) => signUpController.validatePhone(),
                            )),
                            const SizedBox(height: 16),
                            _buildDropdown(
                              label: 'Gender*',
                              value: signUpController.gender.value,
                              items: ['Male', 'Female', 'Other'],
                              onChanged: (value) =>
                                  signUpController.gender.value = value!,
                            ),
                            if (widget.role != 'DOCTOR') ...[
                              const SizedBox(height: 16),
                              _buildDropdown(
                                label: 'Blood Group*',
                                value: signUpController.bloodGroup.value,
                                items: [
                                  'A_POSITIVE',
                                  'A_NEGATIVE',
                                  'B_POSITIVE',
                                  'B_NEGATIVE',
                                  'AB_POSITIVE',
                                  'AB_NEGATIVE',
                                  'O_POSITIVE',
                                  'O_NEGATIVE',
                                ],
                                onChanged: (value) =>
                                    signUpController.bloodGroup.value = value!,
                              ),
                            ],
                            // Role-specific fields
                            if (widget.role == 'PATIENT') ...[
                              const SizedBox(height: 16),
                              Obx(() {
                                if (signUpController.isLoading.value) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (signUpController.userList.value.data ==
                                        null ||
                                    signUpController
                                        .userList.value.data!.isEmpty) {
                                  return Text(
                                    'No doctors available',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  );
                                }
                                // Auto-select first doctor if none selected
                                final doctorItems = signUpController.userList.value.data!
                                    .map((e) => '${e.firstName ?? ''} ${e.lastName ?? ''} (${e.specialization ?? 'General'})')
                                    .toList();
                                
                                if (signUpController.doctor.value.isEmpty && doctorItems.isNotEmpty) {
                                  final firstDoctor = signUpController.userList.value.data!.first;
                                  signUpController.doctor.value = firstDoctor.id ?? '';
                                }
                                
                                // Find current selected doctor display name
                                String? selectedDisplayName;
                                if (signUpController.doctor.value.isNotEmpty) {
                                  try {
                                    final selectedDoctor = signUpController.userList.value.data!
                                        .firstWhere((doctor) => doctor.id == signUpController.doctor.value);
                                    selectedDisplayName = '${selectedDoctor.firstName ?? ''} ${selectedDoctor.lastName ?? ''} (${selectedDoctor.specialization ?? 'General'})';
                                  } catch (e) {
                                    selectedDisplayName = null;
                                  }
                                }
                                
                                return _buildDropdown(
                                  label: 'Select Doctor*',
                                  value: selectedDisplayName,
                                  items: doctorItems,
                                  onChanged: (value) {
                                    // Find the selected doctor and store their ID
                                    final selectedDoctor = signUpController.userList.value.data!
                                        .firstWhere((doctor) => 
                                            '${doctor.firstName ?? ''} ${doctor.lastName ?? ''} (${doctor.specialization ?? 'General'})' == value);
                                    signUpController.doctor.value = selectedDoctor.id ?? '';
                                  },
                                );
                              }),
                            ],
                            if (widget.role == 'RELATIVE') ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Invitation Code*',
                                hint: 'Enter patient invitation code',
                                controller: signUpController.invitationCode,
                              ),
                              const SizedBox(height: 16),
                              Obx(() => _buildDropdown(
                                label: 'Relationship to Patient*',
                                value: signUpController.selectedRelationship.value.isEmpty 
                                    ? null 
                                    : signUpController.selectedRelationship.value,
                                items: const [
                                  'Father',
                                  'Mother',
                                  'Sibling', 
                                  'Spouse',
                                  'Child',
                                  'Other'
                                ],
                                onChanged: (value) {
                                  signUpController.selectedRelationship.value = value ?? '';
                                  signUpController.relationshipToPatient.text = value ?? '';
                                },
                              )),
                            ],
                            if (widget.role == 'DOCTOR') ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Specialization*',
                                hint: 'e.g., Psychiatrist, Neurologist, etc.',
                                controller: signUpController.specialization,
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Use controller's validation instead of manual checks
                                  try {
                                    await signUpController.createUser();
                                  } catch (e) {
                                    print('Error during signup: $e');
                                    Get.snackbar(
                                      'Error',
                                      'Failed to create account. Please try again.',
                                      backgroundColor:
                                          Colors.red.withValues(alpha: 0.1),
                                      colorText: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
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
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0850FD),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidatedTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required String errorText,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText.isNotEmpty ? Colors.red : Colors.white.withValues(alpha: 0.2),
                width: errorText.isNotEmpty ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText.isNotEmpty ? Colors.red : Colors.white.withValues(alpha: 0.2),
                width: errorText.isNotEmpty ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText.isNotEmpty ? Colors.red : const Color(0xFF0850FD),
                width: 2,
              ),
            ),
            errorText: errorText.isNotEmpty ? errorText : null,
            errorStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String errorText,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              onPressed: onVisibilityToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText.isNotEmpty ? Colors.red : Colors.white.withValues(alpha: 0.2),
                width: errorText.isNotEmpty ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText.isNotEmpty ? Colors.red : Colors.white.withValues(alpha: 0.2),
                width: errorText.isNotEmpty ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText.isNotEmpty ? Colors.red : const Color(0xFF0850FD),
                width: 2,
              ),
            ),
            errorText: errorText.isNotEmpty ? errorText : null,
            errorStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            dropdownColor: const Color(0xFF2A2A2A),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
            iconEnabledColor: Colors.white.withValues(alpha: 0.7),
            onChanged: onChanged,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
