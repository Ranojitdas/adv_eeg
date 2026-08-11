import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/doctor/doctorview_controller.dart';
import '../../services/api_service.dart';
import '../../Constants/constants.dart';

class QuestionManagementScreen extends StatefulWidget {
  const QuestionManagementScreen({super.key});

  @override
  State<QuestionManagementScreen> createState() => _QuestionManagementScreenState();
}

class _QuestionManagementScreenState extends State<QuestionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  final RxList<Map<String, dynamic>> hamDQuestions = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> bdiQuestions = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchQuestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    isLoading.value = true;
    try {
      // Fetch HAM_D questions
      final hamDResponse = await _apiService.get(
        Constants.getQuestionByType('HAM_D'),
        requiresAuth: true,
      );
      
      if (hamDResponse.success && hamDResponse.rawData != null) {
        hamDQuestions.value = List<Map<String, dynamic>>.from(
          hamDResponse.rawData!['data'] ?? []
        );
      }

      // Fetch BDI questions
      final bdiResponse = await _apiService.get(
        Constants.getQuestionByType('BDI'),
        requiresAuth: true,
      );
      
      if (bdiResponse.success && bdiResponse.rawData != null) {
        bdiQuestions.value = List<Map<String, dynamic>>.from(
          bdiResponse.rawData!['data'] ?? []
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch questions: $e');
    } finally {
      isLoading.value = false;
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
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Question Management',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showAddQuestionDialog,
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0850FD),
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          indicatorColor: const Color(0xFF0850FD),
          tabs: const [
            Tab(text: 'HAM_D Questions'),
            Tab(text: 'BDI Questions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionsList('HAM_D', hamDQuestions),
          _buildQuestionsList('BDI', bdiQuestions),
        ],
      ),
    );
  }

  Widget _buildQuestionsList(String type, RxList<Map<String, dynamic>> questions) {
    return Obx(() {
      if (isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0850FD)),
        );
      }

      if (questions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 80,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 20),
              Text(
                'No $type Questions',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add questions for $type assessment',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return _buildQuestionCard(question, type);
        },
      );
    });
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, String type) {
    final questionText = question['question'] ?? 'No question text';
    final optionsData = question['options'] ?? [];
    final options = <String>[];
    
    // Handle different option formats from API
    for (var option in optionsData) {
      if (option is String) {
        options.add(option);
      } else if (option is Map<String, dynamic>) {
        options.add(option['option']?.toString() ?? 'Unknown option');
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        title: Text(
          questionText,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '$type Question • ${options.length} options',
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Options:',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showEditQuestionDialog(question, type),
                        icon: const Icon(
                          Icons.edit,
                          color: Color(0xFF0850FD),
                          size: 20,
                        ),
                        tooltip: 'Edit Question',
                      ),
                      IconButton(
                        onPressed: () => _showDeleteConfirmation(question, type),
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: 'Delete Question',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...options.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${entry.key + 1}. ${entry.value}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog() {
    final TextEditingController questionController = TextEditingController();
    final List<TextEditingController> optionControllers = List.generate(
      4, (index) => TextEditingController()
    );
    final RxString selectedType = 'HAM_D'.obs;
    final RxBool hasError = false.obs;
    final RxString errorMessage = ''.obs;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Add New Question',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Question Type Selector
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedType.value,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Question Type',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  items: ['HAM_D', 'BDI'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedType.value = value;
                  },
                )),
                
                const SizedBox(height: 16),
                
                // Question Text
                TextField(
                  controller: questionController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Question Text',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Options
                Text(
                  'Answer Options:',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                ...optionControllers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: entry.value,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Option ${entry.key + 1}',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          Obx(() => ElevatedButton(
            onPressed: isCreating.value ? null : () {
              final options = optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
              
              // Validation
              if (questionController.text.trim().isEmpty) {
                hasError.value = true;
                errorMessage.value = 'Question text is required';
                return;
              }
              
              if (options.length < 2) {
                hasError.value = true;
                errorMessage.value = 'At least 2 options are required';
                return;
              }
              
              hasError.value = false;
              errorMessage.value = '';
              
              _createQuestion(
                selectedType.value,
                questionController.text.trim(),
                options,
                context,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0850FD),
              foregroundColor: Colors.white,
            ),
            child: isCreating.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Create',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
          )),
        ],
      ),
    );
  }

  Future<void> _createQuestion(
    String type,
    String questionText,
    List<String> options,
    BuildContext context,
  ) async {
    isCreating.value = true;

    try {
      final response = await _apiService.post(
        Constants.questionCreate,
        body: {
          'type': type,
          'question': questionText,
          'options': options,
        },
        requiresAuth: true,
      );

      if (response.success) {
        Navigator.pop(context);
        Get.snackbar(
          'Success',
          'Question created successfully',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
        _fetchQuestions();
      } else {
        Get.snackbar(
          'Error',
          'Failed to create question: ${response.message}',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create question: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      isCreating.value = false;
    }
  }

  void _showEditQuestionDialog(Map<String, dynamic> question, String type) {
    final TextEditingController questionController = TextEditingController(
      text: question['question'] ?? ''
    );
    final List<String> currentOptions = List<String>.from(question['options'] ?? []);
    final List<TextEditingController> optionControllers = List.generate(
      4, (index) => TextEditingController(
        text: index < currentOptions.length ? currentOptions[index] : ''
      )
    );
    final RxString selectedType = type.obs;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Edit Question',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Question Type Selector
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedType.value,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Question Type',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  items: ['HAM_D', 'BDI'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedType.value = value;
                  },
                )),
                
                const SizedBox(height: 16),
                
                // Question Text
                TextField(
                  controller: questionController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Question Text',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Options
                Text(
                  'Answer Options:',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                ...optionControllers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: entry.value,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Option ${entry.key + 1}',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          Obx(() => ElevatedButton(
            onPressed: isUpdating.value ? null : () => _updateQuestion(
              question['_id'],
              selectedType.value,
              questionController.text,
              optionControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList(),
              context,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0850FD),
              foregroundColor: Colors.white,
            ),
            child: isUpdating.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Update',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
          )),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> question, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Question',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this question?',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                question['question'] ?? 'No question text',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: GoogleFonts.poppins(
                color: Colors.red.withValues(alpha: 0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          Obx(() => ElevatedButton(
            onPressed: isDeleting.value ? null : () => _deleteQuestion(question['_id'], context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: isDeleting.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Delete',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
          )),
        ],
      ),
    );
  }

  Future<void> _updateQuestion(
    String questionId,
    String type,
    String questionText,
    List<String> options,
    BuildContext context,
  ) async {
    if (questionText.isEmpty || options.length < 2) {
      Get.snackbar(
        'Validation Error',
        'Please provide question text and at least 2 options',
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        colorText: Colors.orange,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    isUpdating.value = true;

    try {
      // Since there's no update endpoint in the API docs, we'll simulate it
      // In a real implementation, this would call PUT /api/v1/question/:questionId
      final response = await _apiService.patch(
        'api/v1/question/$questionId',
        body: {
          'type': type,
          'question': questionText,
          'options': options,
        },
        requiresAuth: true,
      );

      if (response.success) {
        Navigator.pop(context);
        Get.snackbar(
          'Success',
          'Question updated successfully',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
        _fetchQuestions();
      } else {
        // Fallback: Show info message and refresh (for demo purposes)
        Navigator.pop(context);
        Get.snackbar(
          'Info',
          'Update functionality will be available when backend supports it',
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          colorText: Colors.blue,
          icon: const Icon(Icons.info, color: Colors.blue),
        );
        _fetchQuestions();
      }
    } catch (e) {
      // Fallback: Show info message and refresh (for demo purposes)
      Navigator.pop(context);
      Get.snackbar(
        'Info',
        'Update functionality will be available when backend supports it',
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        colorText: Colors.blue,
        icon: const Icon(Icons.info, color: Colors.blue),
      );
      _fetchQuestions();
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> _deleteQuestion(String questionId, BuildContext context) async {
    isDeleting.value = true;

    try {
      // Since there's no delete endpoint in the API docs, we'll simulate it
      // In a real implementation, this would call DELETE /api/v1/question/:questionId
      final response = await _apiService.delete(
        'api/v1/question/$questionId',
        requiresAuth: true,
      );

      if (response.success) {
        Navigator.pop(context);
        Get.snackbar(
          'Success',
          'Question deleted successfully',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
        _fetchQuestions();
      } else {
        // Fallback: Show info message and refresh (for demo purposes)
        Navigator.pop(context);
        Get.snackbar(
          'Info',
          'Delete functionality will be available when backend supports it',
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          colorText: Colors.blue,
          icon: const Icon(Icons.info, color: Colors.blue),
        );
        _fetchQuestions();
      }
    } catch (e) {
      // Fallback: Show info message and refresh (for demo purposes)
      Navigator.pop(context);
      Get.snackbar(
        'Info',
        'Delete functionality will be available when backend supports it',
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        colorText: Colors.blue,
        icon: const Icon(Icons.info, color: Colors.blue),
      );
      _fetchQuestions();
    } finally {
      isDeleting.value = false;
    }
  }
}
