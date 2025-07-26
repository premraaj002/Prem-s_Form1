import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/form_models.dart';
import '../widgets/quiz_question_widget.dart';
import 'dart:math';

class QuizBuilderScreen extends StatefulWidget {
  final String? quizId;

  const QuizBuilderScreen({Key? key, this.quizId}) : super(key: key);

  @override
  _QuizBuilderScreenState createState() => _QuizBuilderScreenState();
}

class _QuizBuilderScreenState extends State<QuizBuilderScreen> {
  final _quizTitleController = TextEditingController();
  final _quizDescriptionController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<FormQuestion> _questions = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _selectedQuestionId;
  
  // Quiz-specific settings
  bool _showScoreAtEnd = true;
  bool _shuffleQuestions = false;
  int _timeLimit = 0;
  bool _allowRetake = true;

  @override
  void initState() {
    super.initState();
    if (widget.quizId != null) {
      _loadQuiz();
    } else {
      _quizTitleController.text = 'Untitled Quiz';
    }
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(widget.quizId)
          .get();
      
      if (doc.exists) {
        final formData = FormData.fromJson(doc.data()!);
        _quizTitleController.text = formData.title;
        _quizDescriptionController.text = formData.description ?? '';
        _questions = formData.questions;
        
        final settings = formData.settings;
        _showScoreAtEnd = settings['showScoreAtEnd'] ?? true;
        _shuffleQuestions = settings['shuffleQuestions'] ?? false;
        _timeLimit = settings['timeLimit'] ?? 0;
        _allowRetake = settings['allowRetake'] ?? true;
        
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading quiz: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateQuestionId() {
    return 'q_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  void _addQuizQuestion(String type) {
    final newQuestion = FormQuestion(
      id: _generateQuestionId(),
      type: type,
      title: _getDefaultQuestionTitle(type),
      required: true,
      order: _questions.length,
      options: _getDefaultOptions(type),
      isQuizQuestion: true,
      points: 1,
      correctAnswer: type == 'true_false' ? 'True' : null,
    );

    setState(() {
      _questions.add(newQuestion);
      _selectedQuestionId = newQuestion.id;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _getDefaultQuestionTitle(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple choice question';
      case 'true_false':
        return 'True or False question';
      case 'short_answer':
        return 'Short answer question';
      default:
        return 'Quiz Question';
    }
  }

  List<String>? _getDefaultOptions(String type) {
    switch (type) {
      case 'multiple_choice':
        return ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
      case 'true_false':
        return ['True', 'False'];
      default:
        return null;
    }
  }

  void _updateQuestion(FormQuestion updatedQuestion) {
    setState(() {
      final index = _questions.indexWhere((q) => q.id == updatedQuestion.id);
      if (index != -1) {
        _questions[index] = updatedQuestion;
      }
    });
  }

  void _deleteQuestion(String questionId) {
    setState(() {
      _questions.removeWhere((q) => q.id == questionId);
      if (_selectedQuestionId == questionId) {
        _selectedQuestionId = null;
      }
      for (int i = 0; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(order: i);
      }
    });
  }

  void _duplicateQuestion(String questionId) {
    final originalQuestion = _questions.firstWhere((q) => q.id == questionId);
    final duplicatedQuestion = FormQuestion(
      id: _generateQuestionId(),
      type: originalQuestion.type,
      title: '${originalQuestion.title} (Copy)',
      description: originalQuestion.description,
      required: originalQuestion.required,
      options: originalQuestion.options?.toList(),
      settings: Map.from(originalQuestion.settings ?? {}),
      order: originalQuestion.order + 1,
      isQuizQuestion: true,
      correctAnswer: originalQuestion.correctAnswer,
      correctAnswers: originalQuestion.correctAnswers?.toList(),
      points: originalQuestion.points,
    );

    setState(() {
      final insertIndex = originalQuestion.order + 1;
      _questions.insert(insertIndex, duplicatedQuestion);
      for (int i = insertIndex + 1; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(order: i);
      }
    });
  }

  Future<void> _saveQuiz({bool publish = false}) async {
    if (_quizTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a quiz title')),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();
      
      final totalPoints = _questions.fold(0, (sum, q) => sum + (q.points ?? 1));
      
      final formData = FormData(
        id: widget.quizId,
        title: _quizTitleController.text.trim(),
        description: _quizDescriptionController.text.trim(),
        questions: _questions,
        settings: {
          'showScoreAtEnd': _showScoreAtEnd,
          'shuffleQuestions': _shuffleQuestions,
          'timeLimit': _timeLimit,
          'allowRetake': _allowRetake,
          'totalPoints': totalPoints,
        },
        createdBy: user.uid,
        createdAt: widget.quizId == null ? now : DateTime.now(),
        updatedAt: now,
        isPublished: publish,
        isQuiz: true,
        isDeleted: false,
      );

      if (widget.quizId == null) {
        final docRef = await FirebaseFirestore.instance
            .collection('forms')
            .add(formData.toJson());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish ? 'Quiz published successfully!' : 'Quiz saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(docRef.id);
      } else {
        await FirebaseFirestore.instance
            .collection('forms')
            .doc(widget.quizId)
            .update(formData.toJson());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish ? 'Quiz published successfully!' : 'Quiz updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving quiz: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading Quiz...'),
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF34A853),
          elevation: 1,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.quizId == null ? 'Create Quiz' : 'Edit Quiz',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF34A853),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showQuizSettings,
            tooltip: 'Quiz Settings',
          ),
          TextButton.icon(
            onPressed: _isSaving ? null : () => _saveQuiz(),
            icon: Icon(Icons.save, size: 16),
            label: Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveQuiz(publish: true),
              icon: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.publish, size: 16),
              label: Text(_isSaving ? 'Publishing...' : 'Publish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF34A853),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: isDesktop ? 3 : 1,
            child: _buildQuizBuilder(),
          ),
          if (isDesktop)
            Container(
              width: 300,
              color: Colors.white,
              child: _buildQuestionTypesSidebar(),
            ),
        ],
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: () => _showQuestionTypesBottomSheet(),
              backgroundColor: Color(0xFF34A853),
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildQuizBuilder() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.quiz, color: Color(0xFF34A853), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Quiz',
                            style: TextStyle(
                              color: Color(0xFF34A853),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${_questions.length} Questions • ${_questions.fold(0, (sum, q) => sum + (q.points ?? 1))} Points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _quizTitleController,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  decoration: InputDecoration(
                    hintText: 'Quiz title',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _quizDescriptionController,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Quiz description (optional)',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          ..._questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return QuizQuestionWidget(
              key: ValueKey(question.id),
              question: question,
              questionNumber: index + 1,
              isSelected: _selectedQuestionId == question.id,
              onTap: () {
                setState(() {
                  _selectedQuestionId = question.id;
                });
              },
              onUpdate: _updateQuestion,
              onDelete: () => _deleteQuestion(question.id),
              onDuplicate: () => _duplicateQuestion(question.id),
            );
          }).toList(),
          
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildQuestionTypesSidebar() {
    final quizQuestionTypes = [
      QuestionType(
        type: 'multiple_choice',
        label: 'Multiple Choice',
        icon: Icons.radio_button_checked,
        description: 'Single correct answer',
      ),
      QuestionType(
        type: 'true_false',
        label: 'True/False',
        icon: Icons.check_circle_outline,
        description: 'True or false question',
      ),
      QuestionType(
        type: 'short_answer',
        label: 'Short Answer',
        icon: Icons.short_text,
        description: 'Text input answer',
      ),
    ];

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle, color: Color(0xFF34A853)),
              SizedBox(width: 8),
              Text(
                'Add Question',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: quizQuestionTypes.length,
            itemBuilder: (context, index) {
              final questionType = quizQuestionTypes[index];
              return Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () => _addQuizQuestion(questionType.type),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          questionType.icon,
                          color: Color(0xFF34A853),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                questionType.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                questionType.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showQuestionTypesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: Color(0xFF34A853)),
                  SizedBox(width: 8),
                  Text(
                    'Add Question',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                padding: EdgeInsets.all(16),
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildQuestionTypeCard('Multiple Choice', Icons.radio_button_checked, 'multiple_choice'),
                  _buildQuestionTypeCard('True/False', Icons.check_circle_outline, 'true_false'),
                  _buildQuestionTypeCard('Short Answer', Icons.short_text, 'short_answer'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTypeCard(String title, IconData icon, String type) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _addQuizQuestion(type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Color(0xFF34A853),
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showQuizSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quiz Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Show score at end'),
                subtitle: Text('Display final score to students'),
                value: _showScoreAtEnd,
                onChanged: (value) {
                  setState(() {
                    _showScoreAtEnd = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Shuffle questions'),
                subtitle: Text('Randomize question order'),
                value: _shuffleQuestions,
                onChanged: (value) {
                  setState(() {
                    _shuffleQuestions = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Allow retake'),
                subtitle: Text('Students can retake the quiz'),
                value: _allowRetake,
                onChanged: (value) {
                  setState(() {
                    _allowRetake = value;
                  });
                },
              ),
              ListTile(
                title: Text('Time limit'),
                subtitle: Text(_timeLimit == 0 ? 'No time limit' : '$_timeLimit minutes'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showTimeLimitDialog(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showTimeLimitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempTimeLimit = _timeLimit;
        return AlertDialog(
          title: Text('Set Time Limit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter time limit in minutes (0 = no limit):'),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _timeLimit.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  tempTimeLimit = int.tryParse(value) ?? 0;
                },
                decoration: InputDecoration(
                  labelText: 'Minutes',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _timeLimit = tempTimeLimit;
                });
                Navigator.pop(context);
                Navigator.pop(context);
                _showQuizSettings();
              },
              child: Text('Set'),
            ),
          ],
        );
      },
    );
  }
}
