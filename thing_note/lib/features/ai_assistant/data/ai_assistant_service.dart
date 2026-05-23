import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiAssistantService {
  /// Generate contextual suggestions based on current records
  Future<List<Map<String, dynamic>>> generateSuggestions(
    List<Map<String, dynamic>> recentRecords,
  ) async {
    if (recentRecords.isEmpty) {
      return [
        {
          'title': 'Start Recording',
          'description': 'Add your first event to get personalized insights',
          'icon': Icons.add,
        },
      ];
    }

    final suggestions = <Map<String, dynamic>>[];

    // Analyze patterns
    final recordCount = recentRecords.length;
    if (recordCount > 10) {
      suggestions.add({
        'title': 'Weekly Summary',
        'description': 'Generate a summary of your week',
        'icon': Icons.summarize,
      });
    }

    suggestions.add({
      'title': 'Smart Tags',
      'description': 'Get AI-powered tag suggestions',
      'icon': Icons.label,
    });

    suggestions.add({
      'title': 'Trend Analysis',
      'description': 'Analyze your recording patterns',
      'icon': Icons.trending_up,
    });

    return suggestions;
  }

  /// Generate a response to user message
  Future<String> generateResponse(
    String userMessage,
    List<Map<String, dynamic>> context,
  ) async {
    // Simple rule-based responses for demo
    // In production, this would call an actual AI API
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello! I\'m your AI assistant. How can I help you today?';
    }

    if (lowerMessage.contains('help')) {
      return 'I can help you with:\n'
          '• Summarizing your records\n'
          '• Suggesting tags\n'
          '• Analyzing patterns\n'
          '• Setting smart reminders\n'
          '• Generating reports';
    }

    if (lowerMessage.contains('summary') || lowerMessage.contains('总结')) {
      return 'Based on your recent records, here\'s what I found...';
    }

    return 'I understand you want to talk about "$userMessage". '
        'How can I assist you with your records?';
  }

  /// Categorize a record based on its content
  Future<String> categorizeRecord(String note) async {
    final lowerNote = note.toLowerCase();

    if (lowerNote.contains('work') || lowerNote.contains('meeting') ||
        lowerNote.contains('project') || lowerNote.contains('工作')) {
      return 'Work';
    }
    if (lowerNote.contains('exercise') || lowerNote.contains('run') ||
        lowerNote.contains('gym') || lowerNote.contains('运动')) {
      return 'Health';
    }
    if (lowerNote.contains('learn') || lowerNote.contains('study') ||
        lowerNote.contains('course') || lowerNote.contains('学习')) {
      return 'Learning';
    }
    if (lowerNote.contains('family') || lowerNote.contains('friend') ||
        lowerNote.contains('social') || lowerNote.contains('家庭')) {
      return 'Social';
    }

    return 'General';
  }

  /// Generate smart tag suggestions
  Future<List<String>> suggestTags(String note) async {
    final tags = <String>[];
    final lowerNote = note.toLowerCase();

    // Keyword-based tagging
    if (lowerNote.contains('important') || lowerNote.contains('urgent') ||
        lowerNote.contains('重要') || lowerNote.contains('紧急')) {
      tags.add('Important');
    }
    if (lowerNote.contains('recurring') || lowerNote.contains('daily') ||
        lowerNote.contains('周期')) {
      tags.add('Recurring');
    }
    if (lowerNote.contains('goal') || lowerNote.contains('target') ||
        lowerNote.contains('目标')) {
      tags.add('Goal');
    }

    return tags;
  }
}

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  return AiAssistantService();
});