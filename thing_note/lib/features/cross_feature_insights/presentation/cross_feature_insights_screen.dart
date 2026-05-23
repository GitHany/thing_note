import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/cross_feature_insights/data/cross_feature_insights_provider.dart';

class CrossFeatureInsightsScreen extends ConsumerWidget {
  const CrossFeatureInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(crossFeatureInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('跨功能洞察'),
      ),
      body: insightsAsync.when(
        data: (insights) {
          if (insights.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(crossFeatureInsightsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: insights.length,
              itemBuilder: (context, index) {
                return _buildInsightCard(context, insights[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无洞察数据',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '记录更多数据以获取跨功能洞察分析',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, CrossFeatureInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showInsightDetail(context, insight),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getInsightColor(insight.insightType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        insight.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildConfidenceIndicator(insight.confidence),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insight.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: insight.recommendations.take(2).map((rec) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rec,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    final percent = (confidence * 100).toInt();
    Color color;
    
    if (percent >= 80) {
      color = Colors.green;
    } else if (percent >= 60) {
      color = Colors.blue;
    } else if (percent >= 40) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }
    
    return Row(
      children: [
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: confidence,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percent%置信',
          style: TextStyle(fontSize: 10, color: color),
        ),
      ],
    );
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'correlation':
        return Colors.purple;
      case 'sync':
        return Colors.blue;
      case 'health':
        return Colors.green;
      case 'location':
        return Colors.orange;
      case 'tag':
        return Colors.pink;
      case 'time':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showInsightDetail(BuildContext context, CrossFeatureInsight insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    insight.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildConfidenceIndicator(insight.confidence),
              const SizedBox(height: 24),
              Text(
                '洞察分析',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(insight.description),
              const SizedBox(height: 24),
              Text(
                '建议行动',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...insight.recommendations.map((rec) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    _getInsightTypeIcon(insight.insightType),
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '类型: ${_getInsightTypeName(insight.insightType)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getInsightTypeIcon(String type) {
    switch (type) {
      case 'correlation':
        return Icons.trending_up;
      case 'sync':
        return Icons.sync;
      case 'health':
        return Icons.favorite;
      case 'location':
        return Icons.location_on;
      case 'tag':
        return Icons.label;
      case 'time':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }

  String _getInsightTypeName(String type) {
    switch (type) {
      case 'correlation':
        return '关联分析';
      case 'sync':
        return '协同分析';
      case 'health':
        return '健康分析';
      case 'location':
        return '位置分析';
      case 'tag':
        return '标签分析';
      case 'time':
        return '时间分析';
      default:
        return '其他';
    }
  }
}