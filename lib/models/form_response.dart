import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_models.dart';

class FormResponse {
  final String id;
  final String formId;
  final Map<String, dynamic> answers;
  final DateTime submittedAt;
  final String? submitterEmail;
  final String? submitterName;
  final double? score;
  final int timeSpent;
  final String status;

  FormResponse({
    required this.id,
    required this.formId,
    required this.answers,
    required this.submittedAt,
    this.submitterEmail,
    this.submitterName,
    this.score,
    this.timeSpent = 0,
    this.status = 'completed',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'formId': formId,
      'answers': answers,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'submitterEmail': submitterEmail,
      'submitterName': submitterName,
      'score': score,
      'timeSpent': timeSpent,
      'status': status,
    };
  }

  factory FormResponse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FormResponse(
      id: doc.id,
      formId: data['formId'] ?? '',
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      submitterEmail: data['submitterEmail'],
      submitterName: data['submitterName'],
      score: data['score']?.toDouble(),
      timeSpent: data['timeSpent'] ?? 0,
      status: data['status'] ?? 'completed',
    );
  }
}
