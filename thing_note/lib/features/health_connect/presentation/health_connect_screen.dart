import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class HealthConnectScreen extends ConsumerStatefulWidget {
  const HealthConnectScreen({super.key});

  @override
  ConsumerState<HealthConnectScreen> createState() => _HealthConnectScreenState();
}

class _HealthConnectScreenState extends ConsumerState<HealthConnectScreen> {
  bool _isConnected = false;
  bool _syncSteps = true;
  bool _syncSleep = true;
  bool _syncHeartRate = false;
  bool _syncWeight = true;
  DateTime? _lastSync;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.healthConnect),
      ),
      body: ListView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        children: [
          // Connection status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.cloud_off,
                    size: 64,
                    color: _isConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isConnected
                        ? AppLocalizations.of(context)!.connected
                        : AppLocalizations.of(context)!.notConnected,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_lastSync != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${AppLocalizations.of(context)!.lastSync}: ${_formatDateTime(_lastSync!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _toggleConnection,
                    icon: Icon(_isConnected ? Icons.link_off : Icons.link),
                    label: Text(_isConnected
                        ? AppLocalizations.of(context)!.disconnect
                        : AppLocalizations.of(context)!.connect),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sync options
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.syncOptions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.steps),
                  subtitle: Text(AppLocalizations.of(context)!.stepsDesc),
                  secondary: const Icon(Icons.directions_walk),
                  value: _syncSteps,
                  onChanged: _isConnected ? (value) => setState(() => _syncSteps = value) : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.sleepData),
                  subtitle: Text(AppLocalizations.of(context)!.sleepDataDesc),
                  secondary: const Icon(Icons.bedtime),
                  value: _syncSleep,
                  onChanged: _isConnected ? (value) => setState(() => _syncSleep = value) : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.heartRate),
                  subtitle: Text(AppLocalizations.of(context)!.heartRateDesc),
                  secondary: const Icon(Icons.favorite),
                  value: _syncHeartRate,
                  onChanged: _isConnected ? (value) => setState(() => _syncHeartRate = value) : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.weight),
                  subtitle: Text(AppLocalizations.of(context)!.weightDesc),
                  secondary: const Icon(Icons.monitor_weight),
                  value: _syncWeight,
                  onChanged: _isConnected ? (value) => setState(() => _syncWeight = value) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Manual sync
          if (_isConnected)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: Text(AppLocalizations.of(context)!.syncNow),
                    subtitle: Text(AppLocalizations.of(context)!.syncNowDesc),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _performSync,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Auto-sync schedule
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.autoSyncSchedule,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(AppLocalizations.of(context)!.syncFrequency),
                  subtitle: Text(AppLocalizations.of(context)!.syncDaily),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFrequencyPicker(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleConnection() async {
    setState(() => _isConnected = !_isConnected);
    if (_isConnected) {
      await _performSync();
    }
  }

  Future<void> _performSync() async {
    setState(() => _lastSync = DateTime.now());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(width: 16),
              Text(AppLocalizations.of(context)!.syncing),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFrequencyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.hourglass_bottom),
            title: Text(AppLocalizations.of(context)!.every15Minutes),
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: Text(AppLocalizations.of(context)!.everyHour),
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: const Icon(Icons.today),
            title: Text(AppLocalizations.of(context)!.daily),
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}