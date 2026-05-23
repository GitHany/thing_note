import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/satisfaction_survey/domain/satisfaction_entry.dart';

class SatisfactionSurveyScreen extends ConsumerStatefulWidget {
  const SatisfactionSurveyScreen({super.key});

  @override
  ConsumerState<SatisfactionSurveyScreen> createState() =>
      _SatisfactionSurveyScreenState();
}

class _SatisfactionSurveyScreenState
    extends ConsumerState<SatisfactionSurveyScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  final Set<String> _selectedFeatures = {};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    // Save to database (would use repository in production)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating section
            Text(
              'How would you rate your experience?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starRating = index + 1;
                return IconButton(
                  icon: Icon(
                    starRating <= _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: starRating <= _rating ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _rating = starRating);
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getRatingLabel(_rating),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 32),

            // Features section
            Text(
              'What features do you use most?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppFeature.allFeatures.map((feature) {
                final isSelected = _selectedFeatures.contains(feature.id);
                return FilterChip(
                  label: Text(feature.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFeatures.add(feature.id);
                      } else {
                        _selectedFeatures.remove(feature.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Comment section
            Text(
              'Any suggestions?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts with us...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}