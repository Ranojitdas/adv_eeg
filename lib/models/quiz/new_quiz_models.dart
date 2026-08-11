// New Quiz Models matching API Documentation
import 'dart:convert';

// Quiz Assignment Response Model
class QuizAssignmentResponse {
  final bool success;
  final int statusCode;
  final String message;
  final QuizAssignmentData? data;

  QuizAssignmentResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory QuizAssignmentResponse.fromJson(Map<String, dynamic> json) {
    return QuizAssignmentResponse(
      success: json['success'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? QuizAssignmentData.fromJson(json['data']) : null,
    );
  }
}

class QuizAssignmentData {
  final String quizAttemptId;
  final String patientId;
  final String questionnaireType;
  final String assignedBy;
  final DateTime createdAt;

  QuizAssignmentData({
    required this.quizAttemptId,
    required this.patientId,
    required this.questionnaireType,
    required this.assignedBy,
    required this.createdAt,
  });

  factory QuizAssignmentData.fromJson(Map<String, dynamic> json) {
    return QuizAssignmentData(
      quizAttemptId: json['quizAttemptId'] ?? '',
      patientId: json['patientId'] ?? '',
      questionnaireType: json['questionnaireType'] ?? '',
      assignedBy: json['assignedBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Quiz Self-Initiate Response Model
class QuizSelfInitiateResponse {
  final bool success;
  final int statusCode;
  final String message;
  final QuizInitiateData? data;

  QuizSelfInitiateResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory QuizSelfInitiateResponse.fromJson(Map<String, dynamic> json) {
    return QuizSelfInitiateResponse(
      success: json['success'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? QuizInitiateData.fromJson(json['data']) : null,
    );
  }
}

class QuizInitiateData {
  final String quizAttemptId;
  final String questionnaireType;
  final DateTime createdAt;

  QuizInitiateData({
    required this.quizAttemptId,
    required this.questionnaireType,
    required this.createdAt,
  });

  factory QuizInitiateData.fromJson(Map<String, dynamic> json) {
    return QuizInitiateData(
      quizAttemptId: json['quizAttemptId'] ?? '',
      questionnaireType: json['questionnaireType'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Quiz Submission Response Model
class QuizSubmissionResponse {
  final bool success;
  final int statusCode;
  final String message;
  final QuizSubmissionData? data;

  QuizSubmissionResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory QuizSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return QuizSubmissionResponse(
      success: json['success'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? QuizSubmissionData.fromJson(json['data']) : null,
    );
  }
}

class QuizSubmissionData {
  final String quizAttemptId;
  final int score;
  final List<QuizResponse> responses;
  final DateTime submittedAt;

  QuizSubmissionData({
    required this.quizAttemptId,
    required this.score,
    required this.responses,
    required this.submittedAt,
  });

  factory QuizSubmissionData.fromJson(Map<String, dynamic> json) {
    return QuizSubmissionData(
      quizAttemptId: json['quizAttemptId'] ?? '',
      score: json['score'] ?? 0,
      responses: (json['responses'] as List<dynamic>?)
          ?.map((e) => QuizResponse.fromJson(e))
          .toList() ?? [],
      submittedAt: DateTime.parse(json['submittedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class QuizResponse {
  final String questionId;
  final dynamic selectedOption;

  QuizResponse({
    required this.questionId,
    required this.selectedOption,
  });

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      questionId: json['question'] ?? json['questionId'] ?? '',
      selectedOption: json['selectedOptionId'] ?? json['selectedOption'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOption': selectedOption,
    };
  }
}

// Quiz History Response Model
class QuizHistoryResponse {
  final bool success;
  final int statusCode;
  final String message;
  final List<QuizHistoryItem> data;

  QuizHistoryResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory QuizHistoryResponse.fromJson(Map<String, dynamic> json) {
    return QuizHistoryResponse(
      success: json['success'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => QuizHistoryItem.fromJson(e))
          .toList() ?? [],
    );
  }
}

class QuizHistoryItem {
  final String id;
  final String questionnaireType;
  final List<QuizResponse> responses;
  final int score;
  final String? latitude;
  final String? longitude;

  QuizHistoryItem({
    required this.id,
    required this.questionnaireType,
    required this.responses,
    required this.score,
    this.latitude,
    this.longitude,
  });

  factory QuizHistoryItem.fromJson(Map<String, dynamic> json) {
    // Use the score provided by the API instead of calculating it
    final responses = (json['responses'] as List<dynamic>?)
        ?.map((e) => QuizResponse.fromJson(e))
        .toList() ?? [];
    
    // Get score from API response, fallback to 0 if not provided
    final score = json['score'] ?? 0;

    return QuizHistoryItem(
      id: json['_id'] ?? '',
      questionnaireType: json['questionnaireType'] ?? '',
      responses: responses,
      score: score,
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}

// Question Response Model (matching API documentation)
class QuestionResponse {
  final bool success;
  final int statusCode;
  final String message;
  final List<Question> data;

  QuestionResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      success: json['success'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Question.fromJson(e))
          .toList() ?? [],
    );
  }
}

class Question {
  final String id;
  final List<String> type;
  final String question;
  final List<String> options;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? json['id'] ?? '',
      type: List<String>.from(json['type'] ?? []),
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
