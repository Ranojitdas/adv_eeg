import 'package:flutter_test/flutter_test.dart';
import 'package:ADDvEEG/Constants/constants.dart';

void main() {
  group('API Documentation Compliance Tests', () {
    
    test('User Routes - Exact API Documentation Match', () {
      // From API Doc: POST api/v1/users/register
      expect(Constants.userRegister, endsWith('/users/register'));
      
      // From API Doc: POST api/v1/users/verify-otp
      expect(Constants.userVerifyOtp, endsWith('/users/verify-otp'));
      
      // From API Doc: POST api/v1/users/login
      expect(Constants.userLogin, endsWith('/users/login'));
      
      // From API Doc: GET api/v1/users/me
      expect(Constants.userMe, endsWith('/users/me'));
      
      // From API Doc: POST api/v1/users/logout
      expect(Constants.userLogout, endsWith('/users/logout'));
      
      // From API Doc: PATCH api/v1/users/update-user-location
      expect(Constants.userUpdateLocation, endsWith('/users/update-user-location'));
      
      // From API Doc: GET api/v1/users/:id
      expect(Constants.getUserById('test123'), endsWith('/users/test123'));
    });

    test('Doctor Routes - Exact API Documentation Match', () {
      // From API Doc: GET api/v1/doctor/get-all-doctors
      expect(Constants.doctorGetAllDoctors, endsWith('/doctor/get-all-doctors'));
      
      // From API Doc: GET api/v1/doctor/get-all-patients
      expect(Constants.doctorGetAllPatients, endsWith('/doctor/get-all-patients'));
    });

    test('Relative Routes - Exact API Documentation Match', () {
      // From API Doc: GET api/v1/relative/get-monitored-patient
      expect(Constants.relativeGetMonitoredPatient, endsWith('/relative/get-monitored-patient'));
    });

    test('Question Routes - Exact API Documentation Match', () {
      // From API Doc: POST api/v1/question/create
      expect(Constants.questionCreate, endsWith('/question/create'));
      
      // From API Doc: GET api/v1/question/all
      expect(Constants.questionAll, endsWith('/question/all'));
      
      // From API Doc: GET api/v1/question/type/:type
      expect(Constants.getQuestionByType('TYPE_A'), endsWith('/question/type/TYPE_A'));
      
      // From API Doc: GET api/v1/question/:questionId
      expect(Constants.getQuestionById('q123'), endsWith('/question/q123'));
    });

    test('Quiz Routes - Exact API Documentation Match', () {
      // From API Doc: POST api/v1/quiz/assign
      expect(Constants.quizAssign, endsWith('/quiz/assign'));
      
      // From API Doc: GET api/v1/quiz/my-assigned-quiz
      expect(Constants.quizMyAssignedQuiz, endsWith('/quiz/my-assigned-quiz'));
      
      // From API Doc: POST api/v1/quiz/self-initiate
      expect(Constants.quizSelfInitiate, endsWith('/quiz/self-initiate'));
      
      // From API Doc: POST api/v1/quiz/submit/:quizAttemptId
      expect(Constants.getQuizSubmit('qa123'), endsWith('/quiz/submit/qa123'));
      
      // From API Doc: GET api/v1/quiz/history/:patientId
      expect(Constants.getQuizHistory('p123'), endsWith('/quiz/history/p123'));
      
      // From API Doc: GET api/v1/quiz/my-all-quizs
      expect(Constants.quizMyAllQuizzes, endsWith('/quiz/my-all-quizs'));
      
      // From API Doc: GET api/v1/quiz/get-quiz-by-id/:quizAttemptId
      expect(Constants.getQuizById('qa123'), endsWith('/quiz/get-quiz-by-id/qa123'));
      
      // From API Doc: GET api/v1/quiz/get-quiz-assigned-by-me
      expect(Constants.quizGetQuizAssignedByMe, endsWith('/quiz/get-quiz-assigned-by-me'));
    });

    test('Patient History Routes - Exact API Documentation Match', () {
      // From API Doc: POST api/v1/patient-history/
      // From API Doc: GET api/v1/patient-history/
      expect(Constants.patientHistory, endsWith('/patient-history'));
    });

    test('Base URL Configuration', () {
      expect(Constants.apiUrl, equals('https://eeg-node-backend-production.up.railway.app/api/v1'));
    });

    test('All endpoints use correct base URL', () {
      final baseUrl = 'https://eeg-node-backend-production.up.railway.app/api/v1';
      
      // Test all user routes
      expect(Constants.userRegister, startsWith(baseUrl));
      expect(Constants.userLogin, startsWith(baseUrl));
      expect(Constants.userLogout, startsWith(baseUrl));
      
      // Test all quiz routes
      expect(Constants.quizAssign, startsWith(baseUrl));
      expect(Constants.quizSelfInitiate, startsWith(baseUrl));
      expect(Constants.quizMyAssignedQuiz, startsWith(baseUrl));
      
      // Test all doctor routes
      expect(Constants.doctorGetAllDoctors, startsWith(baseUrl));
      expect(Constants.doctorGetAllPatients, startsWith(baseUrl));
      
      // Test patient history
      expect(Constants.patientHistory, startsWith(baseUrl));
    });

    test('No legacy endpoints in active use', () {
      // Verify that new controllers don't use deprecated endpoints
      // These should only be used in legacy code marked with @deprecated
      
      final newEndpoints = [
        Constants.userRegister,
        Constants.userLogin,
        Constants.quizAssign,
        Constants.quizSelfInitiate,
        Constants.getQuizSubmit('test'),
        Constants.getQuizHistory('test'),
        Constants.patientHistory,
        Constants.relativeGetMonitoredPatient,
      ];
      
      // Ensure no new endpoint contains legacy patterns
      for (final endpoint in newEndpoints) {
        expect(endpoint, isNot(contains('create-quiz')));
        expect(endpoint, isNot(contains('get-profile')));
        expect(endpoint, isNot(contains('get-questionare')));
        expect(endpoint, isNot(contains('brain-signal')));
      }
    });
  });
}
