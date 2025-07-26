import 'package:flutter/material.dart';
import '../models/form_response.dart';
import '../services/form_service.dart';
import 'response_detail_screen.dart';

class ResponsesScreen extends StatefulWidget {
  final String formId;
  final String formTitle;

  const ResponsesScreen({
    Key? key,
    required this.formId,
    required this.formTitle,
  }) : super(key: key);

  @override
  State<ResponsesScreen> createState() => _ResponsesScreenState();
}

class _ResponsesScreenState extends State<ResponsesScreen> {
  final FormService _formService = FormService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Form Responses'),
            Text(
              widget.formTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: StreamBuilder<List<FormResponse>>(
        stream: _formService.getFormResponses(widget.formId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  SizedBox(height: 16),
                  Text(
                    'Error loading responses',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final responses = snapshot.data ?? [];

          if (responses.isEmpty) {
            return _buildEmptyState();
          }

          return _buildResponsesList(responses);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No responses yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Responses will appear here once people start submitting your form',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesList(List<FormResponse> responses) {
    return Column(
      children: [
        // Summary Card
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[700]),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Responses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Text('${responses.length} submissions'),
                  ],
                ),
              ),
              Text(
                '${responses.length}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),

        // Responses List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: responses.length,
            itemBuilder: (context, index) {
              final response = responses[index];
              return _buildResponseCard(response, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResponseCard(FormResponse response, int responseNumber) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewResponseDetails(response),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Response #$responseNumber',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    _formatDate(response.submittedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // Submitter info
              if (response.submitterName != null || response.submitterEmail != null) ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        response.submitterName ?? response.submitterEmail ?? 'Anonymous',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],

              // Preview of answers
              Row(
                children: [
                  Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${response.answers.length} questions answered',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _viewResponseDetails(FormResponse response) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResponseDetailScreen(
          response: response,
          formId: widget.formId,
        ),
      ),
    );
  }
}
