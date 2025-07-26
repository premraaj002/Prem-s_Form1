import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for Clipboard
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/form_models.dart';
import '../widgets/question_widgets.dart';
import '../screens/form_preview_screen.dart';
import '../screens/public_form_screen.dart';
import 'dart:math';
import '../screens/responses_screen.dart';

class FormBuilderScreen extends StatefulWidget {
  final String? formId; // null for new form, id for editing

  const FormBuilderScreen({Key? key, this.formId}) : super(key: key);

  @override
  _FormBuilderScreenState createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends State<FormBuilderScreen> {
  final _formTitleController = TextEditingController();
  final _formDescriptionController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<FormQuestion> _questions = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _selectedQuestionId;
  FormData? _currentForm; // Store current form for preview

  @override
  void initState() {
    super.initState();
    if (widget.formId != null) {
      _loadForm();
    } else {
      _formTitleController.text = 'Untitled Form';
      _updateCurrentForm(); // Initialize form data
    }
  }

  void _updateCurrentForm() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentForm = FormData(
        id: widget.formId,
        title: _formTitleController.text.trim(),
        description: _formDescriptionController.text.trim(),
        questions: _questions,
        settings: {
          'allowMultipleResponses': true,
          'collectEmail': false,
          'showProgressBar': true,
        },
        createdBy: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublished: false,
        status: 'draft', // Add status field
        responseCount: 0, // Add response count field
      );
    }
  }

  Future<void> _loadForm() async {
    setState(() => _isLoading = true);
    try {
      // Load form from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(widget.formId)
          .get();
      
      if (doc.exists) {
        final formData = FormData.fromJson(doc.data()!);
        _formTitleController.text = formData.title;
        _formDescriptionController.text = formData.description ?? '';
        _questions = formData.questions;
        _currentForm = formData;
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading form: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateQuestionId() {
    return 'q_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  void _addQuestion(String type) {
    final newQuestion = FormQuestion(
      id: _generateQuestionId(),
      type: type,
      title: _getDefaultQuestionTitle(type),
      required: false,
      order: _questions.length,
      options: _needsOptions(type) ? ['Option 1'] : null,
    );

    setState(() {
      _questions.add(newQuestion);
      _selectedQuestionId = newQuestion.id;
      _updateCurrentForm(); // Update form data for preview
    });

    // Scroll to new question
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
      case 'short_answer':
        return 'Short answer text';
      case 'paragraph':
        return 'Long answer text';
      case 'multiple_choice':
        return 'Multiple choice question';
      case 'checkboxes':
        return 'Checkbox question';
      case 'dropdown':
        return 'Dropdown question';
      case 'email':
        return 'Email address';
      case 'number':
        return 'Number';
      case 'date':
        return 'Date';
      case 'time':
        return 'Time';
      case 'rating':
        return 'Rating scale';
      default:
        return 'Untitled Question';
    }
  }

  bool _needsOptions(String type) {
    return ['multiple_choice', 'checkboxes', 'dropdown'].contains(type);
  }

  void _updateQuestion(FormQuestion updatedQuestion) {
    setState(() {
      final index = _questions.indexWhere((q) => q.id == updatedQuestion.id);
      if (index != -1) {
        _questions[index] = updatedQuestion;
        _updateCurrentForm(); // Update form data for preview
      }
    });
  }

  void _deleteQuestion(String questionId) {
    setState(() {
      _questions.removeWhere((q) => q.id == questionId);
      if (_selectedQuestionId == questionId) {
        _selectedQuestionId = null;
      }
      // Reorder questions
      for (int i = 0; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(order: i);
      }
      _updateCurrentForm(); // Update form data for preview
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
    );

    setState(() {
      final insertIndex = originalQuestion.order + 1;
      _questions.insert(insertIndex, duplicatedQuestion);
      // Reorder subsequent questions
      for (int i = insertIndex + 1; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(order: i);
      }
      _updateCurrentForm(); // Update form data for preview
    });
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final question = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, question);
      // Update order for all questions
      for (int i = 0; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(order: i);
      }
      _updateCurrentForm(); // Update form data for preview
    });
  }

  Future<void> _saveForm({bool publish = false}) async {
    if (_formTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a form title')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();
      
      final formData = FormData(
        id: widget.formId,
        title: _formTitleController.text.trim(),
        description: _formDescriptionController.text.trim(),
        questions: _questions,
        settings: {
          'allowMultipleResponses': true,
          'collectEmail': false,
          'showProgressBar': true,
        },
        createdBy: user.uid,
        createdAt: widget.formId == null ? now : _currentForm?.createdAt ?? now,
        updatedAt: now,
        isPublished: publish,
        status: publish ? 'published' : 'draft', // Set status based on publish state
        responseCount: _currentForm?.responseCount ?? 0, // Preserve existing response count
      );

      if (widget.formId == null) {
        // Create new form
        final docRef = await FirebaseFirestore.instance
            .collection('forms')
            .add(formData.toJson());
        
        // Update current form with new ID
        _currentForm = formData.copyWith(id: docRef.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish ? 'Form published successfully!' : 'Form saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back with form ID
        Navigator.of(context).pop(docRef.id);
      } else {
        // Update existing form
        await FirebaseFirestore.instance
            .collection('forms')
            .doc(widget.formId)
            .update(formData.toJson());
        
        _currentForm = formData;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish ? 'Form published successfully!' : 'Form updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving form: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _previewForm() {
    // Update current form data before preview
    _updateCurrentForm();
    
    if (_currentForm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please save the form first')),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add at least one question to preview the form')),
      );
      return;
    }

    // Convert FormData to FormModel for preview
    final formModel = FormModel.fromFormData(_currentForm!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormPreviewScreen(form: formModel),
      ),
    );
  }

  // Updated _shareForm method with enhanced functionality
  void _shareForm() {
    if (_currentForm?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please save the form first to share it')),
      );
      return;
    }

    // For web deployment - replace with your actual domain
   final formUrl = 'https://prem-s-form1-e87biijoj-premraaj002s-projects.vercel.app/form/${_currentForm!.id}';

    
    // For mobile app with deep linking
    // final formUrl = 'https://premsform.app/form/${_currentForm!.id}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share, color: Colors.purple),
            SizedBox(width: 8),
            Text('Share Form'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share this link with others to collect responses:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                formUrl,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            // Warning message if form is not published
            if (_currentForm?.status != 'published')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Form must be published to be accessible via this link.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: formUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Link copied to clipboard!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog first
                      // Open form in preview mode
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PublicFormScreen(
                            formId: _currentForm!.id!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _formTitleController.dispose();
    _formDescriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading Form...'),
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A73E8),
          elevation: 1,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.formId == null ? 'Create Form' : 'Edit Form',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A73E8),
        elevation: 1,
        actions: [
          // Preview
          TextButton.icon(
            onPressed: _previewForm,
            icon: Icon(Icons.visibility, size: 16),
            label: Text('Preview'),
            style: TextButton.styleFrom(foregroundColor: Color(0xFF1A73E8)),
          ),

          // Share
          if (_currentForm?.id != null)
            TextButton.icon(
              onPressed: _shareForm,
              icon: Icon(Icons.share, size: 16),
              label: Text('Share'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),

          // Responses
          if (_currentForm?.id != null && _currentForm!.status == 'published')
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResponsesScreen(
                      formId: _currentForm!.id!,
                      formTitle: _currentForm!.title,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.analytics, size: 16),
              label: Text('Responses'),
              style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
            ),

          // Save
          TextButton.icon(
            onPressed: _isSaving ? null : () => _saveForm(),
            icon: Icon(Icons.save, size: 16),
            label: Text('Save'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),

          // Publish
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveForm(publish: true),
              icon: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.publish, size: 16),
              label: Text(_isSaving ? 'Publishing...' : 'Publish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),

      body: Row(
        children: [
          // Main Form Builder
          Expanded(
            flex: isDesktop ? 3 : 1,
            child: _buildFormBuilder(),
          ),
          
          // Question Types Sidebar (Desktop only)
          if (isDesktop)
            Container(
              width: 300,
              color: Colors.white,
              child: _buildQuestionTypesSidebar(),
            ),
        ],
      ),
      
      // Floating Action Button for Mobile
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: () => _showQuestionTypesBottomSheet(),
              backgroundColor: Color(0xFF1A73E8),
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildFormBuilder() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Header
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
                TextField(
                  controller: _formTitleController,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  decoration: InputDecoration(
                    hintText: 'Form title',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  onChanged: (value) => _updateCurrentForm(),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _formDescriptionController,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Form description (optional)',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  onChanged: (value) => _updateCurrentForm(),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Empty state when no questions
          if (_questions.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 2, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first question to get started',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showQuestionTypesBottomSheet(),
                    icon: Icon(Icons.add),
                    label: Text('Add Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          
          // Questions
          if (_questions.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              onReorder: _reorderQuestions,
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return QuestionWidget(
                  key: ValueKey(question.id),
                  question: question,
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
              },
            ),
          
          SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildQuestionTypesSidebar() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle, color: Color(0xFF1A73E8)),
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
            itemCount: questionTypes.length,
            itemBuilder: (context, index) {
              final questionType = questionTypes[index];
              return Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () => _addQuestion(questionType.type),
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
                          color: Color(0xFF1A73E8),
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
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: Color(0xFF1A73E8)),
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
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: questionTypes.length,
                itemBuilder: (context, index) {
                  final questionType = questionTypes[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _addQuestion(questionType.type);
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
                            questionType.icon,
                            color: Color(0xFF1A73E8),
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            questionType.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            questionType.description,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
