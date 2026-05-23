import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quick action panel widget - Floating action menu
class QuickActionPanel extends ConsumerWidget {
  final VoidCallback? onCreateRecord;
  final VoidCallback? onVoiceRecord;
  final VoidCallback? onCameraCapture;
  final VoidCallback? onQuickNote;

  const QuickActionPanel({
    super.key,
    this.onCreateRecord,
    this.onVoiceRecord,
    this.onCameraCapture,
    this.onQuickNote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showActionSheet(context),
      child: const Icon(Icons.add),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '快速操作',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickActionButton(
                  icon: Icons.edit_note,
                  label: '记录',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(ctx);
                    onCreateRecord?.call();
                  },
                ),
                _QuickActionButton(
                  icon: Icons.mic,
                  label: '语音',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(ctx);
                    onVoiceRecord?.call();
                  },
                ),
                _QuickActionButton(
                  icon: Icons.camera_alt,
                  label: '拍照',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(ctx);
                    onCameraCapture?.call();
                  },
                ),
                _QuickActionButton(
                  icon: Icons.sticky_note_2,
                  label: '便签',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(ctx);
                    onQuickNote?.call();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}