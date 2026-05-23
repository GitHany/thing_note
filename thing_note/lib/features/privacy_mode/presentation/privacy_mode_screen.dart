import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/privacy_mode/domain/privacy_mode_provider.dart';

class PrivacyModeScreen extends ConsumerWidget {
  const PrivacyModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivacyMode = ref.watch(privacyModeProvider);
    final settings = ref.watch(quickHideSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Mode'),
      ),
      body: ListView(
        children: [
          // Main toggle
          SwitchListTile(
            secondary: Icon(
              isPrivacyMode ? Icons.visibility_off : Icons.visibility,
              color: isPrivacyMode ? Colors.red : null,
            ),
            title: const Text('Privacy Mode'),
            subtitle: Text(
              isPrivacyMode
                  ? 'Content is hidden'
                  : 'Content is visible',
            ),
            value: isPrivacyMode,
            onChanged: (_) {
              ref.read(privacyModeProvider.notifier).toggle();
            },
          ),
          const Divider(),

          // Quick hide settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Quick Hide Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: const Text('Hide Photos'),
            subtitle: const Text('Show placeholder instead of photos'),
            value: settings.hidePhotos,
            onChanged: (value) {
              ref.read(quickHideSettingsProvider.notifier).updateSetting(
                    hidePhotos: value,
                  );
            },
          ),
          SwitchListTile(
            title: const Text('Hide Videos'),
            subtitle: const Text('Show placeholder instead of videos'),
            value: settings.hideVideos,
            onChanged: (value) {
              ref.read(quickHideSettingsProvider.notifier).updateSetting(
                    hideVideos: value,
                  );
            },
          ),
          SwitchListTile(
            title: const Text('Hide Audio'),
            subtitle: const Text('Show placeholder instead of audio'),
            value: settings.hideAudio,
            onChanged: (value) {
              ref.read(quickHideSettingsProvider.notifier).updateSetting(
                    hideAudio: value,
                  );
            },
          ),
          SwitchListTile(
            title: const Text('Hide Notes'),
            subtitle: const Text('Show placeholder instead of notes'),
            value: settings.hideNotes,
            onChanged: (value) {
              ref.read(quickHideSettingsProvider.notifier).updateSetting(
                    hideNotes: value,
                  );
            },
          ),
          SwitchListTile(
            title: const Text('Hide Location'),
            subtitle: const Text('Hide location information'),
            value: settings.hideLocation,
            onChanged: (value) {
              ref.read(quickHideSettingsProvider.notifier).updateSetting(
                    hideLocation: value,
                  );
            },
          ),
          SwitchListTile(
            title: const Text('Blur Content'),
            subtitle: const Text('Blur sensitive content in previews'),
            value: settings.blurContent,
            onChanged: (value) {
              ref.read(quickHideSettingsProvider.notifier).updateSetting(
                    blurContent: value,
                  );
            },
          ),
          const Divider(),

          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
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
                          'About Privacy Mode',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Privacy mode helps protect your sensitive information '
                      'when someone else is using your device. You can quickly '
                      'enable it to hide photos, videos, audio, notes, and '
                      'location data.\n\n'
                      'Enable privacy mode by toggling the switch above.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Privacy mode overlay widget
class PrivacyModeOverlay extends ConsumerWidget {
  final Widget child;

  const PrivacyModeOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivacyMode = ref.watch(privacyModeProvider);

    if (!isPrivacyMode) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: Colors.black.withAlpha(128),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Privacy Mode Enabled',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Content is hidden for privacy',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(privacyModeProvider.notifier).disable();
                        },
                        child: const Text('Show Content'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}