import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import '../../theme/app_theme.dart';
import 'yogaScreen.dart';

class OfflineQuizPage extends StatefulWidget {
  const OfflineQuizPage({Key? key}) : super(key: key);

  @override
  State<OfflineQuizPage> createState() => _OfflineQuizPageState();
}

class _OfflineQuizPageState extends State<OfflineQuizPage> {
  String? selectedQuizType;
  int currentQuestionIndex = 0;
  int selectedOption = -1;
  int totalScore = 0;
  bool isQuizCompleted = false;

  // Enhanced HAM_D Questions
  final List<Map<String, dynamic>> hamdQuestions = [
    {
      'question': 'question_depressed_mood',
      'options': [
        {'text': 'option_absent', 'score': 0},
        {'text': 'option_mild', 'score': 1},
        {'text': 'option_moderate', 'score': 2},
        {'text': 'option_severe', 'score': 3},
        {'text': 'option_extreme', 'score': 4},
      ],
    },
    {
      'question': 'question_guilt',
      'options': [
        {'text': 'option_absent', 'score': 0},
        {'text': 'option_self_reproach', 'score': 1},
        {'text': 'option_guilt_ideas', 'score': 2},
        {'text': 'option_guilt_delusions', 'score': 3},
        {'text': 'option_guilt_hallucinations', 'score': 4},
      ],
    },
    {
      'question': 'question_suicide',
      'options': [
        {'text': 'option_absent', 'score': 0},
        {'text': 'option_life_not_worth', 'score': 1},
        {'text': 'option_wishes_dead', 'score': 2},
        {'text': 'option_suicidal_ideas', 'score': 3},
        {'text': 'option_suicide_attempts', 'score': 4},
      ],
    },
    {
      'question': 'question_insomnia_early',
      'options': [
        {'text': 'option_no_difficulty', 'score': 0},
        {'text': 'option_occasional_difficulty', 'score': 1},
        {'text': 'option_nightly_difficulty', 'score': 2},
      ],
    },
    {
      'question': 'question_insomnia_middle',
      'options': [
        {'text': 'option_no_difficulty', 'score': 0},
        {'text': 'option_restless', 'score': 1},
        {'text': 'option_waking_night', 'score': 2},
      ],
    },
    {
      'question': 'question_insomnia_late',
      'options': [
        {'text': 'option_no_difficulty', 'score': 0},
        {'text': 'option_waking_early', 'score': 1},
        {'text': 'option_cant_sleep', 'score': 2},
      ],
    },
    {
      'question': 'question_work_activities',
      'options': [
        {'text': 'option_no_difficulty', 'score': 0},
        {'text': 'option_incapacity', 'score': 1},
        {'text': 'option_loss_interest', 'score': 2},
        {'text': 'option_decreased_time', 'score': 3},
        {'text': 'option_stopped_working', 'score': 4},
      ],
    },
    {
      'question': 'question_retardation',
      'options': [
        {'text': 'option_normal_speech', 'score': 0},
        {'text': 'option_slight_retardation', 'score': 1},
        {'text': 'option_obvious_retardation', 'score': 2},
        {'text': 'option_interview_difficult', 'score': 3},
        {'text': 'option_complete_stupor', 'score': 4},
      ],
    },
    {
      'question': 'question_agitation',
      'options': [
        {'text': 'option_none', 'score': 0},
        {'text': 'option_fidgetiness', 'score': 1},
        {'text': 'option_playing', 'score': 2},
        {'text': 'option_cant_sit', 'score': 3},
        {'text': 'option_hand_wringing', 'score': 4},
      ],
    },
    {
      'question': 'question_anxiety_psychic',
      'options': [
        {'text': 'option_no_difficulty', 'score': 0},
        {'text': 'option_subjective_tension', 'score': 1},
        {'text': 'option_worrying', 'score': 2},
        {'text': 'option_apprehensive', 'score': 3},
        {'text': 'option_fears', 'score': 4},
      ],
    },
    {
      'question': 'question_anxiety_somatic',
      'options': [
        {'text': 'option_absent', 'score': 0},
        {'text': 'option_mild', 'score': 1},
        {'text': 'option_moderate', 'score': 2},
        {'text': 'option_severe', 'score': 3},
        {'text': 'option_incapacitating', 'score': 4},
      ],
    },
    {
      'question': 'question_somatic_gi',
      'options': [
        {'text': 'option_none', 'score': 0},
        {'text': 'option_loss_appetite', 'score': 1},
        {'text': 'option_difficulty_eating', 'score': 2},
        {'text': 'option_requires_persuasion', 'score': 3},
      ],
    },
    {
      'question': 'question_somatic_general',
      'options': [
        {'text': 'option_none', 'score': 0},
        {'text': 'option_heaviness', 'score': 1},
        {'text': 'option_aches', 'score': 2},
        {'text': 'option_loss_energy', 'score': 3},
      ],
    },
    {
      'question': 'question_genital',
      'options': [
        {'text': 'option_absent', 'score': 0},
        {'text': 'option_mild', 'score': 1},
        {'text': 'option_severe', 'score': 2},
      ],
    },
    {
      'question': 'question_hypochondriasis',
      'options': [
        {'text': 'option_none', 'score': 0},
        {'text': 'option_self_absorption', 'score': 1},
        {'text': 'option_health_preoccupation', 'score': 2},
        {'text': 'option_frequent_complaints', 'score': 3},
        {'text': 'option_hypochondriacal', 'score': 4},
      ],
    },
    {
      'question': 'question_weight',
      'options': [
        {'text': 'option_none', 'score': 0},
        {'text': 'option_probable_weight', 'score': 1},
        {'text': 'option_definite_weight', 'score': 2},
      ],
    },
    {
      'question': 'question_insight',
      'options': [
        {'text': 'option_acknowledges_depressed', 'score': 0},
        {'text': 'option_acknowledges_illness', 'score': 1},
        {'text': 'option_denies_illness', 'score': 2},
      ],
    },
  ];

