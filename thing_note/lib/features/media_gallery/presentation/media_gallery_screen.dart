import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mediaGalleryProvider = StateNotifierProvider<MediaGalleryNotifier, List<MediaItem>>((ref) {
  return MediaGalleryNotifier();
});

class MediaGalleryNotifier extends StateNotifier<List<MediaItem>> {
  MediaGalleryNotifier() : super([]);

  void addItem(MediaItem item) {
    state = [item, ...state];
  }

  void removeItem(int id) {
    state = state.where((i) => i.id != id).toList();
  }
}

class MediaItem {
  final int id;
  final String filePath;
  final String fileType;
  final String? thumbnailPath;
  final int fileSize;
  final int? width;
  final int? height;
  final int? linkedRecordId;
  final int? albumId;
  final String createdAt;

  MediaItem({
    required this.id,
    required this.filePath,
    required this.fileType,
    this.thumbnailPath,
    this.fileSize = 0,
    this.width,
    this.height,
    this.linkedRecordId,
    this.albumId,
    required this.createdAt,
  });

  MediaItem copyWith({
    int? id,
    String? filePath,
    String? fileType,
    String? thumbnailPath,
    int? fileSize,
    int? width,
    int? height,
    int? linkedRecordId,
    int? albumId,
    String? createdAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      albumId: albumId ?? this.albumId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MediaGalleryScreen extends ConsumerStatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  ConsumerState<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends ConsumerState<MediaGalleryScreen> {
  String _sortBy = 'date';
  bool _sortAsc = false;
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(mediaGalleryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStats(items),
          Expanded(
            child: items.isEmpty ? _buildEmptyState() : _buildMediaGrid(items),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(List<MediaItem> items) {
    final photos = items.where((i) => i.fileType == 'photo').length;
    final videos = items.where((i) => i.fileType == 'video').length;
    final totalSize = items.fold<int>(0, (sum, i) => sum + i.fileSize);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                icon: Icons.photo,
                value: '$photos',
                label: 'Photos',
                color: Colors.blue,
              ),
              _buildStatColumn(
                icon: Icons.videocam,
                value: '$videos',
                label: 'Videos',
                color: Colors.red,
              ),
              _buildStatColumn(
                icon: Icons.storage,
                value: _formatSize(totalSize),
                label: 'Size',
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No media files yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Photos and videos from your records will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(List<MediaItem> items) {
    var filtered = items;
    
    if (_filterType != 'all') {
      filtered = items.where((i) => i.fileType == _filterType).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text('No $_filterType files', style: TextStyle(color: Colors.grey[600])),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _buildMediaTile(item);
      },
    );
  }

  Widget _buildMediaTile(MediaItem item) {
    return GestureDetector(
      onTap: () => _showMediaDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                item.fileType == 'photo' ? Icons.image : Icons.videocam,
                color: Colors.grey[400],
                size: 32,
              ),
            ),
            if (item.fileType == 'video')
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                ),
              ),
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatSize(item.fileSize),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaDetail(MediaItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Media Detail',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        item.fileType == 'photo' ? Icons.image : Icons.videocam,
                        color: Colors.grey[400],
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Type', item.fileType.toUpperCase()),
                  _buildDetailRow('Size', _formatSize(item.fileSize)),
                  if (item.width != null && item.height != null)
                    _buildDetailRow('Dimensions', '${item.width} x ${item.height}'),
                  _buildDetailRow('Date', _formatDate(item.createdAt)),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ref.read(mediaGalleryProvider.notifier).removeItem(item.id);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Delete'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // Share functionality
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            trailing: _sortBy == 'date' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _sortBy = 'date');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Size'),
            trailing: _sortBy == 'size' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _sortBy = 'size');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
            title: Text(_sortAsc ? 'Ascending' : 'Descending'),
            onTap: () {
              setState(() => _sortAsc = !_sortAsc);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('All'),
            trailing: _filterType == 'all' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _filterType = 'all');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Photos Only'),
            trailing: _filterType == 'photo' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _filterType = 'photo');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Videos Only'),
            trailing: _filterType == 'video' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _filterType = 'video');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.parse(isoDate);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}