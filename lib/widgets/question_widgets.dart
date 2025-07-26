import 'package:flutter/material.dart';
import '../models/form_models.dart';

class QuestionWidget extends StatefulWidget {
  final FormQuestion question;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(FormQuestion) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const QuestionWidget({
    Key? key,
    required this.question,
    required this.isSelected,
    required this.onTap,
    required this.onUpdate,
    required this.onDelete,
    required this.onDuplicate,
  }) : super(key: key);

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  List<TextEditingController> _optionControllers = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.question.title);
    _descriptionController = TextEditingController(text: widget.question.description ?? '');
    
    if (widget.question.options != null) {
      _optionControllers = widget.question.options!
          .map((option) => TextEditingController(text: option))
          .toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveChanges() {
    final updatedQuestion = widget.question.copyWith(
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      options: _optionControllers.isEmpty 
          ? null 
          : _optionControllers.map((c) => c.text).where((text) => text.isNotEmpty).toList(),
    );
    widget.onUpdate(updatedQuestion);
    setState(() => _isEditing = false);
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController(text: 'Option ${_optionControllers.length + 1}'));
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 1) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? Color(0xFF1A73E8) : Colors.grey[200]!,
              width: widget.isSelected ? 2 : 1,
            ),
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
              // Question Header
              Row(
                children: [
                  Icon(
                    _getQuestionIcon(widget.question.type),
                    color: Color(0xFF1A73E8),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getQuestionTypeLabel(widget.question.type),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  if (widget.isSelected) ...[
                    IconButton(
                      icon: Icon(Icons.content_copy, size: 16),
                      onPressed: widget.onDuplicate,
                      tooltip: 'Duplicate',
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[600]),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete',
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(),
                    ),
                  ],
                  // Drag handle
                  ReorderableDragStartListener(
                    index: widget.question.order,
                    child: Icon(Icons.drag_handle, color: Colors.grey[400]),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Question Title
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                decoration: InputDecoration(
                  hintText: 'Question title',
                  border: widget.isSelected ? UnderlineInputBorder() : InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                onChanged: (_) => _saveChanges(),
              ),
              
              // Question Description
              if (widget.isSelected || widget.question.description != null)
                TextField(
                  controller: _descriptionController,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    border: widget.isSelected ? UnderlineInputBorder() : InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  onChanged: (_) => _saveChanges(),
                ),
              
              SizedBox(height: 16),
              
              // Question Preview/Options
              _buildQuestionPreview(),
              
              if (widget.isSelected) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Spacer(),
                    Switch(
                      value: widget.question.required,
                      onChanged: (value) {
                        widget.onUpdate(widget.question.copyWith(required: value));
                      },
                      activeColor: Color(0xFF1A73E8),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPreview() {
    switch (widget.question.type) {
      case 'short_answer':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Text(
            'Short answer text',
            style: TextStyle(color: Colors.grey[500]),
          ),
        );
        
      case 'paragraph':
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Long answer text',
            style: TextStyle(color: Colors.grey[500]),
          ),
        );
        
      case 'multiple_choice':
      case 'checkboxes':
        return _buildOptionsEditor();
        
      case 'dropdown':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text('Choose', style: TextStyle(color: Colors.grey[500])),
              Spacer(),
              Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
            ],
          ),
        );
        
      case 'email':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Text(
            'example@email.com',
            style: TextStyle(color: Colors.grey[500]),
          ),
        );
        
      case 'number':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Text(
            '123',
            style: TextStyle(color: Colors.grey[500]),
          ),
        );
        
      case 'date':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text('mm/dd/yyyy', style: TextStyle(color: Colors.grey[500])),
              Spacer(),
              Icon(Icons.calendar_today, color: Colors.grey[500], size: 16),
            ],
          ),
        );
        
      case 'time':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text('--:-- --', style: TextStyle(color: Colors.grey[500])),
              Spacer(),
              Icon(Icons.access_time, color: Colors.grey[500], size: 16),
            ],
          ),
        );
        
      case 'rating':
        return Row(
          children: List.generate(5, (index) => 
            Icon(Icons.star_border, color: Colors.grey[400], size: 24)
          ),
        );
        
      default:
        return Container();
    }
  }

  Widget _buildOptionsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_optionControllers.length, (index) {
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  widget.question.type == 'multiple_choice' 
                      ? Icons.radio_button_unchecked 
                      : Icons.check_box_outline_blank,
                  color: Colors.grey[400],
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Option ${index + 1}',
                      border: widget.isSelected ? UnderlineInputBorder() : InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                    onChanged: (_) => _saveChanges(),
                  ),
                ),
                if (widget.isSelected && _optionControllers.length > 1)
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                    onPressed: () => _removeOption(index),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
          );
        }),
        if (widget.isSelected)
          TextButton.icon(
            onPressed: _addOption,
            icon: Icon(Icons.add, size: 16),
            label: Text('Add option'),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF1A73E8),
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  IconData _getQuestionIcon(String type) {
    switch (type) {
      case 'short_answer': return Icons.short_text;
      case 'paragraph': return Icons.notes;
      case 'multiple_choice': return Icons.radio_button_checked;
      case 'checkboxes': return Icons.check_box;
      case 'dropdown': return Icons.arrow_drop_down_circle;
      case 'email': return Icons.email;
      case 'number': return Icons.numbers;
      case 'date': return Icons.calendar_today;
      case 'time': return Icons.access_time;
      case 'rating': return Icons.star;
      default: return Icons.help_outline;
    }
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'short_answer': return 'Short Answer';
      case 'paragraph': return 'Paragraph';
      case 'multiple_choice': return 'Multiple Choice';
      case 'checkboxes': return 'Checkboxes';
      case 'dropdown': return 'Dropdown';
      case 'email': return 'Email';
      case 'number': return 'Number';
      case 'date': return 'Date';
      case 'time': return 'Time';
      case 'rating': return 'Rating Scale';
      default: return 'Question';
    }
  }
}