  //  BDI Questions
  final List<Map<String, dynamic>> bdiQuestions = [
    {
      'question': 'question_sadness',
      'options': [
        {'text': 'option_not_sad', 'score': 0},
        {'text': 'option_sad_sometimes', 'score': 1},
        {'text': 'option_sad_often', 'score': 2},
        {'text': 'option_sad_always', 'score': 3},
      ],
    },
    {
      'question': 'question_pessimism',
      'options': [
        {'text': 'option_not_discouraged', 'score': 0},
        {'text': 'option_more_discouraged', 'score': 1},
        {'text': 'option_no_hope', 'score': 2},
        {'text': 'option_future_hopeless', 'score': 3},
      ],
    },
    {
      'question': 'question_past_failure',
      'options': [
        {'text': 'option_not_failure', 'score': 0},
        {'text': 'option_failed_more', 'score': 1},
        {'text': 'option_many_failures', 'score': 2},
        {'text': 'option_total_failure', 'score': 3},
      ],
    },
    {
      'question': 'question_loss_pleasure',
      'options': [
        {'text': 'option_same_pleasure', 'score': 0},
        {'text': 'option_less_pleasure', 'score': 1},
        {'text': 'option_little_pleasure', 'score': 2},
        {'text': 'option_no_pleasure', 'score': 3},
      ],
    },
    {
      'question': 'question_guilty_feelings',
      'options': [
        {'text': 'option_not_guilty', 'score': 0},
        {'text': 'option_guilty_sometimes', 'score': 1},
        {'text': 'option_guilty_often', 'score': 2},
        {'text': 'option_guilty_always', 'score': 3},
      ],
    },
    {
      'question': 'question_punishment_feelings',
      'options': [
        {'text': 'option_not_punished', 'score': 0},
        {'text': 'option_may_be_punished', 'score': 1},
        {'text': 'option_expect_punishment', 'score': 2},
        {'text': 'option_feel_punished', 'score': 3},
      ],
    },
    {
      'question': 'question_self_dislike',
      'options': [
        {'text': 'option_same_about_self', 'score': 0},
        {'text': 'option_less_confident', 'score': 1},
        {'text': 'option_disappointed_self', 'score': 2},
        {'text': 'option_dislike_self', 'score': 3},
      ],
    },
    {
      'question': 'question_self_critical',
      'options': [
        {'text': 'option_not_critical', 'score': 0},
        {'text': 'option_more_critical', 'score': 1},
        {'text': 'option_critical_faults', 'score': 2},
        {'text': 'option_blame_self', 'score': 3},
      ],
    },
    {
      'question': 'question_suicidal_thoughts',
      'options': [
        {'text': 'option_no_suicidal', 'score': 0},
        {'text': 'option_suicidal_thoughts', 'score': 1},
        {'text': 'option_want_suicide', 'score': 2},
        {'text': 'option_would_suicide', 'score': 3},
      ],
    },
    {
      'question': 'question_crying',
      'options': [
        {'text': 'option_cry_normal', 'score': 0},
        {'text': 'option_cry_more', 'score': 1},
        {'text': 'option_cry_always', 'score': 2},
        {'text': 'option_cant_cry', 'score': 3},
      ],
    },
    {
      'question': 'question_agitation',
      'options': [
        {'text': 'option_not_restless', 'score': 0},
        {'text': 'option_more_restless', 'score': 1},
        {'text': 'option_very_restless', 'score': 2},
        {'text': 'option_extremely_restless', 'score': 3},
      ],
    },
    {
      'question': 'question_loss_interest',
      'options': [
        {'text': 'option_same_interest', 'score': 0},
        {'text': 'option_less_interest', 'score': 1},
        {'text': 'option_lost_interest', 'score': 2},
        {'text': 'option_no_interest', 'score': 3},
      ],
    },
    {
      'question': 'question_indecisiveness',
      'options': [
        {'text': 'option_decide_normal', 'score': 0},
        {'text': 'option_put_off_decisions', 'score': 1},
        {'text': 'option_hard_decisions', 'score': 2},
        {'text': 'option_cant_decide', 'score': 3},
      ],
    },
    {
      'question': 'question_worthlessness',
      'options': [
        {'text': 'option_not_worthless', 'score': 0},
        {'text': 'option_less_worthwhile', 'score': 1},
        {'text': 'option_more_worthless', 'score': 2},
        {'text': 'option_completely_worthless', 'score': 3},
      ],
    },
    {
      'question': 'question_loss_energy',
      'options': [
        {'text': 'option_same_energy', 'score': 0},
        {'text': 'option_less_energy', 'score': 1},
        {'text': 'option_little_energy', 'score': 2},
        {'text': 'option_no_energy', 'score': 3},
      ],
    },
    {
      'question': 'question_sleep_changes',
      'options': [
        {'text': 'option_sleep_normal', 'score': 0},
        {'text': 'option_sleep_more', 'score': 1},
        {'text': 'option_sleep_less', 'score': 2},
        {'text': 'option_sleep_much_more', 'score': 3},
        {'text': 'option_sleep_much_less', 'score': 3},
      ],
    },
    {
      'question': 'question_irritability',
      'options': [
        {'text': 'option_not_irritable', 'score': 0},
        {'text': 'option_more_irritable', 'score': 1},
        {'text': 'option_very_irritable', 'score': 2},
        {'text': 'option_always_irritable', 'score': 3},
      ],
    },
    {
      'question': 'question_appetite_changes',
      'options': [
        {'text': 'option_appetite_normal', 'score': 0},
        {'text': 'option_appetite_less', 'score': 1},
        {'text': 'option_appetite_more', 'score': 1},
        {'text': 'option_appetite_much_less', 'score': 2},
        {'text': 'option_appetite_much_more', 'score': 2},
      ],
    },
    {
      'question': 'question_concentration',
      'options': [
        {'text': 'option_concentrate_normal', 'score': 0},
        {'text': 'option_concentrate_less', 'score': 1},
        {'text': 'option_hard_concentrate', 'score': 2},
        {'text': 'option_cant_concentrate', 'score': 3},
      ],
    },
    {
      'question': 'question_tiredness',
      'options': [
        {'text': 'option_not_tired', 'score': 0},
        {'text': 'option_more_tired', 'score': 1},
        {'text': 'option_very_tired', 'score': 2},
        {'text': 'option_extremely_tired', 'score': 3},
      ],
    },
  ];

