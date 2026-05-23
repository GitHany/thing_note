import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI 分类规则
class ClassificationRule {
  final String id;
  final String keyword;
  final String suggestedThing;
  final List<String> suggestedTags;
  final int matchCount;
  final bool isEnabled;

  const ClassificationRule({
    required this.id,
    required this.keyword,
    required this.suggestedThing,
    required this.suggestedTags,
    this.matchCount = 0,
    this.isEnabled = true,
  });
}

/// 分类结果
class ClassificationResult {
  final String? suggestedThingName;
  final List<String> suggestedTags;
  final double confidence;
  final String reason;

  const ClassificationResult({
    this.suggestedThingName,
    required this.suggestedTags,
    required this.confidence,
    required this.reason,
  });
}

/// AI 分类器 Provider
final aiClassifierProvider = StateNotifierProvider<AiClassifierNotifier, AsyncValue<List<ClassificationRule>>>((ref) {
  return AiClassifierNotifier();
});

class AiClassifierNotifier extends StateNotifier<AsyncValue<List<ClassificationRule>>> {
  AiClassifierNotifier() : super(const AsyncValue.loading());

  Future<void> loadRules() async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      state = AsyncValue.data([
        const ClassificationRule(id: '1', keyword: '会议', suggestedThing: '工作会议', suggestedTags: ['工作']),
        const ClassificationRule(id: '2', keyword: '运动', suggestedThing: '健身', suggestedTags: ['健康']),
        const ClassificationRule(id: '3', keyword: '读书', suggestedThing: '阅读', suggestedTags: ['学习']),
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  ClassificationResult classify(String note) {
    final rules = state.value ?? [];
    for (final rule in rules) {
      if (note.contains(rule.keyword)) {
        return ClassificationResult(
          suggestedThingName: rule.suggestedThing,
          suggestedTags: rule.suggestedTags,
          confidence: 0.85,
          reason: '关键词 "${rule.keyword}" 匹配',
        );
      }
    }
    return const ClassificationResult(suggestedTags: [], confidence: 0.3, reason: '无匹配规则');
  }

  Future<void> addRule(ClassificationRule rule) async {
    state.whenData((rules) {
      state = AsyncValue.data([...rules, rule]);
    });
  }
}