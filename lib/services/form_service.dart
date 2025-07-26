import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/form_models.dart';
import '../models/form_response.dart';

class FormService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a form response
  Future<String> submitFormResponse({
    required String formId,
    required Map<String, dynamic> answers,
    String? submitterEmail,
    String? submitterName,
    int timeSpent = 0,
  }) async {
    try {
      final response = FormResponse(
        id: '',
        formId: formId,
        answers: answers,
        submittedAt: DateTime.now(),
        submitterEmail: submitterEmail,
        submitterName: submitterName,
        timeSpent: timeSpent,
      );

      final docRef = await _firestore
          .collection('responses')
          .add(response.toFirestore());

      // Try to update form response count
      try {
        await _firestore.collection('forms').doc(formId).update({
          'responseCount': FieldValue.increment(1),
          'lastResponseAt': Timestamp.now(),
        });
      } catch (e) {
        print('Could not update form stats: $e');
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit form: $e');
    }
  }

  // Get form by ID for public access
  Future<FormModel?> getPublicForm(String formId) async {
    try {
      final doc = await _firestore.collection('forms').doc(formId).get();
      
      if (!doc.exists) return null;
      
      final formData = FormData.fromJson(doc.data()!);
      return FormModel.fromFormData(formData);
    } catch (e) {
      throw Exception('Failed to load form: $e');
    }
  }

  // PERMANENT FIX: Get responses for a form with server-side ordering
  Stream<List<FormResponse>> getFormResponses(String formId) {
    return _firestore
        .collection('responses')
        .where('formId', isEqualTo: formId)
        .orderBy('submittedAt', descending: true) // ✅ RESTORED - Now works with composite index
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FormResponse.fromFirestore(doc))
            .toList());
  }

  // Validate form answers
  Map<String, String> validateAnswers(FormModel form, Map<String, dynamic> answers) {
    Map<String, String> errors = {};
    
    for (var question in form.questions) {
      final answer = answers[question.id];
      
      if (question.required && (answer == null || answer.toString().trim().isEmpty)) {
        errors[question.id] = 'This question is required';
        continue;
      }
      
      if (answer == null || answer.toString().trim().isEmpty) continue;
      
      switch (question.type) {
        case 'email':
          if (!_isValidEmail(answer.toString())) {
            errors[question.id] = 'Please enter a valid email address';
          }
          break;
        case 'number':
          if (!_isValidNumber(answer.toString())) {
            errors[question.id] = 'Please enter a valid number';
          }
          break;
      }
    }
    
    return errors;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidNumber(String number) {
    return double.tryParse(number) != null;
  }
}
