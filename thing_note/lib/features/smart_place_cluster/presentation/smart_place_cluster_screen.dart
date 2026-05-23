import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/smart_place_cluster/data/place_cluster_repository.dart';
import 'package:thing_note/features/smart_place_cluster/domain/place_cluster.dart';

final clustersProvider = FutureProvider<List<PlaceCluster>>((ref) async {
  final repository = ref.watch(placeClusterRepositoryProvider);
  return await repository.getAllClusters();
});

class SmartPlaceClusterScreen extends ConsumerStatefulWidget {
  const SmartPlaceClusterScreen({super.key});

  @override
  ConsumerState<SmartPlaceClusterScreen> createState() => _SmartPlaceClusterScreenState();
}

class _SmartPlaceClusterScreenState extends ConsumerState<SmartPlaceClusterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clustersAsync = ref.watch(clustersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能地点'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddClusterDialog(context),
            tooltip: '添加地点',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '常去地点'),
            Tab(text: '统计'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClustersList(context, clustersAsync),
          _buildStatisticsTab(context),
        ],
      ),
    );
  }

  Widget _buildClustersList(
    BuildContext context,
    AsyncValue<List<PlaceCluster>> clustersAsync,
  ) {
    return clustersAsync.when(
      data: (clusters) {
        if (clusters.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clusters.length,
          itemBuilder: (context, index) {
            return _buildClusterCard(context, clusters[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              '暂无地点记录',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '添加常去地点，系统将自动统计访问次数和停留时长',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddClusterDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('添加地点'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterCard(BuildContext context, PlaceCluster cluster) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showClusterDetails(context, cluster),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cluster.colorValue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  cluster.iconData,
                  size: 28,
                  color: cluster.colorValue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cluster.clusterName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cluster.colorValue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cluster.typeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: cluster.colorValue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${cluster.visitCount}次',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.timer,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          cluster.durationLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditClusterDialog(context, cluster);
                  } else if (value == 'delete') {
                    _showDeleteConfirmDialog(context, cluster);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(placeClusterRepositoryProvider).getClusterStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        final totalClusters = stats['total_clusters'] as int;
        final totalVisits = stats['total_visits'] as int;
        final topTypes = stats['top_types'] as List<Map<String, dynamic>>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.place,
                      label: '地点数量',
                      value: totalClusters.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.visibility,
                      label: '访问次数',
                      value: totalVisits.toString(),
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '地点类型分布',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (topTypes.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        '暂无数据',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: topTypes.map((type) {
                        final typeName = type['cluster_type'] as String;
                        final count = type['count'] as int;
                        final maxCount = topTypes.first['count'] as int;
                        final progress = count / maxCount;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(PlaceCluster.getTypeLabel(typeName)),
                                  Text(
                                    '$count 个',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getTypeColor(typeName),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    final colors = {
      'home': Colors.blue,
      'work': Colors.purple,
      'restaurant': Colors.orange,
      'shopping': Colors.pink,
      'entertainment': Colors.teal,
      'sports': Colors.green,
      'education': Colors.indigo,
      'hospital': Colors.red,
      'park': Colors.lightGreen,
      'transport': Colors.blueGrey,
    };
    return colors[type] ?? Colors.grey;
  }

  void _showClusterDetails(BuildContext context, PlaceCluster cluster) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cluster.colorValue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            cluster.iconData,
                            color: cluster.colorValue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cluster.clusterName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                cluster.typeLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: FutureBuilder<List<PlaceVisitHistory>>(
                      future: ref.read(placeClusterRepositoryProvider).getVisitHistory(
                        cluster.id!,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              '暂无访问记录',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: snapshot.data!.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final history = snapshot.data![index];
                            return ListTile(
                              leading: const Icon(Icons.location_on),
                              title: Text(_formatDateTime(history.arrivedAt)),
                              subtitle: history.durationMinutes != null
                                  ? Text('停留 ${history.durationMinutes} 分钟')
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(String isoTime) {
    try {
      final date = DateTime.parse(isoTime);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }

  void _showAddClusterDialog(BuildContext context) {
    _showClusterDialog(context, null);
  }

  void _showEditClusterDialog(BuildContext context, PlaceCluster cluster) {
    _showClusterDialog(context, cluster);
  }

  void _showClusterDialog(BuildContext context, PlaceCluster? existingCluster) {
    final nameController = TextEditingController(
      text: existingCluster?.clusterName ?? '',
    );
    String selectedType = existingCluster?.clusterType ?? 'other';
    String selectedColor = existingCluster?.color ?? 'blue';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingCluster == null ? '添加地点' : '编辑地点'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '地点名称',
                        hintText: '例如：公司、家门口',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: '地点类型',
                      ),
                      items: PlaceCluster.clusterTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(PlaceCluster.getTypeLabel(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedType = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('颜色'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildColorOption('blue', Colors.blue, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                        _buildColorOption('green', Colors.green, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                        _buildColorOption('orange', Colors.orange, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                        _buildColorOption('purple', Colors.purple, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                        _buildColorOption('red', Colors.red, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                        _buildColorOption('teal', Colors.teal, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入地点名称')),
                      );
                      return;
                    }

                    final repository = ref.read(placeClusterRepositoryProvider);
                    final cluster = PlaceCluster(
                      id: existingCluster?.id,
                      clusterName: nameController.text,
                      clusterType: selectedType,
                      color: selectedColor,
                      visitCount: existingCluster?.visitCount ?? 0,
                      avgDurationMinutes: existingCluster?.avgDurationMinutes ?? 0,
                      createdAt: existingCluster?.createdAt ?? DateTime.now().toIso8601String(),
                    );

                    if (existingCluster == null) {
                      await repository.insertCluster(cluster);
                    } else {
                      await repository.updateCluster(cluster);
                    }

                    ref.invalidate(clustersProvider);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(existingCluster == null ? '添加' : '保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorOption(
    String value,
    Color color,
    String selected,
    Function(String) onSelect,
  ) {
    final isSelected = value == selected;
    return InkWell(
      onTap: () => onSelect(value),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, PlaceCluster cluster) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除地点「${cluster.clusterName}」吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repository = ref.read(placeClusterRepositoryProvider);
                await repository.deleteCluster(cluster.id!);
                ref.invalidate(clustersProvider);
                if (!mounted) return;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
