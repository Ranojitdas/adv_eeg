import 'package:flutter_test/flutter_test.dart';
import 'package:ADDvEEG/Constants/constants.dart';

void main() {
  group('Basic Constants Tests', () {
    test('API base URL is configured correctly', () {
      expect(Constants.apiUrl, equals('https://eeg-node-backend-production.up.railway.app/api/v1'));
    });

    test('User endpoints are properly defined', () {
      expect(Constants.userRegister, isNotEmpty);
      expect(Constants.userLogin, isNotEmpty);
      expect(Constants.userLogout, isNotEmpty);
      expect(Constants.userMe, isNotEmpty);
      expect(Constants.userUpdateLocation, isNotEmpty);
    });

    test('Quiz endpoints are properly defined', () {
      expect(Constants.quizAssign, isNotEmpty);
      expect(Constants.quizSelfInitiate, isNotEmpty);
      expect(Constants.quizMyAssignedQuiz, isNotEmpty);
      expect(Constants.quizMyAllQuizzes, isNotEmpty);
      expect(Constants.quizGetQuizAssignedByMe, isNotEmpty);
    });

    test('Doctor endpoints are properly defined', () {
      expect(Constants.doctorGetAllDoctors, isNotEmpty);
      expect(Constants.doctorGetAllPatients, isNotEmpty);
    });

    test('Patient history endpoint is properly defined', () {
      expect(Constants.patientHistory, isNotEmpty);
    });

    test('Relative endpoint is properly defined', () {
      expect(Constants.relativeGetMonitoredPatient, isNotEmpty);
    });

    test('Question endpoints are properly defined', () {
      expect(Constants.questionCreate, isNotEmpty);
      expect(Constants.questionAll, isNotEmpty);
    });

    test('Dynamic endpoints work correctly', () {
      expect(Constants.getUserById('test123'), contains('test123'));
      expect(Constants.getQuestionByType('TYPE_A'), contains('TYPE_A'));
      expect(Constants.getQuizSubmit('qa123'), contains('qa123'));
      expect(Constants.getQuizHistory('p123'), contains('p123'));
      expect(Constants.getQuizById('qa456'), contains('qa456'));
    });

    test('All endpoints use correct base URL', () {
      final baseUrl = 'https://eeg-node-backend-production.up.railway.app/api/v1';
      
      expect(Constants.userLogin, startsWith(baseUrl));
      expect(Constants.quizAssign, startsWith(baseUrl));
      expect(Constants.doctorGetAllDoctors, startsWith(baseUrl));
      expect(Constants.patientHistory, startsWith(baseUrl));
      expect(Constants.relativeGetMonitoredPatient, startsWith(baseUrl));
    });
  });
}
