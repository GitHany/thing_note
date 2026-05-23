import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/vehicle_repository.dart';
import '../domain/vehicle_entry.dart';

final vehicleProvider = StateNotifierProvider<VehicleNotifier, AsyncValue<List<VehicleEntry>>>((ref) {
  return VehicleNotifier(ref.watch(vehicleRepositoryProvider));
});

class VehicleNotifier extends StateNotifier<AsyncValue<List<VehicleEntry>>> {
  final VehicleRepository _repository;

  VehicleNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    state = const AsyncValue.loading();
    try {
      final vehicles = await _repository.getAllVehicles();
      state = AsyncValue.data(vehicles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addVehicle(VehicleEntry vehicle) async {
    await _repository.insertVehicle(vehicle);
    await loadVehicles();
  }

  Future<void> updateVehicle(VehicleEntry vehicle) async {
    await _repository.updateVehicle(vehicle);
    await loadVehicles();
  }

  Future<void> deleteVehicle(int id) async {
    await _repository.deleteVehicle(id);
    await loadVehicles();
  }
}

class VehicleTrackerScreen extends ConsumerWidget {
  const VehicleTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆追踪'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: vehiclesAsync.when(
        data: (vehicles) => vehicles.isEmpty
            ? const Center(child: Text('暂无车辆'))
            : ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return _buildVehicleCard(context, ref, vehicle);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVehicleDialog(context, ref),
        child: const Icon(Icons.directions_car),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, WidgetRef ref, VehicleEntry vehicle) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, size: 40, color: Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.name, style: Theme.of(context).textTheme.titleLarge),
                      if (vehicle.licensePlate != null)
                        Text(vehicle.licensePlate!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('编辑')),
                    const PopupMenuItem(value: 'fuel', child: Text('加油记录')),
                    const PopupMenuItem(value: 'delete', child: Text('删除')),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showVehicleDialog(context, ref, vehicle);
                    } else if (value == 'fuel') {
                      _showFuelRecordDialog(context, ref, vehicle);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, ref, vehicle);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('品牌', vehicle.brand ?? '-'),
            _buildInfoRow('型号', vehicle.model ?? '-'),
            _buildInfoRow('年份', vehicle.purchaseYear.toString()),
            _buildInfoRow('里程', '${vehicle.currentMileage} km'),
            _buildInfoRow('车架号', vehicle.vin ?? '-'),
            if (vehicle.insuranceExpiry != null)
              _buildInfoRow('保险到期', vehicle.insuranceExpiry!),
            if (vehicle.inspectionExpiry != null)
              _buildInfoRow('年检到期', vehicle.inspectionExpiry!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showVehicleDialog(BuildContext context, WidgetRef ref, [VehicleEntry? vehicle]) {
    showDialog(
      context: context,
      builder: (context) => VehicleFormDialog(vehicle: vehicle),
    );
  }

  void _showFuelRecordDialog(BuildContext context, WidgetRef ref, VehicleEntry vehicle) {
    showDialog(
      context: context,
      builder: (context) => FuelRecordDialog(vehicleId: vehicle.id!),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, VehicleEntry vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除车辆'),
        content: Text('确定要删除 "${vehicle.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(vehicleProvider.notifier).deleteVehicle(vehicle.id!);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class VehicleFormDialog extends ConsumerStatefulWidget {
  final VehicleEntry? vehicle;

  const VehicleFormDialog({super.key, this.vehicle});

  @override
  ConsumerState<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends ConsumerState<VehicleFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _plateController;
  late TextEditingController _mileageController;
  late TextEditingController _vinController;
  String _purchaseYear = DateTime.now().year.toString();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle?.name ?? '');
    _brandController = TextEditingController(text: widget.vehicle?.brand ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _plateController = TextEditingController(text: widget.vehicle?.licensePlate ?? '');
    _mileageController = TextEditingController(text: widget.vehicle?.currentMileage.toString() ?? '0');
    _vinController = TextEditingController(text: widget.vehicle?.vin ?? '');
    if (widget.vehicle != null) {
      _purchaseYear = widget.vehicle!.purchaseYear.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicle != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑车辆' : '添加车辆'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: '车辆名称 *')),
            TextField(controller: _brandController, decoration: const InputDecoration(labelText: '品牌')),
            TextField(controller: _modelController, decoration: const InputDecoration(labelText: '型号')),
            TextField(controller: _plateController, decoration: const InputDecoration(labelText: '车牌号')),
            DropdownButtonFormField<String>(
              value: _purchaseYear,
              decoration: const InputDecoration(labelText: '购买年份'),
              items: List.generate(30, (i) => (DateTime.now().year - i).toString())
                  .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                  .toList(),
              onChanged: (value) => setState(() => _purchaseYear = value!),
            ),
            TextField(
              controller: _mileageController,
              decoration: const InputDecoration(labelText: '当前里程 (km)'),
              keyboardType: TextInputType.number,
            ),
            TextField(controller: _vinController, decoration: const InputDecoration(labelText: '车架号 (VIN)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;

            final vehicle = VehicleEntry(
              id: widget.vehicle?.id,
              name: _nameController.text,
              brand: _brandController.text.isEmpty ? null : _brandController.text,
              model: _modelController.text.isEmpty ? null : _modelController.text,
              licensePlate: _plateController.text.isEmpty ? null : _plateController.text,
              purchaseYear: int.tryParse(_purchaseYear) ?? DateTime.now().year,
              currentMileage: int.tryParse(_mileageController.text) ?? 0,
              vin: _vinController.text.isEmpty ? null : _vinController.text,
              createdAt: widget.vehicle?.createdAt ?? DateTime.now().toIso8601String(),
            );

            if (isEditing) {
              ref.read(vehicleProvider.notifier).updateVehicle(vehicle);
            } else {
              ref.read(vehicleProvider.notifier).addVehicle(vehicle);
            }
            Navigator.pop(context);
          },
          child: Text(isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }
}

class FuelRecordDialog extends ConsumerStatefulWidget {
  final int vehicleId;

  const FuelRecordDialog({super.key, required this.vehicleId});

  @override
  ConsumerState<FuelRecordDialog> createState() => _FuelRecordDialogState();
}

class _FuelRecordDialogState extends ConsumerState<FuelRecordDialog> {
  late TextEditingController _amountController;
  late TextEditingController _litersController;
  late TextEditingController _mileageController;
  late TextEditingController _stationController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _litersController = TextEditingController();
    _mileageController = TextEditingController();
    _stationController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加加油记录'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('日期'),
              subtitle: Text('${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            TextField(controller: _mileageController, decoration: const InputDecoration(labelText: '当前里程 (km)'), keyboardType: TextInputType.number),
            TextField(controller: _litersController, decoration: const InputDecoration(labelText: '加油量 (L)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: '金额 (¥)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: _stationController, decoration: const InputDecoration(labelText: '加油站 (可选)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () async {
            if (_amountController.text.isEmpty || _litersController.text.isEmpty) return;

            final record = FuelRecord(
              vehicleId: widget.vehicleId,
              date: _selectedDate,
              mileage: int.tryParse(_mileageController.text) ?? 0,
              amount: double.tryParse(_amountController.text) ?? 0,
              liters: double.tryParse(_litersController.text) ?? 0,
              station: _stationController.text.isEmpty ? null : _stationController.text,
              createdAt: DateTime.now().toIso8601String(),
            );

            await ref.read(vehicleRepositoryProvider).insertFuelRecord(record);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}