  List<Map<String, dynamic>> get currentQuestions {
    return selectedQuizType == 'HAM_D' ? hamdQuestions : bdiQuestions;
  }

  int _getMaxPossibleScore() {
    int maxScore = 0;
    for (var question in currentQuestions) {
      int maxQuestionScore = 0;
      for (var option in question['options']) {
        if (option['score'] > maxQuestionScore) {
          maxQuestionScore = option['score'];
        }
      }
      maxScore += maxQuestionScore;
    }
    return maxScore;
  }

  void nextQuestion() {
    if (selectedOption != -1) {
      totalScore += (currentQuestions[currentQuestionIndex]['options']
          [selectedOption]['score'] as int);

      if (currentQuestionIndex < currentQuestions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          selectedOption = -1;
        });
      } else {
        setState(() {
          isQuizCompleted = true;
        });
      }
    }
  }

  String getResultMessage() {
    if (selectedQuizType == 'HAM_D') {
      if (totalScore < 8) return 'Normal';
      if (totalScore < 14) return 'Mild Depression';
      if (totalScore < 19) return 'Moderate Depression';
      return 'Severe Depression';
    } else {
      if (totalScore < 7) return 'Minimal Depression';
      if (totalScore < 13) return 'Mild Depression';
      if (totalScore < 20) return 'Moderate Depression';
      return 'Severe Depression';
    }
  }

  String getDetailedResult() {
    if (selectedQuizType == 'HAM_D') {
      if (totalScore < 8) {
        return 'Your mental health appears to be in good condition. Keep up your healthy habits!';
      } else if (totalScore < 14) {
        return 'Consider stress management techniques and regular physical activity.';
      } else if (totalScore < 19) {
        return 'Regular exercise and social support are important. Consider professional guidance.';
      } else {
        return 'Professional help is strongly recommended. Please consider reaching out to a mental health professional.';
      }
    } else {
      if (totalScore < 7) {
        return 'Your score indicates minimal depression. Continue maintaining your positive lifestyle habits.';
      } else if (totalScore < 13) {
        return 'Consider incorporating daily mindfulness practices and regular exercise.';
      } else if (totalScore < 20) {
        return 'Regular exercise, proper sleep, and social activities are recommended. Consider professional guidance.';
      } else {
        return 'Professional help is strongly recommended. Please consider reaching out to a mental health professional.';
      }
    }
  }

  List<String> getRecommendations() {
    List<String> recommendations = [];

    if (selectedQuizType == 'HAM_D') {
      if (totalScore < 8) {
        recommendations = [
          'Continue practicing good self-care habits',
          'Maintain regular exercise and healthy eating',
          'Keep a regular sleep schedule',
          'Stay connected with friends and family',
          'Practice stress management techniques'
        ];
      } else if (totalScore < 14) {
        recommendations = [
          'Consider talking to a mental health professional',
          'Practice regular exercise and mindfulness',
          'Maintain a healthy sleep schedule',
          'Stay connected with supportive people',
          'Consider keeping a mood journal'
        ];
      } else if (totalScore < 19) {
        recommendations = [
          'Seek professional help from a mental health provider',
          'Consider therapy or counseling',
          'Practice stress reduction techniques',
          'Maintain a regular routine',
          'Consider medication evaluation with a doctor'
        ];
      } else {
        recommendations = [
          'Seek immediate professional help',
          'Contact a mental health provider',
          'Consider emergency services if needed',
          'Stay connected with supportive people',
          'Follow professional treatment recommendations'
        ];
      }
    } else {
      if (totalScore < 7) {
        recommendations = [
          'Continue healthy lifestyle habits',
          'Practice regular self-care',
          'Maintain social connections',
          'Keep a balanced routine',
          'Practice stress management'
        ];
      } else if (totalScore < 13) {
        recommendations = [
          'Consider talking to someone about your feelings',
          'Practice regular exercise',
          'Maintain a healthy sleep schedule',
          'Try mindfulness or meditation',
          'Keep a mood journal'
        ];
      } else if (totalScore < 20) {
        recommendations = [
          'Consider professional counseling',
          'Practice stress reduction techniques',
          'Maintain regular exercise',
          'Keep a regular routine',
          'Stay connected with supportive people'
        ];
      } else {
        recommendations = [
          'Seek professional mental health support',
          'Consider therapy or counseling',
          'Practice regular self-care',
          'Follow treatment recommendations',
          'Stay connected with your support system'
        ];
      }
    }
    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    if (selectedQuizType == null) {
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'select_quiz_type'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'choose_assessment_type'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildQuizOption(
                    title: 'hamd_title'.tr,
                    description: 'hamd_description'.tr,
                    icon: Icons.medical_services_rounded,
                    isSelected: selectedQuizType == 'HAM_D',
                    onTap: () => setState(() => selectedQuizType = 'HAM_D'),
                  ),
                  const SizedBox(height: 20),
                  _buildQuizOption(
                    title: 'bdi_title'.tr,
                    description: 'bdi_description'.tr,
                    icon: Icons.psychology_rounded,
                    isSelected: selectedQuizType == 'BDI',
                    onTap: () => setState(() => selectedQuizType = 'BDI'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white),
                  onPressed: () => setState(() => selectedQuizType = null),
                ),
                const SizedBox(height: 20),
                StepProgressIndicator(
                  totalSteps: currentQuestions.length,
                  currentStep: currentQuestionIndex + 1,
                  size: 8,
                  padding: 0,
                  selectedColor: AppTheme.primaryColor,
                  unselectedColor: Colors.grey,
                  roundedEdges: const Radius.circular(10),
                ),
                const SizedBox(height: 30),
                if (!isQuizCompleted) ...[
                  Text(
                    'Question ${currentQuestionIndex + 1} of ${currentQuestions.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentQuestions[currentQuestionIndex]['question']
                        .toString()
                        .tr,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentQuestions[currentQuestionIndex]
                              ['options']
                          .length,
                      itemBuilder: (context, index) {
                        final option = currentQuestions[currentQuestionIndex]
                            ['options'][index];
                        final isSelected = selectedOption == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedOption = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.white.withValues(alpha: 0.1),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                              .withValues(alpha: 0.2)
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
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                                .withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.radio_button_checked_rounded,
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.white.withValues(alpha: 0.5),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        option['text'].toString().tr,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryColor,
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
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: selectedOption == -1 ? null : nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      currentQuestionIndex == currentQuestions.length - 1
                          ? 'finish'.tr
                          : 'next'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  _buildResultPage(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizOption({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  size: 24,
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
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
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
    );
  }

  Widget _buildResultPage() {
    return Flexible(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'quiz_completed'.tr,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'your_score'.trParams({
                        'score': '$totalScore',
                        'total': '${_getMaxPossibleScore()}'
                      }),
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      getResultMessage(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'detailed_assessment'.tr,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      getDetailedResult(),
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'recommended_practices'.tr,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'meditation'.tr,
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRecommendationCard(
                      'mindful_breathing'.tr,
                      'mindful_breathing_desc'.tr,
                      Icons.air_rounded,
                      Colors.blue,
                      () => Get.to(() => YogaScreen(
                          initialSection: 'meditation',
                          initialPractice: 'mindful_breathing')),
                    ),
                    const SizedBox(height: 10),
                    _buildRecommendationCard(
                      'body_scan'.tr,
                      'body_scan_desc'.tr,
                      Icons.self_improvement_rounded,
                      Colors.purple,
                      () => Get.to(() => YogaScreen(
                          initialSection: 'meditation',
                          initialPractice: 'body_scan')),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'music_therapy'.tr,
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRecommendationCard(
                      'nature_sounds'.tr,
                      'nature_sounds_desc'.tr,
                      Icons.nature_rounded,
                      Colors.green,
                      () => Get.to(() => YogaScreen(
                          initialSection: 'music',
                          initialPractice: 'nature_sounds')),
                    ),
                    const SizedBox(height: 10),
                    _buildRecommendationCard(
                      'meditation_music'.tr,
                      'meditation_music_desc'.tr,
                      Icons.self_improvement_rounded,
                      Colors.blue,
                      () => Get.to(() => YogaScreen(
                          initialSection: 'music',
                          initialPractice: 'meditation_music')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'general_recommendations'.tr,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...getRecommendations().map((recommendation) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  recommendation,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentQuestionIndex = 0;
                        selectedOption = -1;
                        totalScore = 0;
                        isQuizCompleted = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'take_quiz_again'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'return_home'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
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
    );
  }

  Widget _buildRecommendationCard(
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
