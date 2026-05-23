import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/place/domain/place.dart';

class PlaceScreen extends ConsumerStatefulWidget {
  const PlaceScreen({super.key});

  @override
  ConsumerState<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends ConsumerState<PlaceScreen> with SingleTickerProviderStateMixin {
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
    final placesAsync = ref.watch(placeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('地点管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '常用'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: placesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (places) {
          if (places.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('还没有添加地点'),
                  SizedBox(height: 8),
                  Text('点击右上角添加常用地点'),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _PlaceList(places: places),
              _PlaceList(
                places: places.where((p) => p.visitCount > 0).toList()
                  ..sort((a, b) => b.visitCount.compareTo(a.visitCount)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _PlaceEditor(),
    );
  }
}

class _PlaceList extends StatelessWidget {
  final List<Place> places;

  const _PlaceList({required this.places});

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return _PlaceCard(place: place);
      },
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;

  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(int.parse(place.color.replaceFirst('#', '0xFF'))).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconData(place.icon),
            color: Color(int.parse(place.color.replaceFirst('#', '0xFF'))),
          ),
        ),
        title: Text(place.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place.alias != null)
              Text('别名: ${place.alias}'),
            Row(
              children: [
                Icon(Icons.visibility, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${place.visitCount} 次访问'),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(_formatDuration(place.totalDurationSec)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.navigation),
              onPressed: () {
                // TODO: Navigate to place
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                // TODO: Delete place
              },
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getIconData(String? icon) {
    switch (icon) {
      case 'home': return Icons.home;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'store': return Icons.store;
      case 'restaurant': return Icons.restaurant;
      case 'gym': return Icons.fitness_center;
      case 'hospital': return Icons.local_hospital;
      case 'park': return Icons.park;
      default: return Icons.place;
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '${hours}h${mins}m';
  }
}

class _PlaceEditor extends StatefulWidget {
  const _PlaceEditor();

  @override
  State<_PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends State<_PlaceEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedIcon = 'place';
  String _selectedColor = '#607D8B';
  String? _selectedCategory;

  final List<String> _icons = ['home', 'work', 'school', 'store', 'restaurant', 'gym', 'hospital', 'park', 'place'];
  final List<String> _colors = ['#607D8B', '#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9C27B0', '#00BCD4', '#795548'];
  final List<String> _categories = ['家', '工作', '学习', '娱乐', '餐饮', '运动', '医疗', '其他'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '添加地点',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '地点名称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? '请输入名称' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aliasController,
                decoration: const InputDecoration(
                  labelText: '别名 (可选)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: '分类',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '地址 (可选)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('图标'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _icons.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                      ),
                      child: Icon(_getIconData(icon)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('颜色'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'home': return Icons.home;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'store': return Icons.store;
      case 'restaurant': return Icons.restaurant;
      case 'gym': return Icons.fitness_center;
      case 'hospital': return Icons.local_hospital;
      case 'park': return Icons.park;
      default: return Icons.place;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: Save place
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}