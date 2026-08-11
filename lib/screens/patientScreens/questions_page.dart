import 'package:ADDvEEG/screens/patientScreens/eegScreen.dart';
import 'package:ADDvEEG/screens/patientScreens/patient_login.dart';
import 'package:ADDvEEG/screens/patientScreens/yogaScreen.dart';
import 'package:ADDvEEG/controllers/patientSideControllers/bluetoothConnection_controller.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_seria_changed/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:toast/toast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../controllers/counter_controller.dart';
import '../../controllers/patientSideControllers/question_controller.dart';
import '../../controllers/patientSideControllers/quiz_controller.dart';
import '../../theme/app_theme.dart';

class QuestionsPage extends StatefulWidget {
  const QuestionsPage(
      {Key? key, required this.type, required this.role, required this.uid})
      : super(key: key);

  final type;
  final role;
  final uid;

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late final QuizController quizController;

  @override
  void initState() {
    super.initState();
    quizController = Get.put(QuizController(widget.type));

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    _ensureLocationPermission();
  }

  Future<void> _ensureLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationPermissionDialog(false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog(true);
        return;
      }

      // If we get here, we have permission
      await quizController.locationService.getCurrentLocation();
    } catch (e) {
      print('Error checking location permission: $e');
    }
  }

  void _showLocationServiceDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'Location Services Disabled',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          'Location services are required to continue with the quiz. Please enable location services in your device settings.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await Geolocator.openLocationSettings();
              // Wait a bit then retry
              await Future.delayed(Duration(seconds: 2));
              _ensureLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _ensureLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showLocationPermissionDialog(bool isPermanentlyDenied) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_disabled, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'Location Permission Required',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: Text(
          isPermanentlyDenied
              ? 'Location permission has been permanently denied. Please enable it manually in app settings to continue with the quiz.'
              : 'Location permission is required to continue with the quiz. Please grant permission when prompted.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          if (isPermanentlyDenied)
            ElevatedButton(
              onPressed: () async {
                Get.back();
                await openAppSettings();
                // Wait a bit then retry
                await Future.delayed(Duration(seconds: 2));
                _ensureLocationPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'App Settings',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _ensureLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    final QuestionController questionController =
        Get.put(QuestionController(widget.type));
    final CounterController counterController = Get.put(CounterController());
    var size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Obx(
      () => questionController.isLoading.value
          ? Scaffold(
              backgroundColor: const Color(0xFF1A1A1A),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0850FD)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Loading Assessment',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait while we load the ${widget.type} quiz for you',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Obx(
              () => ModalProgressHUD(
                inAsyncCall: quizController.isLoading.value,
                progressIndicator: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0850FD)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Processing',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Scaffold(
                  backgroundColor: const Color(0xFF1A1A1A),
                  appBar: AppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    title: Text(
                      '${widget.type} Assessment',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  extendBodyBehindAppBar: true,
                  body: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0850FD).withValues(alpha: 0.1),
                          const Color(0xFF1A1A1A),
                        ],
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SafeArea(
                          child: Column(
                            children: [
                              SizedBox(height: size.height * 0.009),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16.0 : 24.0,
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Obx(
                                            () => questionController.question.value.questions.isNotEmpty 
                                                ? StepProgressIndicator(
                                                    roundedEdges:
                                                        const Radius.circular(8),
                                                    totalSteps: questionController
                                                        .question
                                                        .value
                                                        .questions
                                                        .length,
                                                    currentStep: counterController
                                                            .current_step.value +
                                                        1,
                                                    selectedColor:
                                                        const Color(0xFF0850FD),
                                                    unselectedColor:
                                                        Colors.white.withValues(alpha: 0.2),
                                                    size: 8,
                                                  )
                                                : Container(
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(height: 8),
                                          Obx(
                                            () => Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  questionController.question.value.questions.isNotEmpty 
                                                      ? 'Question ${counterController.current_step.value + 1} of ${questionController.question.value.questions.length}'
                                                      : 'Loading questions...',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Obx(
                                () => questionController.question.value.questions.isNotEmpty 
                                    ? Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 16.0 : 24.0,
                                          vertical: 24,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.1),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    AutoSizeText(
                                                      '${questionController.question.value.questions[counterController.current_step.value].question?.question}',
                                                      textAlign: TextAlign.left,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: isSmallScreen ? 18 : 20,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    // Show description directly below question if available
                                                    if (questionController
                                                            .question
                                                            .value
                                                            .questions[counterController
                                                                .current_step.value]
                                                            .question
                                                            ?.description !=
                                                        null && questionController
                                                            .question
                                                            .value
                                                            .questions[counterController
                                                                .current_step.value]
                                                            .question!
                                                            .description!.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 12.0),
                                                        child: Text(
                                                          questionController
                                                              .question
                                                              .value
                                                              .questions[counterController
                                                                  .current_step.value]
                                                              .question!
                                                              .description!,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            color: Colors.white.withValues(alpha: 0.7),
                                                            fontStyle: FontStyle.italic,
                                                            height: 1.4,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 16.0 : 24.0,
                                          vertical: 24,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.1),
                                            ),
                                          ),
                                          child: Center(
                                            child: Column(
                                              children: [
                                                CircularProgressIndicator(
                                                  color: Color(0xFF0850FD),
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'Loading questions...',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white.withValues(alpha: 0.7),
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              Obx(
                                () => questionController.question.value.questions.isNotEmpty
                                    ? Expanded(
                                        child: ListView.builder(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallScreen ? 16.0 : 24.0,
                                          ),
                                          itemCount: questionController
                                              .question
                                              .value
                                              .questions[counterController
                                                  .current_step.value]
                                              .options
                                              ?.length ?? 0,
                                          itemBuilder:
                                              (BuildContext context, int index) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.only(bottom: 12.0),
                                              child: _buildOptionCard(
                                                context,
                                                questionController,
                                                counterController,
                                                index,
                                                isSmallScreen,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Expanded(
                                        child: Center(
                                          child: Text(
                                            'No questions available',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Obx(
                                        () => ElevatedButton(
                                          onPressed: counterController
                                                      .current_step.value >
                                                  0
                                              ? () {
                                                  counterController
                                                      .current_step.value--;
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.white.withValues(alpha: 0.1),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.arrow_back_rounded,
                                                  size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Previous',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Obx(
                                        () => ElevatedButton(
                                          onPressed: questionController.question.value.questions.isNotEmpty &&
                                              questionController.options.length > counterController.current_step.value &&
                                              (questionController.options.length > counterController.current_step.value ? 
                                                questionController.options[counterController.current_step.value] : -1) !=
                                                  -1
                                                  ? () {
                                                      if (counterController
                                                              .current_step
                                                              .value <
                                                          questionController
                                                                  .question
                                                                  .value
                                                                  .questions
                                                                  .length -
                                                              1) {
                                                        counterController
                                                            .current_step
                                                            .value++;
                                                      } else {
                                                        // Submit quiz using new backend workflow
                                                        quizController
                                                            .mergeScoreAndQuestion();
                                                        quizController
                                                            .submitQuizNewWorkflow()
                                                            .then((success) {
                                                          if (success) {
                                                            Get.back();
                                                            Get.bottomSheet(
                                                              Dismissible(
                                                                key: const Key(
                                                                    'value'),
                                                                onDismissed:
                                                                    (direction) {
                                                                  Get.back();
                                                                },
                                                                child: Material(
                                                                  color: Colors
                                                                      .blueGrey,
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                          .only(
                                                                    topLeft: Radius
                                                                        .circular(
                                                                            20),
                                                                    topRight: Radius
                                                                        .circular(
                                                                            20),
                                                                  ),
                                                                  child:
                                                                      Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      gradient:
                                                                          LinearGradient(
                                                                        colors: [
                                                                          const Color(0xFF0850FD)
                                                                              .withValues(alpha: 0.9),
                                                                          const Color(0xFF1A1A1A)
                                                                              .withValues(alpha: 0.95),
                                                                        ],
                                                                        begin: Alignment
                                                                            .topLeft,
                                                                        end: Alignment
                                                                            .bottomRight,
                                                                      ),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        topLeft:
                                                                            Radius.circular(20),
                                                                        topRight:
                                                                            Radius.circular(20),
                                                                      ),
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                          color: Colors
                                                                              .black
                                                                              .withValues(alpha: 0.2),
                                                                          blurRadius:
                                                                              20,
                                                                          offset: const Offset(
                                                                              0,
                                                                              8),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    child:
                                                                        SingleChildScrollView(
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                24.0,
                                                                            vertical:
                                                                                32),
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            const SizedBox(height: 16),
                                                                            // Home button in top-right corner
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                                              children: [
                                                                                Container(
                                                                                  decoration: BoxDecoration(
                                                                                    color: Colors.white.withValues(alpha: 0.1),
                                                                                    borderRadius: BorderRadius.circular(12),
                                                                                    border: Border.all(
                                                                                      color: Colors.white.withValues(alpha: 0.2),
                                                                                    ),
                                                                                  ),
                                                                                  child: IconButton(
                                                                                    onPressed: () {
                                                                                      Get.back(); // Close bottom sheet
                                                                                      Get.offAll(() => PatientLogin()); // Navigate to patient screen
                                                                                    },
                                                                                    icon: const Icon(
                                                                                      Icons.home_rounded,
                                                                                      color: Colors.white,
                                                                                      size: 24,
                                                                                    ),
                                                                                    tooltip: 'Return to Home',
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            // Animated Score Indicator with Mood Icon
                                                                            TweenAnimationBuilder(
                                                                              duration: const Duration(seconds: 1),
                                                                              tween: Tween<double>(begin: 0, end: quizController.score.value.toDouble()),
                                                                              builder: (context, double value, child) {
                                                                                Color moodColor = Colors.white;
                                                                                IconData moodIcon = Icons.sentiment_satisfied_alt_rounded;
                                                                                if (widget.type == 'BDI') {
                                                                                  if (value >= 1 && value <= 10) {
                                                                                    moodColor = Colors.green;
                                                                                    moodIcon = Icons.sentiment_very_satisfied_rounded;
                                                                                  } else if (value >= 11 && value <= 16) {
                                                                                    moodColor = const Color(0xFF8BC34A);
                                                                                    moodIcon = Icons.sentiment_satisfied_alt_rounded;
                                                                                  } else if (value >= 17 && value <= 20) {
                                                                                    moodColor = Colors.yellow;
                                                                                    moodIcon = Icons.sentiment_neutral_rounded;
                                                                                  } else if (value >= 21 && value <= 30) {
                                                                                    moodColor = Colors.orange;
                                                                                    moodIcon = Icons.sentiment_dissatisfied_rounded;
                                                                                  } else if (value >= 31 && value <= 40) {
                                                                                    moodColor = Colors.red;
                                                                                    moodIcon = Icons.sentiment_very_dissatisfied_rounded;
                                                                                  } else if (value > 40) {
                                                                                    moodColor = const Color(0xFFD32F2F);
                                                                                    moodIcon = Icons.sentiment_very_dissatisfied_rounded;
                                                                                  } else {
                                                                                    moodColor = Colors.green;
                                                                                    moodIcon = Icons.sentiment_very_satisfied_rounded;
                                                                                  }
                                                                                } else {
                                                                                  // HAM_D
                                                                                  if (value >= 0 && value <= 7) {
                                                                                    moodColor = const Color(0xFF4CAF50);
                                                                                    moodIcon = Icons.sentiment_very_satisfied_rounded;
                                                                                  } else if (value >= 8 && value <= 13) {
                                                                                    moodColor = const Color(0xFF8BC34A);
                                                                                    moodIcon = Icons.sentiment_satisfied_alt_rounded;
                                                                                  } else if (value >= 14 && value <= 18) {
                                                                                    moodColor = const Color(0xFFFFEB3B);
                                                                                    moodIcon = Icons.sentiment_neutral_rounded;
                                                                                  } else if (value >= 19 && value <= 22) {
                                                                                    moodColor = const Color(0xFFFF9800);
                                                                                    moodIcon = Icons.sentiment_dissatisfied_rounded;
                                                                                  } else if (value >= 23) {
                                                                                    moodColor = const Color(0xFFF44336);
                                                                                    moodIcon = Icons.sentiment_very_dissatisfied_rounded;
                                                                                  } else {
                                                                                    moodColor = const Color(0xFF4CAF50);
                                                                                    moodIcon = Icons.sentiment_very_satisfied_rounded;
                                                                                  }
                                                                                }
                                                                                return Card(
                                                                                  color: Colors.white.withValues(alpha: 0.05),
                                                                                  elevation: 0,
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(20),
                                                                                  ),
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                                                                                    child: Column(
                                                                                      children: [
                                                                                        Stack(
                                                                                          alignment: Alignment.center,
                                                                                          children: [
                                                                                            SizedBox(
                                                                                              width: 155,
                                                                                              height: 155,
                                                                                              child: CircularProgressIndicator(
                                                                                                value: value / 40.0, // assuming max score 40
                                                                                                strokeWidth: 10,
                                                                                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                                                                                valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                                                                                              ),
                                                                                            ),
                                                                                            Column(
                                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                                              children: [
                                                                                                Text(
                                                                                                  value.toStringAsFixed(1),
                                                                                                  style: GoogleFonts.poppins(
                                                                                                    fontSize: 36,
                                                                                                    color: Colors.white,
                                                                                                    fontWeight: FontWeight.bold,
                                                                                                  ),
                                                                                                ),
                                                                                                Text(
                                                                                                  'Your Score',
                                                                                                  style: GoogleFonts.poppins(
                                                                                                    fontSize: 16,
                                                                                                    color: Colors.white.withValues(alpha: 0.7),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              },
                                                                            ),
                                                                            const SizedBox(height: 14),
                                                                            Divider(
                                                                                color: Colors.white24,
                                                                                thickness: 1),
                                                                            // Score Interpretation Section
                                                                            Card(
                                                                              color: Colors.white.withValues(alpha: 0.07),
                                                                              elevation: 0,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(16),
                                                                              ),
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.all(20),
                                                                                child: Column(
                                                                                  children: [
                                                                                    Row(
                                                                                      children: [
                                                                                        Icon(Icons.psychology_alt_rounded, color: Colors.amber, size: 24),
                                                                                        const SizedBox(width: 8),
                                                                                        Text(
                                                                                          'Score Interpretation',
                                                                                          style: GoogleFonts.poppins(
                                                                                            fontSize: 20,
                                                                                            color: Colors.white,
                                                                                            fontWeight: FontWeight.w600,
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    const SizedBox(height: 16),
                                                                                    Obx(() {
                                                                                      final score = quizController.score.value;
                                                                                      String interpretation = '';
                                                                                      String recommendation = '';
                                                                                      Color moodColor = Colors.white;
                                                                                      if (widget.type == 'BDI') {
                                                                                        if (score < 7) {
                                                                                          interpretation = 'Minimal Depression';
                                                                                          recommendation = 'Your score indicates minimal depression. Continue maintaining your positive lifestyle habits.';
                                                                                          moodColor = Colors.green;
                                                                                        } else if (score < 13) {
                                                                                          interpretation = 'Mild Depression';
                                                                                          recommendation = 'Consider incorporating daily mindfulness practices and regular exercise.';
                                                                                          moodColor = Colors.blue;
                                                                                        } else if (score < 20) {
                                                                                          interpretation = 'Moderate Depression';
                                                                                          recommendation = 'Regular exercise, proper sleep, and social activities are recommended. Consider professional guidance.';
                                                                                          moodColor = Colors.orange;
                                                                                        } else {
                                                                                          interpretation = 'Severe Depression';
                                                                                          recommendation = 'Professional help is recommended. Consider consulting a mental health specialist.';
                                                                                          moodColor = Colors.red;
                                                                                        }
                                                                                      } else {
                                                                                        // HAMD
                                                                                        if (score < 8) {
                                                                                          interpretation = 'Normal';
                                                                                          recommendation = 'Your mental health appears to be in good condition. Keep up your healthy habits!';
                                                                                          moodColor = Colors.green;
                                                                                        } else if (score < 14) {
                                                                                          interpretation = 'Mild Depression';
                                                                                          recommendation = 'Consider stress management techniques and regular physical activity.';
                                                                                          moodColor = Colors.blue;
                                                                                        } else if (score < 19) {
                                                                                          interpretation = 'Moderate Depression';
                                                                                          recommendation = 'Regular exercise and social support are important. Consider professional guidance.';
                                                                                          moodColor = Colors.orange;
                                                                                        } else {
                                                                                          interpretation = 'Severe Depression';
                                                                                          recommendation = 'Professional help is recommended. Please consult a mental health specialist.';
                                                                                          moodColor = Colors.red;
                                                                                        }
                                                                                      }
                                                                                      return Column(
                                                                                        children: [
                                                                                          Container(
                                                                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                                            decoration: BoxDecoration(
                                                                                              color: moodColor.withValues(alpha: 0.1),
                                                                                              borderRadius: BorderRadius.circular(12),
                                                                                              border: Border.all(color: moodColor.withValues(alpha: 0.3)),
                                                                                            ),
                                                                                            child: Text(
                                                                                              interpretation,
                                                                                              style: GoogleFonts.poppins(
                                                                                                color: moodColor,
                                                                                                fontSize: 18,
                                                                                                fontWeight: FontWeight.w600,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16),
                                                                                          Text(
                                                                                            recommendation,
                                                                                            textAlign: TextAlign.center,
                                                                                            style: GoogleFonts.poppins(
                                                                                              fontSize: 16,
                                                                                              color: Colors.white.withValues(alpha: 0.7),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                                    }),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 24),
                                                                            Divider(
                                                                                color: Colors.white24,
                                                                                thickness: 1),
                                                                            // Recommended Practices Section
                                                                            Card(
                                                                              color: Colors.white.withValues(alpha: 0.07),
                                                                              elevation: 0,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(16),
                                                                              ),
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.all(20),
                                                                                child: Column(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Row(
                                                                                      children: [
                                                                                        Icon(Icons.self_improvement_rounded, color: Colors.purple, size: 24),
                                                                                        const SizedBox(width: 8),
                                                                                        Text(
                                                                                          'Recommended Practices',
                                                                                          style: GoogleFonts.poppins(
                                                                                            fontSize: 20,
                                                                                            color: Colors.white,
                                                                                            fontWeight: FontWeight.w600,
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    const SizedBox(height: 20),
                                                                                    Text(
                                                                                      'Meditation',
                                                                                      style: GoogleFonts.poppins(
                                                                                        color: const Color(0xFFF3BC5C),
                                                                                        fontSize: 18,
                                                                                        fontWeight: FontWeight.w500,
                                                                                      ),
                                                                                    ),
                                                                                    const SizedBox(height: 10),
                                                                                    _buildPracticeCard(
                                                                                      'Mindful Breathing',
                                                                                      'Focus on your breath to calm the mind',
                                                                                      Icons.air_rounded,
                                                                                      Colors.blue,
                                                                                      () => Get.to(() => YogaScreen(initialSection: 'meditation')),
                                                                                    ),
                                                                                    const SizedBox(height: 10),
                                                                                    _buildPracticeCard(
                                                                                      'Body Scan',
                                                                                      'Release tension through body awareness',
                                                                                      Icons.self_improvement_rounded,
                                                                                      Colors.purple,
                                                                                      () => Get.to(() => YogaScreen(initialSection: 'meditation')),
                                                                                    ),
                                                                                    const SizedBox(height: 20),
                                                                                    Text(
                                                                                      'Music Therapy',
                                                                                      style: GoogleFonts.poppins(
                                                                                        color: const Color(0xFFF3BC5C),
                                                                                        fontSize: 18,
                                                                                        fontWeight: FontWeight.w500,
                                                                                      ),
                                                                                    ),
                                                                                    const SizedBox(height: 10),
                                                                                    _buildPracticeCard(
                                                                                      'Calming Nature Sounds',
                                                                                      'Forest, Ocean, Rain',
                                                                                      Icons.nature_rounded,
                                                                                      Colors.green,
                                                                                      () => Get.to(() => YogaScreen(initialSection: 'music', initialPractice: 'nature_sounds')),
                                                                                    ),
                                                                                    const SizedBox(height: 10),
                                                                                    _buildPracticeCard(
                                                                                      'Meditation Music',
                                                                                      'Zen, Tibetan Bowls',
                                                                                      Icons.self_improvement_rounded,
                                                                                      Colors.blue,
                                                                                      () => Get.to(() => YogaScreen(initialSection: 'music', initialPractice: 'meditation_music')),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 24),
                                                                            Divider(
                                                                                color: Colors.white24,
                                                                                thickness: 1),
                                                                            // Daily Tips Section
                                                                            Card(
                                                                              color: Colors.white.withValues(alpha: 0.07),
                                                                              elevation: 0,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(16),
                                                                              ),
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.all(20),
                                                                                child: Column(
                                                                                  children: [
                                                                                    Row(
                                                                                      children: [
                                                                                        Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 24),
                                                                                        const SizedBox(width: 8),
                                                                                        Text(
                                                                                          'Daily Tips',
                                                                                          style: GoogleFonts.poppins(
                                                                                            fontSize: 20,
                                                                                            color: Colors.white,
                                                                                            fontWeight: FontWeight.w600,
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    const SizedBox(height: 16),
                                                                                    Obx(() {
                                                                                      final score = quizController.score.value;
                                                                                      List<String> tips = [];
                                                                                      if (score < 10) {
                                                                                        tips = [
                                                                                          'Practice 10 minutes of mindfulness meditation daily',
                                                                                          'Take regular breaks during work',
                                                                                          'Maintain a consistent sleep schedule',
                                                                                        ];
                                                                                      } else if (score < 20) {
                                                                                        tips = [
                                                                                          'Engage in 30 minutes of physical activity daily',
                                                                                          'Connect with friends or family regularly',
                                                                                          'Practice deep breathing exercises',
                                                                                          'Keep a gratitude journal',
                                                                                        ];
                                                                                      } else {
                                                                                        tips = [
                                                                                          'Consider professional counseling',
                                                                                          'Join a support group',
                                                                                          'Practice stress management techniques',
                                                                                          'Maintain a healthy diet and exercise routine',
                                                                                          'Set small, achievable daily goals',
                                                                                        ];
                                                                                      }
                                                                                      return Column(
                                                                                        children: tips
                                                                                            .map((tip) => Padding(
                                                                                                  padding: const EdgeInsets.only(bottom: 12),
                                                                                                  child: Row(
                                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                    children: [
                                                                                                      const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                                                                                                      const SizedBox(width: 8),
                                                                                                      Expanded(
                                                                                                        child: Text(
                                                                                                          tip,
                                                                                                          style: GoogleFonts.poppins(
                                                                                                            fontSize: 14,
                                                                                                            color: Colors.white.withValues(alpha: 0.8),
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ],
                                                                                                  ),
                                                                                                ))
                                                                                            .toList(),
                                                                                      );
                                                                                    }),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 24),
                                                                            // Score Image with Animation
                                                                            const SizedBox(height: 32),
                                                                            // Action Buttons
                                                                            Row(
                                                                              children: [
                                                                                Expanded(
                                                                                  child: ElevatedButton.icon(
                                                                                    onPressed: () async {
                                                                                      Get.back();
                                                                                      if (!GetPlatform.isAndroid) {
                                                                                        Get.snackbar(
                                                                                          'Alert',
                                                                                          'This feature is not available for your Platform',
                                                                                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                                                                                          colorText: Colors.red,
                                                                                        );
                                                                                        return;
                                                                                      }
                                                                                      
                                                                                      // Check Bluetooth permissions before proceeding
                                                                                      final bluetoothController = Get.find<BluetoothController>();
                                                                                      if (!bluetoothController.isReadyForEEG) {
                                                                                        Get.snackbar(
                                                                                          'Permissions Required',
                                                                                          'Please grant Bluetooth and Location permissions to use EEG functionality',
                                                                                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                                                                                          colorText: Colors.orange,
                                                                                          duration: Duration(seconds: 4),
                                                                                        );
                                                                                        await bluetoothController.checkAndRequestBluetoothPermissions();
                                                                                        return;
                                                                                      }
                                                                                      if (await FlutterBluetoothSerial.instance.state == BluetoothState.STATE_OFF) {
                                                                                        try {
                                                                                          await FlutterBluetoothSerial.instance.requestEnable();
                                                                                        } catch (e) {
                                                                                          print('Bluetooth enable error: $e');
                                                                                          Get.snackbar(
                                                                                            'Alert',
                                                                                            'Please enable Bluetooth manually in settings',
                                                                                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                                                                                            colorText: Colors.red,
                                                                                          );
                                                                                          return;
                                                                                        }
                                                                                        if (await FlutterBluetoothSerial.instance.state == BluetoothState.STATE_OFF) {
                                                                                          Get.snackbar(
                                                                                            'Alert',
                                                                                            'Please turn on bluetooth',
                                                                                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                                                                                            colorText: Colors.red,
                                                                                          );
                                                                                          return;
                                                                                        }
                                                                                      }
                                                                                      Get.to(() => EegScreen());
                                                                                    },
                                                                                    icon: const Icon(Icons.psychology_alt_rounded, size: 22),
                                                                                    label: Text(
                                                                                      'Take EEG Test',
                                                                                      style: GoogleFonts.poppins(
                                                                                        fontSize: 15,
                                                                                        fontWeight: FontWeight.w500,
                                                                                      ),
                                                                                    ),
                                                                                    style: ElevatedButton.styleFrom(
                                                                                      backgroundColor: const Color(0xFF0850FD),
                                                                                      foregroundColor: Colors.white,
                                                                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                                                                      shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.circular(12),
                                                                                      ),
                                                                                      elevation: 4,
                                                                                      shadowColor: const Color(0xFF0850FD).withValues(alpha: 0.3),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(width: 16),
                                                                                Expanded(
                                                                                  child: ElevatedButton.icon(
                                                                                    onPressed: () {
                                                                                      Get.back();
                                                                                      Get.to(
                                                                                        () => YogaScreen(),
                                                                                        transition: Transition.rightToLeft,
                                                                                        duration: const Duration(milliseconds: 300),
                                                                                      );
                                                                                    },
                                                                                    icon: const Icon(Icons.self_improvement_rounded, size: 22),
                                                                                    label: Text(
                                                                                      'Try Yoga',
                                                                                      style: GoogleFonts.poppins(
                                                                                        fontSize: 15,
                                                                                        fontWeight: FontWeight.w500,
                                                                                      ),
                                                                                    ),
                                                                                    style: ElevatedButton.styleFrom(
                                                                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                                                                      foregroundColor: Colors.white,
                                                                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                                                                      shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.circular(12),
                                                                                      ),
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
                                                              isDismissible:
                                                                  false,
                                                              isScrollControlled:
                                                                  true,
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                            );
                                                          }
                                                        });
                                                      }
                                                    }
                                                  : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF0850FD),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 4,
                                            shadowColor: const Color(0xFF0850FD)
                                                .withValues(alpha: 0.3),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                counterController.current_step
                                                            .value <
                                                        questionController
                                                                .question
                                                                .value
                                                                .questions
                                                                .length -
                                                            1
                                                    ? 'Next'
                                                    : 'Submit',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    QuestionController questionController,
    CounterController counterController,
    int index,
    bool isSmallScreen,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final stepIndex = counterController.current_step.value;
          print('📝 [UI] Attempting to select option $index for question $stepIndex');
          print('📝 [UI] Current options array length: ${questionController.options.length}');
          print('📝 [UI] Current options array: ${questionController.options}');
          
          // Ensure the options array is large enough
          if (stepIndex >= questionController.options.length) {
            print('📝 [UI] ⚠️ Expanding options array from ${questionController.options.length} to ${stepIndex + 1}');
            questionController.options.value = List.filled(stepIndex + 1, -1);
          }
          
          questionController.options[stepIndex] = index;
          print('📝 [UI] ✅ Selected option $index for question $stepIndex');
          print('📝 [UI] Updated options array: ${questionController.options}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Obx(
          () => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: (questionController.options.length > counterController.current_step.value &&
                                questionController.options[counterController.current_step.value] == index)
                  ? const Color(0xFF0850FD).withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (questionController.options.length > counterController.current_step.value &&
                                questionController.options[counterController.current_step.value] == index)
                    ? const Color(0xFF0850FD)
                    : Colors.white.withValues(alpha: 0.1),
                width: (questionController.options.length > counterController.current_step.value &&
                                questionController.options[counterController.current_step.value] == index)
                    ? 2
                    : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (questionController.options.length > counterController.current_step.value &&
                                questionController.options[counterController.current_step.value] == index)
                      ? const Color(0xFF0850FD).withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (questionController.options.length > counterController.current_step.value &&
                                questionController.options[counterController.current_step.value] == index)
                        ? const Color(0xFF0850FD).withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.radio_button_checked_rounded,
                    color: (questionController.options.length > counterController.current_step.value &&
                                questionController.options[counterController.current_step.value] == index)
                        ? const Color(0xFF0850FD)
                        : Colors.white.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${questionController.question.value.questions[counterController.current_step.value].options?[index].option}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: (questionController.options.length > counterController.current_step.value &&
                                  questionController.options[counterController.current_step.value] == index)
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if ((questionController.options.length > counterController.current_step.value &&
                                questionController.options[counterController.current_step.value] == index))
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0850FD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDescriptionDialog(String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF0850FD),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Question Details',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              description,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0850FD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Got it',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
