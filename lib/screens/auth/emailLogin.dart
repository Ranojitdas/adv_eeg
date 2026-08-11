import 'package:ADDvEEG/screens/patientScreens/patient_login.dart';
import 'package:ADDvEEG/screens/auth/signUpPage.dart';
import 'package:ADDvEEG/screens/auth/forgot_password_screen.dart';
import 'package:ADDvEEG/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';

import '../../controllers/auth/login_controller.dart';
// import 'package:get/get.dart';

// ignore: camel_case_types
class UsernameLogin extends StatefulWidget {
  const UsernameLogin({super.key});

  @override
  State<UsernameLogin> createState() => _UsernameLoginState();
}

class _UsernameLoginState extends State<UsernameLogin> {
  late LoginController loginController;
  final box = GetStorage();
  List<Map<String, String>> accounts = [];
  bool rememberMe = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    loginController = Get.put(LoginController());
    // Load saved accounts
    final saved = box.read('saved_accounts') ?? [];
    accounts =
        (saved as List).map((e) => Map<String, String>.from(e as Map)).toList();
    
    // Auto-populate fields if coming from signup
    _checkSignupCredentials();
  }
  
  void _checkSignupCredentials() {
    final signupEmail = box.read('signup_email');
    final signupPassword = box.read('signup_password');
    
    if (signupEmail != null && signupPassword != null) {
      setState(() {
        loginController.username.text = signupEmail;
        loginController.password.text = signupPassword;
      });
      
      // Clear the signup credentials after using them
      box.remove('signup_email');
      box.remove('signup_password');
      
      print('✅ [LOGIN] Auto-populated credentials from signup');
    }
  }

  void saveAccount(String email, String password) {
    accounts.removeWhere((acc) => acc['email'] == email);
    accounts.add({'email': email, 'password': password});
    box.write('saved_accounts', accounts);
    setState(() {});
  }

  void deleteAccount(Map<String, String> acc) {
    accounts.remove(acc);
    box.write('saved_accounts', accounts);
    setState(() {});
  }

  void _showAccountPickerDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF232323),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Choose an account',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (context, idx) {
                final acc = accounts[idx];
                return Card(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading:
                        const Icon(Icons.account_circle, color: Colors.white),
                    title: Text(acc['email'] ?? '',
                        style: GoogleFonts.poppins(color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        deleteAccount(acc);
                        Navigator.of(context).pop();
                      },
                    ),
                    onTap: () {
                      setState(() {
                        loginController.username.text = acc['email'] ?? '';
                        loginController.password.text = acc['password'] ?? '';
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always reload accounts from storage in build to ensure up-to-date
    final saved = box.read('saved_accounts') ?? [];
    accounts =
        (saved as List).map((e) => Map<String, String>.from(e as Map)).toList();
    print('Loaded accounts: $accounts');
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/bg2.jpg'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.7),
                BlendMode.darken,
              ),
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/pattern.png'),
                    repeat: ImageRepeat.repeat,
                    opacity: 0.1,
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Obx(
                  () => ModalProgressHUD(
                    inAsyncCall: loginController.isLoading.value,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios,
                                  color: Colors.white),
                              onPressed: () => Get.back(),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Welcome Back',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Login to continue your wellness journey',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Container(
                              decoration: AppTheme.glassDecoration,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: loginController.username,
                                    keyboardType: TextInputType.emailAddress,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                      suffixIcon: accounts.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                  Icons.account_circle,
                                                  color: Colors.white),
                                              onPressed:
                                                  _showAccountPickerDialog,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Password',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: loginController.password,
                                    obscureText: !_isPasswordVisible,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your password',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: rememberMe,
                                        onChanged: (val) {
                                          setState(() {
                                            rememberMe = val ?? false;
                                          });
                                        },
                                        activeColor: AppTheme.primaryColor,
                                      ),
                                      Text(
                                        'Remember Me',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await loginController.login(
                                            rememberMe: rememberMe);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Login',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Forgot Password Link
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        Get.to(() => const ForgotPasswordScreen());
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: GoogleFonts.poppins(
                                          color: Colors.lightBlue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'New User?',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.defaultDialog(
                                      title: 'Select your role',
                                      content: Column(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              Get.back();
                                              Get.to(() =>
                                                  SignUpPage(role: 'PATIENT'));
                                            },
                                            child: Text(
                                              'Patient',
                                              style: GoogleFonts.poppins(
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Get.back();
                                              Get.to(() =>
                                                  SignUpPage(role: 'DOCTOR'));
                                            },
                                            child: Text(
                                              'Doctor',
                                              style: GoogleFonts.poppins(
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Get.back();
                                              Get.to(() =>
                                                  SignUpPage(role: 'RELATIVE'));
                                            },
                                            child: Text(
                                              'Relative',
                                              style: GoogleFonts.poppins(
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign up',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
