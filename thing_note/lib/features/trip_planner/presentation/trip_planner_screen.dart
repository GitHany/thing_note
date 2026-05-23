import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/trip_planner/data/trip_repository.dart';
import 'package:thing_note/features/trip_planner/domain/trip_models.dart';

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('旅行规划'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _selectedStatus = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'planning', child: Text('规划中')),
              const PopupMenuItem(value: 'ongoing', child: Text('进行中')),
              const PopupMenuItem(value: 'completed', child: Text('已完成')),
            ],
          ),
        ],
      ),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (trips) {
          final filtered = _selectedStatus == 'all'
              ? trips
              : trips.where((t) => t.status == _selectedStatus).toList();
          
          if (filtered.isEmpty) {
            return _buildEmptyState();
          }
          return _buildTripList(filtered);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTripDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flight_takeoff, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无旅行计划', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('规划你的下一次旅行', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTripDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('创建旅行'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList(List<Trip> trips) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return _TripCard(
          trip: trips[index],
          onTap: () => _openTripDetail(trips[index]),
          onDelete: () => ref.read(tripsProvider.notifier).deleteTrip(trips[index].id!),
        );
      },
    );
  }

  void _openTripDetail(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TripDetailScreen(tripId: trip.id!)),
    );
  }

  void _showAddTripDialog(BuildContext context) {
    final titleController = TextEditingController();
    final destController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建旅行'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '旅行名称', hintText: '例如：三亚之旅'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: destController,
                  decoration: const InputDecoration(labelText: '目的地', hintText: '例如：海南三亚'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('出发日期'),
                  subtitle: Text('${startDate.year}/${startDate.month}/${startDate.day}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: const Text('结束日期（可选）'),
                  subtitle: Text(endDate != null ? '${endDate!.year}/${endDate!.month}/${endDate!.day}' : '未设置'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? startDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
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
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final trip = Trip(
                    title: titleController.text,
                    destination: destController.text.isEmpty ? null : destController.text,
                    startDate: startDate,
                    endDate: endDate,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  ref.read(tripsProvider.notifier).addTrip(trip);
                  Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(trip.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.flight_takeoff, color: _getStatusColor(trip.status)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (trip.destination != null)
                          Text(
                            trip.destination!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  _StatusChip(status: trip.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${trip.startDate.month}/${trip.startDate.day}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (trip.endDate != null)
                    Text(
                      ' - ${trip.endDate!.month}/${trip.endDate!.day}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planning':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    
    switch (status) {
      case 'planning':
        label = '规划中';
        color = Colors.blue;
        break;
      case 'ongoing':
        label = '进行中';
        color = Colors.green;
        break;
      case 'completed':
        label = '已完成';
        color = Colors.grey;
        break;
      case 'cancelled':
        label = '已取消';
        color = Colors.red;
        break;
      default:
        label = status;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

// Trip Detail Screen
class TripDetailScreen extends ConsumerWidget {
  final int tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));
    final itineraryAsync = ref.watch(tripItinerariesProvider(tripId));
    final bookingsAsync = ref.watch(tripBookingsProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: tripAsync.when(
          data: (trip) => Text(trip?.title ?? '旅行详情'),
          loading: () => const Text('加载中...'),
          error: (_, __) => const Text('旅行详情'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Info
            tripAsync.when(
              data: (trip) => trip != null ? _buildTripInfo(trip) : const SizedBox(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('错误: $e'),
            ),
            const SizedBox(height: 24),

            // Itinerary Section
            _buildSectionHeader('行程安排', Icons.list_alt, () => _showAddItineraryDialog(context, ref)),
            itineraryAsync.when(
              data: (items) => _buildItineraryList(items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('错误: $e'),
            ),
            const SizedBox(height: 24),

            // Bookings Section
            _buildSectionHeader('预订', Icons.book_online, () {}),
            bookingsAsync.when(
              data: (bookings) => _buildBookingsList(bookings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('错误: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfo(Trip trip) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (trip.destination != null)
              _InfoRow(icon: Icons.location_on, label: '目的地', value: trip.destination!),
            _InfoRow(
              icon: Icons.calendar_today,
              label: '日期',
              value: '${trip.startDate.month}/${trip.startDate.day}${trip.endDate != null ? ' - ${trip.endDate!.month}/${trip.endDate!.day}' : ''}',
            ),
            _InfoRow(icon: Icons.people, label: '人数', value: '${trip.participants}人'),
            if (trip.budget != null)
              _InfoRow(icon: Icons.attach_money, label: '预算', value: '¥${trip.budget!.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(icon: const Icon(Icons.add), onPressed: onAdd),
      ],
    );
  }

  Widget _buildItineraryList(List<TripItinerary> items) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('暂无行程安排', style: TextStyle(color: Colors.grey))),
        ),
      );
    }
    return Column(
      children: items.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.event),
          title: Text(item.title),
          subtitle: Text('${item.date.month}/${item.date.day}${item.location != null ? ' - ${item.location}' : ''}'),
        ),
      )).toList(),
    );
  }

  Widget _buildBookingsList(List<TripBooking> bookings) {
    if (bookings.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('暂无预订', style: TextStyle(color: Colors.grey))),
        ),
      );
    }
    return Column(
      children: bookings.map((b) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(_getBookingIcon(b.bookingType)),
          title: Text(b.title),
          subtitle: Text(b.bookingType),
          trailing: b.amount != null ? Text('¥${b.amount!.toStringAsFixed(0)}') : null,
        ),
      )).toList(),
    );
  }

  IconData _getBookingIcon(String type) {
    switch (type) {
      case 'flight':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      case 'car':
        return Icons.directions_car;
      case 'ticket':
        return Icons.confirmation_number;
      default:
        return Icons.book;
    }
  }

  void _showAddItineraryDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加行程'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '行程标题'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final itinerary = TripItinerary(
                  tripId: tripId,
                  title: titleController.text,
                  date: date,
                );
                ref.read(tripRepositoryProvider).insertItinerary(itinerary);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}