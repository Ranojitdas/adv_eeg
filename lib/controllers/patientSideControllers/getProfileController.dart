import 'dart:convert';

import 'package:ADDvEEG/models/quiz/new_quiz_models.dart';
import '../../models/profile_model.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../Constants/constants.dart';
import '../../models/brainScoreModel.dart';
import '../../services/api_service.dart';
import '../data_context_controller.dart';

class GetProflieController extends GetxController {
  final DataContextController _dataContext = Get.put(DataContextController());
  
  @override
  void onInit() async {
    await refreshData();
    super.onInit();
  }
  
  /// Refresh all data using current context (patient or relative view)
  Future<void> refreshData() async {
    final userId = _dataContext.getDataUserId();
    if (userId.isNotEmpty) {
      print('🔄 [PROFILE] Refreshing data for user: $userId (Context: ${_dataContext.getContextDisplayName()})');
      await fetchProfile(userId);
      await fetchBrainScore(userId);
      await fetchQuizHistory();
    } else {
      print('❌ [PROFILE] No user ID available for data fetching');
    }
  }

  var profile = Profile().obs;
  var isLoading = false.obs;
  var quizHistory = <Map<String, dynamic>>[].obs;

  /// Get user's full name from login details or profile
  /// This ensures we always show a proper name instead of "Unknown User"
  String get userFullName {
    // First try to get name from login details (most reliable)
    final loginDetails = GetStorage().read('loginDetails');
    if (loginDetails != null && loginDetails['user'] != null) {
      final user = loginDetails['user'];
      final firstName = user['firstName']?.toString().trim() ?? '';
      final lastName = user['lastName']?.toString().trim() ?? '';
      
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
      
      // Fallback to name field if firstName/lastName not available
      final name = user['name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    
    // Fallback to profile data if login details don't have name
    if (profile.value.firstName != null && profile.value.firstName!.isNotEmpty ||
        profile.value.lastName != null && profile.value.lastName!.isNotEmpty) {
      return profile.value.fullName;
    }
    
    // Last resort fallback
    return 'Patient';
  }

  /// Get user's invitation code from login details or profile
  String? get userInvitationCode {
    // First try to get invitation code from login details
    final loginDetails = GetStorage().read('loginDetails');
    if (loginDetails != null && loginDetails['user'] != null) {
      final invitationCode = loginDetails['user']['invitationCode']?.toString();
      if (invitationCode != null && invitationCode.isNotEmpty) {
        return invitationCode;
      }
    }
    
    // Fallback to profile data
    return profile.value.invitationCode;
  }

  fetchProfile(String? profileId) async {
    // Use data context to determine which user's profile to fetch
    final userId = profileId ?? _dataContext.getDataUserId();
    print('👤 [PROFILE] Fetching profile for ID: $userId (Context: ${_dataContext.getContextDisplayName()})');
    isLoading.value = true;
    try {
      final response = await apiService.get(
        Constants.getUserById(userId),
        requiresAuth: true,
      );

      if (response.success) {
        print('👤 [PROFILE] ✅ Profile fetched successfully!');
        profile.value = profileFromJson(jsonEncode(response.rawData));
      } else {
        print('👤 [PROFILE] ❌ Failed to fetch profile: ${response.message}');
      }
    } catch (err) {
      print('❌ [PROFILE] Error fetching profile: $err');
    } finally {
      isLoading.value = false;
    }
  }

  var quiz = QuizHistoryResponse(success: false, statusCode: 0, message: '', data: []).obs;

  fetchQuiz(String? uid) async {
    quiz = QuizHistoryResponse(success: false, statusCode: 0, message: '', data: []).obs;
    try {
      isLoading(true);
      // Use data context to determine which user's quiz data to fetch
      final userId = uid ?? _dataContext.getDataUserId();
      if (userId.isEmpty) {
        print('❌ [QUIZ] User ID not found');
        return;
      }
      print('📝 [QUIZ] Fetching quiz history for user: $userId (Context: ${_dataContext.getContextDisplayName()})');

      // Using the correct endpoint for logged-in user's quizzes
      print('📊 [QUIZ_HISTORY] Using my-all-quizzes endpoint');
      final response = await apiService.get(
        Constants.quizMyAllQuizzes,
        requiresAuth: true,
      );
      
      print('📊 [QUIZ_HISTORY] Response status: ${response.statusCode}');
      print('📊 [QUIZ_HISTORY] Response success: ${response.success}');
      print('📊 [QUIZ_HISTORY] Response data type: ${response.rawData.runtimeType}');
      print('📊 [QUIZ_HISTORY] Raw response: ${response.rawData}');

      if (response.success && response.rawData != null) {
        final data = response.rawData!['data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          print('📊 [QUIZ_HISTORY] Processing ${data.length} quiz records from API');
          
          List<Map<String, dynamic>> processedQuizzes = [];
          for (var quiz in data) {
            // Calculate score from responses
            final responses = quiz['responses'] as List<dynamic>? ?? [];
            int totalScore = 0;
            for (var response in responses) {
              totalScore += (response['selectedOptionId'] as int? ?? 0);
            }
            
            final processedQuiz = {
              '_id': quiz['_id'] ?? '',
              'questionnaireType': quiz['questionnaireType'] ?? '',
              'score': totalScore,
              'status': 'completed',
              'createdAt': DateTime.now().toIso8601String(),
              'responses': responses,
            };
            processedQuizzes.add(processedQuiz);
          }
          
          print('📊 [QUIZ_HISTORY] ✅ Successfully processed ${processedQuizzes.length} quizzes from API');
          quizData(processedQuizzes);
        } else {
          print('📊 [QUIZ_HISTORY] No quiz data found in API response');
          quizData([]);
        }
      } else {
        print('📊 [QUIZ_HISTORY] API call failed, using empty quiz list');
        quizData([]);
      }
    } catch (err) {
      print('❌ [QUIZ] Error: $err');
      quiz.value = QuizHistoryResponse(success: false, statusCode: 0, message: 'Error: $err', data: []);
    } finally {
      isLoading(false);
    }
  }

  void quizData(List<Map<String, dynamic>> quizzes) {
    List<QuizHistoryItem> quizHistoryItems = [];
    for (var quizItem in quizzes) {
      final responses = (quizItem['responses'] as List<dynamic>).map((response) {
        return QuizResponse(
          questionId: response['question']?.toString() ?? '',
          selectedOption: response['selectedOptionId'] ?? 0,
        );
      }).toList();
      
      final quizHistoryItem = QuizHistoryItem(
        id: quizItem['_id'] as String,
        questionnaireType: quizItem['questionnaireType'] as String,
        score: quizItem['score'] as int,
        responses: responses,
      );
      quizHistoryItems.add(quizHistoryItem);
    }
    
    quiz.value = QuizHistoryResponse(
      success: true, 
      statusCode: 200, 
      message: 'Success', 
      data: quizHistoryItems
    );
    
    print('📊 [QUIZ_HISTORY] ✅ Successfully processed ${quizHistoryItems.length} quiz history items');
  }

  var brainScores = <BrainScoreModel>[].obs;

  fetchBrainScore(String? uid) async {
    try {
      // Use data context to determine which user's brain scores to fetch
      final userId = uid ?? _dataContext.getDataUserId();
      if (userId.isEmpty) {
        print('❌ [BRAIN] User ID not found');
        return;
      }
      print('🧠 [BRAIN] Fetching brain scores for user: $userId (Context: ${_dataContext.getContextDisplayName()})');

      // Using new API endpoint for brain signal scores
      final response = await apiService.get(
        Constants.getBrainSignalScores(userId),
        requiresAuth: true,
      );

      if (response.success) {
        print('🧠 [BRAIN] ✅ Brain scores fetched successfully!');
        
        // Parse brain signal scores from new API response structure
        if (response.rawData != null && response.rawData!['data'] != null) {
          var scoresData = response.rawData!['data']['scores'] as List<dynamic>? ?? [];
          print('🧠 [BRAIN] Scores data: $scoresData');
          
          List<BrainScoreModel> parsedScores = [];
          for (var scoreData in scoresData) {
            try {
              parsedScores.add(BrainScoreModel.fromJson(scoreData));
            } catch (e) {
              print('🧠 [BRAIN] Error parsing score data: $e');
            }
          }
          
          brainScores.value = parsedScores;
          print('🧠 [BRAIN] Processed ${parsedScores.length} brain signal scores');
        } else {
          print('🧠 [BRAIN] ⚠️ No scores data found or invalid format');
          brainScores.value = [];
        }
      } else {
        print('🧠 [BRAIN] ❌ Failed to fetch brain scores: ${response.message}');
        brainScores.value = [];
      }
    } catch (err) {
      Get.snackbar('Error', 'Something went wrong');
      print('❌ [BRAIN] Error: $err');
    } finally {
      isLoading(false);
    }
  }

  var assignedQuizzes = <Map<String, dynamic>>[].obs;

  fetchAssignedQuizzes() async {
    try {
      isLoading.value = true;
      print('📋 [ASSIGNED_QUIZ] 🚀 Starting to fetch assigned quizzes...');
      print('📋 [ASSIGNED_QUIZ] 🔗 Endpoint: ${Constants.quizMyAssignedQuiz}');
      
      // Check authentication
      final loginDetails = GetStorage().read('loginDetails');
      print('📋 [ASSIGNED_QUIZ] 🔐 Auth check - Login details exist: ${loginDetails != null}');
      if (loginDetails != null) {
        print('📋 [ASSIGNED_QUIZ] 👤 User ID: ${loginDetails['user']?['_id'] ?? loginDetails['user']?['uid']}');
      }

      // Try my-all-quizzes endpoint instead due to API issue
      print('📋 [ASSIGNED_QUIZ] 🔄 Trying my-all-quizzes endpoint as fallback...');
      final response = await apiService.get(
        Constants.quizMyAllQuizzes,
        requiresAuth: true,
      );

      print('📋 [ASSIGNED_QUIZ] 📡 API Response received');
      print('📋 [ASSIGNED_QUIZ] ✅ Status Code: ${response.statusCode}');
      print('📋 [ASSIGNED_QUIZ] ✅ Success: ${response.success}');
      print('📋 [ASSIGNED_QUIZ] 📄 Message: ${response.message}');
      print('📋 [ASSIGNED_QUIZ] 🗂️ Raw Data Type: ${response.rawData?.runtimeType}');
      print('📋 [ASSIGNED_QUIZ] 📋 Full Raw Response: ${response.rawData}');

      if (response.success && response.rawData != null) {
        print('📋 [ASSIGNED_QUIZ] ✅ Response successful, parsing data...');
        
        // Check if response has 'data' array or 'quiz' object or direct array
        dynamic dataSource;
        print('📋 [ASSIGNED_QUIZ] 🔍 Response structure analysis:');
        print('📋 [ASSIGNED_QUIZ] 🔍 Contains "data" key: ${response.rawData!.containsKey('data')}');
        print('📋 [ASSIGNED_QUIZ] 🔍 Contains "quiz" key: ${response.rawData!.containsKey('quiz')}');
        print('📋 [ASSIGNED_QUIZ] 🔍 Response keys: ${response.rawData!.keys.toList()}');
        
        if (response.rawData!.containsKey('data') && response.rawData!['data'] is List) {
          // my-all-quizzes returns data array - filter for assigned quizzes only
          List<dynamic> allQuizzes = response.rawData!['data'] as List<dynamic>;
          print('📋 [ASSIGNED_QUIZ] 📊 Found data array with ${allQuizzes.length} total quizzes');
          
          // Filter for assigned quizzes (isSelfInitiated: false)
          dataSource = allQuizzes.where((quiz) {
            bool isAssigned = quiz['isSelfInitiated'] == false;
            print('📋 [ASSIGNED_QUIZ] 🔍 Quiz ${quiz['_id']}: isSelfInitiated=${quiz['isSelfInitiated']}, isAssigned=$isAssigned');
            return isAssigned;
          }).toList();
          
          print('📋 [ASSIGNED_QUIZ] ✅ Filtered to ${dataSource.length} assigned quizzes');
        } else {
          print('📋 [ASSIGNED_QUIZ] ❌ Unexpected response structure');
          assignedQuizzes.value = [];
          return;
        }

        List<Map<String, dynamic>> processedQuizzes = [];
        
        for (int i = 0; i < dataSource.length; i++) {
          var quiz = dataSource[i];
          print('📋 [ASSIGNED_QUIZ] Processing quiz $i: ${quiz}');
          
          // Handle assignedBy field - can be string ID or object with name
          String assignedByName = 'Unknown Doctor';
          if (quiz['assignedBy'] != null) {
            if (quiz['assignedBy'] is String) {
              // If it's just an ID string, show generic "Doctor"
              assignedByName = 'Doctor';
            } else if (quiz['assignedBy'] is Map && quiz['assignedBy']['name'] != null) {
              // If it's an object with name, use the actual name
              assignedByName = quiz['assignedBy']['name'];
            }
          }
          
          final processedQuiz = {
            'id': quiz['_id'] ?? '',
            'questionnaireType': quiz['questionnaireType'] ?? '',
            'assignedBy': assignedByName,
            'assignedAt': quiz['assignedAt'] ?? quiz['createdAt'] ?? DateTime.now().toIso8601String(),
            'status': quiz['status'] ?? 'assigned',
            'dueDate': quiz['dueDate'],
          };
          
          processedQuizzes.add(processedQuiz);
          print('📋 [ASSIGNED_QUIZ] Processed quiz: $processedQuiz');
        }

        assignedQuizzes.value = processedQuizzes;
        print('📋 [ASSIGNED_QUIZ] ✅ Successfully loaded ${processedQuizzes.length} assigned quizzes');
      } else {
        print('📋 [ASSIGNED_QUIZ] ❌ Failed to fetch assigned quizzes: ${response.message}');
        print('📋 [ASSIGNED_QUIZ] ❌ Status code: ${response.statusCode}');
        assignedQuizzes.value = [];
      }
    } catch (err) {
      print('❌ [ASSIGNED_QUIZ] Exception caught: $err');
      print('❌ [ASSIGNED_QUIZ] Exception type: ${err.runtimeType}');
      assignedQuizzes.value = [];
    } finally {
      print('📋 [ASSIGNED_QUIZ] 🏁 Finished fetching, setting isLoading to false');
      print('📋 [ASSIGNED_QUIZ] 📈 Final assignedQuizzes count: ${assignedQuizzes.length}');
      isLoading.value = false;
    }
  }

  // Fetch quiz history with location data
  fetchQuizHistory() async {
    try {
      // Use different endpoint based on context (relative viewing patient vs own data)
      String endpoint;
      final userId = _dataContext.getDataUserId();
      
      if (_dataContext.isRelativeView) {
        // Relative viewing patient data - use patient-specific endpoint
        endpoint = Constants.getQuizHistory(userId);
      } else {
        // User viewing own data - use my-all-quizzes endpoint
        endpoint = Constants.quizMyAllQuizzes;
      }
      
      final response = await apiService.get(
        endpoint,
        requiresAuth: true,
      );


      if (response.success && response.rawData != null) {
        // Handle different response structures
        dynamic dataSource;
        if (response.rawData!.containsKey('data') && response.rawData!['data'] is List) {
          dataSource = response.rawData!['data'] as List<dynamic>;
        } else if (response.rawData is List) {
          dataSource = response.rawData as List<dynamic>;
        } else {
          quizHistory.value = [];
          return;
        }

        List<Map<String, dynamic>> processedHistory = [];
        
        for (var quiz in dataSource) {
          final responses = quiz['responses'] as List<dynamic>? ?? [];
          final status = quiz['status'] ?? 'unknown';
          final quizType = quiz['questionnaireType'] ?? 'unknown';
          final isSelfInitiated = quiz['isSelfInitiated'] ?? false;
          
          
          // More restrictive filtering - only include quizzes that are actual attempts
          bool shouldInclude = false;
          
          // Include if quiz has been completed (has responses and completion data)
          if (responses.isNotEmpty && (status == 'completed' || quiz['completedAt'] != null)) {
            shouldInclude = true;
          }
          // Include if quiz is in progress but has some responses
          else if (responses.isNotEmpty && status == 'in_progress') {
            shouldInclude = true;
          }
          // Exclude everything else (assigned but not started, pending, etc.)
          else {
            shouldInclude = false;
          }
          
          if (shouldInclude) {
            // Calculate score from responses if not provided
            int calculatedScore = quiz['score'] ?? 0;
            if (calculatedScore == 0) {
              final responses = quiz['responses'] as List<dynamic>? ?? [];
              for (var response in responses) {
                calculatedScore += (response['selectedOptionId'] as int? ?? 0);
              }
            }
            
            final processedQuiz = {
              'id': quiz['_id'] ?? '',
              'questionnaireType': quiz['questionnaireType'] ?? '',
              'score': calculatedScore,
              'status': quiz['status'] ?? 'completed',
              'createdAt': quiz['createdAt'] ?? DateTime.now().toIso8601String(),
              'completedAt': quiz['completedAt'] ?? quiz['updatedAt'] ?? quiz['createdAt'],
              'isSelfInitiated': quiz['isSelfInitiated'] ?? true,
              'assignedBy': quiz['assignedBy'],
              'location': quiz['location'], // Include location data if available
              'responses': quiz['responses'], // Include responses for debugging
            };
            
            processedHistory.add(processedQuiz);
          }
        }

        // Sort by completion date (most recent first)
        processedHistory.sort((a, b) {
          DateTime dateA = DateTime.parse(a['completedAt'] ?? a['createdAt']);
          DateTime dateB = DateTime.parse(b['completedAt'] ?? b['createdAt']);
          return dateB.compareTo(dateA);
        });

        quizHistory.value = processedHistory;
      } else {
        quizHistory.value = [];
      }
    } catch (e) {
      quizHistory.value = [];
    }
  }

  logout() async {
    isLoading.value = true;
    try {
      print('🚪 [LOGOUT] Starting logout process...');

      final response = await apiService.post(
        Constants.userLogout,
        requiresAuth: true,
      );

      if (response.success) {
        print('🚪 [LOGOUT] ✅ Logout successful!');
      } else {
        print('🚪 [LOGOUT] ⚠️ Logout API failed: ${response.message}');
      }
    } catch (err) {
      print('❌ [LOGOUT] Error: $err');
    } finally {
      // Always clear local data regardless of API response
      print('🚪 [LOGOUT] Clearing local data...');
      apiService.clearAuth();
      isLoading.value = false;
    }
  }
}
