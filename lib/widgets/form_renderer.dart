import 'package:flutter/material.dart';
import '../models/form_models.dart';

class FormRenderer extends StatefulWidget {
  final FormModel form;
  final bool isPreview;
  final Function(Map<String, dynamic>) onSubmit;
  final bool isSubmitting;

  const FormRenderer({
    Key? key,
    required this.form,
    required this.onSubmit,
    this.isPreview = false,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<FormRenderer> createState() => _FormRendererState();
}

class _FormRendererState extends State<FormRenderer> {
  final Map<String, dynamic> answers = {};
  final Map<String, GlobalKey<FormState>> questionKeys = {};

  @override
  void initState() {
    super.initState();
    // Initialize form keys for each question
    for (var question in widget.form.questions) {
      questionKeys[question.id] = GlobalKey<FormState>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Header
          _buildFormHeader(),
          const SizedBox(height: 32),
          
          // Questions
          ...widget.form.questions.map((question) => _buildQuestion(question)),
          
          const SizedBox(height: 32),
          
          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.form.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (widget.form.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.form.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestion(Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Form(
        key: questionKeys[question.id],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Title
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: question.title),
                  if (question.required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
            
            if (question.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                question.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Question Input
            _buildQuestionInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(Question question) {
    switch (question.type) {
      case 'short_text':
        return TextFormField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Your answer',
          ),
          validator: question.required ? (value) {
            if (value?.isEmpty ?? true) return 'This field is required';
            return null;
          } : null,
          onChanged: (value) => answers[question.id] = value,
        );
        
      case 'long_text':
        return TextFormField(
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Your answer',
          ),
          validator: question.required ? (value) {
            if (value?.isEmpty ?? true) return 'This field is required';
            return null;
          } : null,
          onChanged: (value) => answers[question.id] = value,
        );
        
      case 'multiple_choice':
        return Column(
          children: question.options.map((option) => RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: answers[question.id],
            onChanged: (value) {
              setState(() {
                answers[question.id] = value;
              });
            },
          )).toList(),
        );
        
      case 'checkboxes':
        return Column(
          children: question.options.map((option) {
            final selectedOptions = answers[question.id] as List<String>? ?? [];
            return CheckboxListTile(
              title: Text(option),
              value: selectedOptions.contains(option),
              onChanged: (checked) {
                setState(() {
                  final current = answers[question.id] as List<String>? ?? [];
                  if (checked == true) {
                    answers[question.id] = [...current, option];
                  } else {
                    answers[question.id] = current.where((item) => item != option).toList();
                  }
                });
              },
            );
          }).toList(),
        );
        
      case 'dropdown':
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          hint: const Text('Choose an option'),
          value: answers[question.id],
          items: question.options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option),
          )).toList(),
          onChanged: (value) {
            setState(() {
              answers[question.id] = value;
            });
          },
          validator: question.required ? (value) {
            if (value == null) return 'Please select an option';
            return null;
          } : null,
        );
        
      case 'email':
        return TextFormField(
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter your email',
          ),
          validator: (value) {
            if (question.required && (value?.isEmpty ?? true)) {
              return 'This field is required';
            }
            if (value?.isNotEmpty == true && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Please enter a valid email';
            }
            return null;
          },
          onChanged: (value) => answers[question.id] = value,
        );
        
      case 'number':
        return TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter a number',
          ),
          validator: (value) {
            if (question.required && (value?.isEmpty ?? true)) {
              return 'This field is required';
            }
            if (value?.isNotEmpty == true && double.tryParse(value!) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onChanged: (value) => answers[question.id] = value,
        );
        
      default:
        return const Text('Unsupported question type');
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: widget.isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting...'),
                ],
              )
            : Text(
                widget.form.type == 'quiz' ? 'Submit Quiz' : 'Submit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _handleSubmit() {
    // Validate all questions
    bool isValid = true;
    for (var question in widget.form.questions) {
      final formKey = questionKeys[question.id];
      if (formKey?.currentState?.validate() == false) {
        isValid = false;
      }
    }

    if (!isValid) return;

    // Submit answers
    widget.onSubmit(answers);
  }
}
