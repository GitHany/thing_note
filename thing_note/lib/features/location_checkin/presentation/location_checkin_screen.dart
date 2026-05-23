import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/location_checkin/data/location_checkin_repository.dart';
import 'package:thing_note/features/location_checkin/domain/location_checkin.dart';

final locationCheckinRepoProvider = Provider((ref) => LocationCheckinRepository(ref));

class LocationCheckinScreen extends ConsumerStatefulWidget {
  const LocationCheckinScreen({super.key});

  @override
  ConsumerState<LocationCheckinScreen> createState() => _LocationCheckinScreenState();
}

class _LocationCheckinScreenState extends ConsumerState<LocationCheckinScreen> {
  List<LocationCheckin> _checkins = [];
  Map<String, int> _placeStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(locationCheckinRepoProvider);
    _checkins = await repo.getRecentCheckins(limit: 50);
    _placeStats = await repo.getPlaceStats();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('位置打卡'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: _showCheckinDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildFrequentPlaces(),
                  _buildRecentCheckins(),
                ],
              ),
            ),
    );
  }

  Widget _buildFrequentPlaces() {
    if (_placeStats.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('常去地点', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _placeStats.entries.take(6).map((e) {
              return ActionChip(
                avatar: const Icon(Icons.location_on, size: 18),
                label: Text('${e.key} (${e.value})'),
                onPressed: () => _showCheckinDialog(placeName: e.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCheckins() {
    if (_checkins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无打卡记录'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCheckinDialog,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('立即打卡'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _checkins.length,
      itemBuilder: (context, index) {
        final checkin = _checkins[index];
        return _CheckinCard(
          checkin: checkin,
          onDelete: () => _deleteCheckin(checkin.id!),
        );
      },
    );
  }

  void _showCheckinDialog({String? placeName}) {
    final placeController = TextEditingController(text: placeName);
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('位置打卡'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: placeController,
                decoration: const InputDecoration(
                  labelText: '地点名称',
                  hintText: '例如：公司、家、咖啡厅',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: '备注（可选）'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'GPS定位将自动获取',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
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
              if (placeController.text.trim().isEmpty) return;
              final repo = ref.read(locationCheckinRepoProvider);
              await repo.insertCheckin(LocationCheckin(
                placeName: placeController.text.trim(),
                latitude: 0.0, // Would use actual GPS in production
                longitude: 0.0,
                note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                checkInAt: DateTime.now(),
                createdAt: DateTime.now(),
              ));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('打卡'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCheckin(int id) async {
    final repo = ref.read(locationCheckinRepoProvider);
    await repo.deleteCheckin(id);
    _loadData();
  }
}

class _CheckinCard extends StatelessWidget {
  final LocationCheckin checkin;
  final VoidCallback onDelete;

  const _CheckinCard({
    required this.checkin,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.location_on),
        ),
        title: Text(checkin.placeName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(checkin.checkInAt)),
            if (checkin.note != null) Text(checkin.note!),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}