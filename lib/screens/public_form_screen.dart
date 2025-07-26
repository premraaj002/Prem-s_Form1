import 'package:flutter/material.dart';
import '../models/form_models.dart';
import '../services/form_service.dart';
import '../widgets/form_renderer.dart';

class PublicFormScreen extends StatefulWidget {
  final String formId;

  const PublicFormScreen({
    Key? key,
    required this.formId,
  }) : super(key: key);

  @override
  State<PublicFormScreen> createState() => _PublicFormScreenState();
}

class _PublicFormScreenState extends State<PublicFormScreen> {
  final FormService _formService = FormService();
  FormModel? form;
  bool isLoading = true;
  String? errorMessage;
  bool isSubmitting = false;
  bool isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    try {
      final loadedForm = await _formService.getPublicForm(widget.formId);
      setState(() {
        form = loadedForm;
        isLoading = false;
        if (form == null) {
          errorMessage = 'Form not found or no longer available';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load form: $e';
      });
    }
  }

  Future<void> _handleSubmit(Map<String, dynamic> answers) async {
    if (form == null || isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      // Validate answers
      final errors = _formService.validateAnswers(form!, answers);
      if (errors.isNotEmpty) {
        _showValidationErrors(errors);
        setState(() {
          isSubmitting = false;
        });
        return;
      }

      // Submit response
      await _formService.submitFormResponse(
        formId: widget.formId,
        answers: answers,
        submitterEmail: answers['_email'], // If collected
        submitterName: answers['_name'], // If collected
      );

      setState(() {
        isSubmitting = false;
        isSubmitted = true;
      });
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      _showErrorDialog('Failed to submit form: $e');
    }
  }

  void _showValidationErrors(Map<String, String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Please fix the following errors:'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors.values.map((error) => Text('• $error')).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (isSubmitted) {
      return _buildThankYouScreen();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormRenderer(
        form: form!,
        isPreview: false,
        onSubmit: _handleSubmit,
        isSubmitting: isSubmitting,
      ),
    );
  }

  Widget _buildThankYouScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Thank you!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your response has been submitted successfully.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (form?.thankYouMessage?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                form!.thankYouMessage!,
                style: TextStyle(
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
