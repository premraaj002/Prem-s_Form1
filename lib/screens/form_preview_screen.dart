import 'package:flutter/material.dart';
import '../models/form_models.dart';
import '../widgets/form_renderer.dart';

class FormPreviewScreen extends StatelessWidget {
  final FormModel form;

  const FormPreviewScreen({
    Key? key,
    required this.form,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Preview'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: () => _shareForm(context),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Preview Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          'This is how your form will appear to respondents',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Form Renderer
            FormRenderer(
              form: form,
              isPreview: true,
              onSubmit: (answers) => _handlePreviewSubmit(context, answers),
            ),
          ],
        ),
      ),
    );
  }

  void _shareForm(BuildContext context) {
    final formUrl = 'https://yourapp.com/form/${form.id}'; // Replace with your domain
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this link with respondents:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                formUrl,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard!')),
              );
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  void _handlePreviewSubmit(BuildContext context, Map<String, dynamic> answers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Submission'),
        content: const Text('This is a preview. No data has been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
