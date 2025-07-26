import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/form_models.dart';
import '../models/form_response.dart';

class ResponseDetailScreen extends StatefulWidget {
  final FormResponse response;
  final String formId;

  const ResponseDetailScreen({
    Key? key,
    required this.response,
    required this.formId,
  }) : super(key: key);

  @override
  State<ResponseDetailScreen> createState() => _ResponseDetailScreenState();
}

class _ResponseDetailScreenState extends State<ResponseDetailScreen> {
  FormData? formData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(widget.formId)
          .get();
      
      if (doc.exists) {
        setState(() {
          formData = FormData.fromJson(doc.data()!);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading form data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Response Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : formData == null
              ? Center(child: Text('Form data not found'))
              : _buildResponseDetails(),
    );
  }

  Widget _buildResponseDetails() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Response Header
          _buildResponseHeader(),
          SizedBox(height: 24),

          // Answers Section
          _buildAnswersSection(),
        ],
      ),
    );
  }

  Widget _buildResponseHeader() {
    return Container(
      padding: EdgeInsets.all(20),
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
              Icon(Icons.receipt, color: Colors.blue[600]),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Response Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildInfoRow('Submitted At', _formatFullDate(widget.response.submittedAt)),
          
          if (widget.response.submitterName != null)
            _buildInfoRow('Name', widget.response.submitterName!),
          
          if (widget.response.submitterEmail != null)
            _buildInfoRow('Email', widget.response.submitterEmail!),
          
          _buildInfoRow('Questions Answered', '${widget.response.answers.length}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Responses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        
        ...formData!.questions.map((question) => _buildAnswerCard(question)),
      ],
    );
  }

  Widget _buildAnswerCard(FormQuestion question) {
    final answer = widget.response.answers[question.id];
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
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
          Text(
            question.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Answer
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: answer == null
                ? Text(
                    'No answer provided',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Text(
                    answer.toString(),
                    style: TextStyle(color: Colors.grey[800]),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
