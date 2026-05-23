import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thing_note/features/data_encryption/data/encryption_repository.dart';

class EncryptionSettingsScreen extends ConsumerStatefulWidget {
  const EncryptionSettingsScreen({super.key});

  @override
  ConsumerState<EncryptionSettingsScreen> createState() =>
      _EncryptionSettingsScreenState();
}

class _EncryptionSettingsScreenState
    extends ConsumerState<EncryptionSettingsScreen> {
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showPassphrase = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _enableEncryption() async {
    if (_passphraseController.text.length < 8) {
      _showError('Passphrase must be at least 8 characters');
      return;
    }

    if (_passphraseController.text != _confirmController.text) {
      _showError('Passphrases do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = EncryptionRepository(prefs);
      await repo.enableEncryption(_passphraseController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encryption enabled successfully')),
        );
        setState(() {});
      }
    } catch (e) {
      _showError('Failed to enable encryption: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disableEncryption() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Encryption'),
        content: const Text(
          'Are you sure you want to disable encryption? '
          'Your data will be stored without protection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = EncryptionRepository(prefs);
      await repo.disableEncryption();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encryption disabled')),
        );
        setState(() {});
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Encryption'),
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final repo = EncryptionRepository(snapshot.data!);
          final status = repo.getStatus();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status card
              Card(
                color: status.isEnabled
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: ListTile(
                  leading: Icon(
                    status.isEnabled ? Icons.lock : Icons.lock_open,
                    color: status.isEnabled ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    status.isEnabled ? 'Encryption Enabled' : 'Encryption Disabled',
                  ),
                  subtitle: status.isEnabled
                      ? Text('${status.encryptedFields} fields encrypted')
                      : const Text('Your data is not protected'),
                ),
              ),
              const SizedBox(height: 24),

              if (!status.isEnabled) ...[
                // Enable encryption form
                Text(
                  'Enable Encryption',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set a passphrase to encrypt your sensitive data. '
                  'Make sure to remember it!',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passphraseController,
                  obscureText: !_showPassphrase,
                  decoration: InputDecoration(
                    labelText: 'Passphrase',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassphrase
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _showPassphrase = !_showPassphrase),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: !_showPassphrase,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Passphrase',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isLoading ? null : _enableEncryption,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enable Encryption'),
                ),
              ] else ...[
                // Disable encryption button
                const Text(
                  'Your data is currently encrypted. Disabling encryption '
                  'will make your data accessible without a passphrase.',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _disableEncryption,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Disable Encryption'),
                ),
              ],

              const SizedBox(height: 32),

              // Info section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 8),
                          Text(
                            'About Encryption',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• AES-256 encryption for maximum security\n'
                        '• Your passphrase is never stored\n'
                        '• Encrypted fields: notes, audio paths, document paths\n'
                        '• You\'ll need your passphrase to access encrypted data',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}