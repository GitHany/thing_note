import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/location_history/data/location_history_repository.dart';
import 'package:thing_note/features/location_history/domain/location_entry.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final locationHistoryProvider = Provider((ref) => ref.watch(locationHistoryRepositoryProvider));

class LocationHistoryScreen extends ConsumerStatefulWidget {
  const LocationHistoryScreen({super.key});

  @override
  ConsumerState<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends ConsumerState<LocationHistoryScreen> {
  List<LocationEntry> _entries = [];
  Map<String, int> _placeFrequency = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(locationHistoryProvider);
    _entries = await repo.getRecent(50);
    _placeFrequency = await repo.getPlaceFrequency(30);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locationHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: _showAddLocationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopPlaces(),
                    const SizedBox(height: 16),
                    _buildRecentLocations(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopPlaces() {
    if (_placeFrequency.isEmpty) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.place_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('暂无地点数据'),
            SizedBox(height: 8),
            Text('记录位置后这里会显示你最常去的地方'),
          ],
        ),
      ),
    );
    }

    final sortedPlaces = _placeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text('常去的地方', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedPlaces.take(5).map((entry) {
              final maxCount = sortedPlaces.first.value;
              final percentage = (entry.value / maxCount * 100).round();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.place, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.key)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$percentage%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.green),
                const SizedBox(width: 8),
                Text('最近位置', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            if (_entries.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('暂无位置记录'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.place),
                    ),
                    title: Text(entry.placeName ?? '未知地点'),
                    subtitle: Text(
                      entry.address ?? 
                      '${entry.latitude.toStringAsFixed(4)}, ${entry.longitude.toStringAsFixed(4)}',
                    ),
                    trailing: Text(
                      _formatTime(entry.recordedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  void _showAddLocationDialog() {
    final latController = TextEditingController(text: '39.9042');
    final lngController = TextEditingController(text: '116.4074');
    final placeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加位置'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: placeController,
                decoration: const InputDecoration(
                  labelText: '地点名称',
                  hintText: '例如：公司、家、咖啡厅',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      decoration: const InputDecoration(
                        labelText: '纬度',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      decoration: const InputDecoration(
                        labelText: '经度',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);
              if (lat == null || lng == null) return;

              final entry = LocationEntry(
                latitude: lat,
                longitude: lng,
                placeName: placeController.text.isNotEmpty ? placeController.text : null,
                recordedAt: DateTime.now(),
              );
              await ref.read(locationHistoryProvider).insert(entry);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}