import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormQuestion {
  final String id;
  final String type;
  final String title;
  final String? description;
  final bool required;
  final List<String>? options;
  final Map<String, dynamic>? settings;
  final int order;
  // Add quiz-specific fields
  final bool isQuizQuestion;
  final String? correctAnswer;
  final List<String>? correctAnswers;
  final int? points;

  FormQuestion({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.required = false,
    this.options,
    this.settings,
    required this.order,
    this.isQuizQuestion = false,
    this.correctAnswer,
    this.correctAnswers,
    this.points = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'required': required,
      'options': options,
      'settings': settings,
      'order': order,
      'isQuizQuestion': isQuizQuestion,
      'correctAnswer': correctAnswer,
      'correctAnswers': correctAnswers,
      'points': points,
    };
  }

  factory FormQuestion.fromJson(Map<String, dynamic> json) {
    return FormQuestion(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      required: json['required'] ?? false,
      options: json['options']?.cast<String>(),
      settings: json['settings'],
      order: json['order'],
      isQuizQuestion: json['isQuizQuestion'] ?? false,
      correctAnswer: json['correctAnswer'],
      correctAnswers: json['correctAnswers']?.cast<String>(),
      points: json['points'] ?? 1,
    );
  }

  FormQuestion copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    bool? required,
    List<String>? options,
    Map<String, dynamic>? settings,
    int? order,
    bool? isQuizQuestion,
    String? correctAnswer,
    List<String>? correctAnswers,
    int? points,
  }) {
    return FormQuestion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      required: required ?? this.required,
      options: options ?? this.options,
      settings: settings ?? this.settings,
      order: order ?? this.order,
      isQuizQuestion: isQuizQuestion ?? this.isQuizQuestion,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      points: points ?? this.points,
    );
  }
}

class FormData {
  final String? id;
  final String title;
  final String? description;
  final List<FormQuestion> questions;
  final Map<String, dynamic> settings;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isQuiz;

  FormData({
    this.id,
    required this.title,
    this.description,
    required this.questions,
    required this.settings,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = false,
    this.isDeleted = false,
    this.deletedAt,
    this.isQuiz = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'settings': settings,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPublished': isPublished,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'isQuiz': isQuiz,
    };
  }

  factory FormData.fromJson(Map<String, dynamic> json) {
    return FormData(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      questions: (json['questions'] as List)
          .map((q) => FormQuestion.fromJson(q))
          .toList(),
      settings: json['settings'] ?? {},
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isPublished: json['isPublished'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      isQuiz: json['isQuiz'] ?? false,
    );
  }

  // Added copyWith method for Phase 1 implementation
  FormData copyWith({
    String? id,
    String? title,
    String? description,
    List<FormQuestion>? questions,
    Map<String, dynamic>? settings,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    bool? isDeleted,
    DateTime? deletedAt,
    bool? isQuiz,
  }) {
    return FormData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      settings: settings ?? this.settings,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      isQuiz: isQuiz ?? this.isQuiz,
    );
  }
}

// Added FormModel class for Phase 1 implementation
class FormModel {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String type;
  final Map<String, dynamic> settings;
  final DateTime? expiresAt;
  final String? thankYouMessage;

  FormModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.type = 'form',
    this.settings = const {},
    this.expiresAt,
    this.thankYouMessage,
  });

  factory FormModel.fromFormData(FormData formData) {
    return FormModel(
      id: formData.id ?? '',
      title: formData.title,
      description: formData.description ?? '',
      questions: formData.questions.map((q) => Question.fromFormQuestion(q)).toList(),
      createdBy: formData.createdBy,
      createdAt: formData.createdAt,
      updatedAt: formData.updatedAt,
      isActive: formData.isPublished,
      type: formData.isQuiz ? 'quiz' : 'form',
      settings: formData.settings,
    );
  }

  // Convert from Firestore document
  factory FormModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final formData = FormData.fromJson(data);
    return FormModel.fromFormData(formData);
  }
}

// Added Question class for Phase 1 implementation
class Question {
  final String id;
  final String type;
  final String title;
  final String description;
  final bool required;
  final List<String> options;
  final Map<String, dynamic> settings;
  final int order;
  final double? points;
  final dynamic correctAnswer;

  Question({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.required,
    required this.options,
    required this.settings,
    required this.order,
    this.points,
    this.correctAnswer,
  });

  factory Question.fromFormQuestion(FormQuestion formQuestion) {
    return Question(
      id: formQuestion.id,
      type: formQuestion.type,
      title: formQuestion.title,
      description: formQuestion.description ?? '',
      required: formQuestion.required,
      options: formQuestion.options ?? [],
      settings: formQuestion.settings ?? {},
      order: formQuestion.order,
      points: formQuestion.points?.toDouble(),
      correctAnswer: formQuestion.correctAnswer,
    );
  }

  // Convert to FormQuestion
  FormQuestion toFormQuestion() {
    return FormQuestion(
      id: id,
      type: type,
      title: title,
      description: description.isEmpty ? null : description,
      required: required,
      options: options.isEmpty ? null : options,
      settings: settings.isEmpty ? null : settings,
      order: order,
      isQuizQuestion: points != null && points! > 0,
      correctAnswer: correctAnswer?.toString(),
      points: points?.toInt(),
    );
  }
}

class QuestionType {
  final String type;
  final String label;
  final IconData icon;
  final String description;

  const QuestionType({
    required this.type,
    required this.label,
    required this.icon,
    required this.description,
  });
}

const List<QuestionType> questionTypes = [
  QuestionType(
    type: 'short_answer',
    label: 'Short Answer',
    icon: Icons.short_text,
    description: 'Single line text input',
  ),
  QuestionType(
    type: 'paragraph',
    label: 'Paragraph',
    icon: Icons.notes,
    description: 'Multi-line text input',
  ),
  QuestionType(
    type: 'multiple_choice',
    label: 'Multiple Choice',
    icon: Icons.radio_button_checked,
    description: 'Single selection from options',
  ),
  QuestionType(
    type: 'checkboxes',
    label: 'Checkboxes',
    icon: Icons.check_box,
    description: 'Multiple selections from options',
  ),
  QuestionType(
    type: 'dropdown',
    label: 'Dropdown',
    icon: Icons.arrow_drop_down_circle,
    description: 'Dropdown selection',
  ),
  QuestionType(
    type: 'email',
    label: 'Email',
    icon: Icons.email,
    description: 'Email address input',
  ),
  QuestionType(
    type: 'number',
    label: 'Number',
    icon: Icons.numbers,
    description: 'Numeric input',
  ),
  QuestionType(
    type: 'date',
    label: 'Date',
    icon: Icons.calendar_today,
    description: 'Date picker',
  ),
  QuestionType(
    type: 'time',
    label: 'Time',
    icon: Icons.access_time,
    description: 'Time picker',
  ),
  QuestionType(
    type: 'rating',
    label: 'Rating Scale',
    icon: Icons.star,
    description: 'Star or numeric rating',
  ),
  QuestionType(
    type: 'true_false',
    label: 'True/False',
    icon: Icons.check_circle_outline,
    description: 'True or false question',
  ),
];
