import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CustomWidgetDashboardScreen extends ConsumerStatefulWidget {
  const CustomWidgetDashboardScreen({super.key});

  @override
  ConsumerState<CustomWidgetDashboardScreen> createState() => _CustomWidgetDashboardScreenState();
}

class _CustomWidgetDashboardScreenState extends ConsumerState<CustomWidgetDashboardScreen> {
  bool _isEditing = false;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {'name': '首页', 'isDefault': true, 'widgets': []},
    {'name': '统计', 'isDefault': false, 'widgets': []},
    {'name': '习惯', 'isDefault': false, 'widgets': []},
  ];

  @override
  void initState() {
    super.initState();
    _loadWidgets();
  }

  void _loadWidgets() {
    // Sample widgets
    _pages[0]['widgets'] = [
      {'type': 'stats', 'title': '今日概览', 'config': {}},
      {'type': 'habit', 'title': '习惯打卡', 'config': {}},
      {'type': 'chart', 'title': '趋势图表', 'config': {}},
    ];
    _pages[1]['widgets'] = [
      {'type': 'chart', 'title': '周统计', 'config': {}},
      {'type': 'ranking', 'title': '排行榜', 'config': {}},
    ];
    _pages[2]['widgets'] = [
      {'type': 'habit', 'title': '今日习惯', 'config': {}},
      {'type': 'streak', 'title': '连续记录', 'config': {}},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义仪表盘'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addWidget(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPageTabs(),
          Expanded(
            child: _buildWidgetGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTabs() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                final isSelected = _currentPage == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      page['name'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetGrid() {
    final widgets = _pages[_currentPage]['widgets'] as List<Map<String, dynamic>>;

    if (widgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无小组件',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addWidget(),
              icon: const Icon(Icons.add),
              label: const Text('添加小组件'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widgets.length,
      itemBuilder: (context, idx) {
        final widgetItem = widgets[idx];
        return _buildWidgetCard(widgetItem, idx);
      },
    );
  }

  Widget _buildWidgetCard(Map<String, dynamic> widget, int widgetIndex) {
    final type = widget['type'] as String;
    
    IconData icon;
    Color color;
    switch (type) {
      case 'stats':
        icon = Icons.analytics;
        color = Colors.blue;
        break;
      case 'habit':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'chart':
        icon = Icons.show_chart;
        color = Colors.orange;
        break;
      case 'ranking':
        icon = Icons.leaderboard;
        color = Colors.purple;
        break;
      case 'streak':
        icon = Icons.local_fire_department;
        color = Colors.red;
        break;
      default:
        icon = Icons.widgets;
        color = Colors.grey;
    }

    return Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      widget['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _buildWidgetContent(type),
              ],
            ),
          ),
          if (_isEditing)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _removeWidget(widgetIndex),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWidgetContent(String type) {
    switch (type) {
      case 'stats':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日记录', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('12 条', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: 0.8, backgroundColor: Colors.grey[200]),
          ],
        );
      case 'habit':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('已完成', style: TextStyle(fontSize: 16)),
                Text('3/5', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            const Text('运动 读书 冥想'),
          ],
        );
      case 'chart':
        return Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [Colors.blue.withOpacity(0.3), Colors.green.withOpacity(0.3)],
            ),
          ),
          child: CustomPaint(
            painter: _SimpleLinePainter(),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  void _addWidget() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '添加小组件',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildWidgetOption('stats', Icons.analytics, '统计卡片', Colors.blue),
                _buildWidgetOption('habit', Icons.check_circle, '习惯打卡', Colors.green),
                _buildWidgetOption('chart', Icons.show_chart, '趋势图表', Colors.orange),
                _buildWidgetOption('ranking', Icons.leaderboard, '排行榜', Colors.purple),
                _buildWidgetOption('streak', Icons.local_fire_department, '连续记录', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetOption(String type, IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          (_pages[_currentPage]['widgets'] as List).add({
            'type': type,
            'title': label,
            'config': {},
          });
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _removeWidget(int index) {
    setState(() {
      (_pages[_currentPage]['widgets'] as List).removeAt(index);
    });
  }

  void _addPage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加页面'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: '页面名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _pages.add({'name': '新页面', 'isDefault': false, 'widgets': []});
              });
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _SimpleLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.3, size.height * 0.5);
    path.lineTo(size.width * 0.6, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}