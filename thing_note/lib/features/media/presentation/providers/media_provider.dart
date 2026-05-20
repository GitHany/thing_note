import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/media/data/media_service_impl.dart';
import 'package:thing_note/features/media/domain/media_service.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  final service = MediaServiceImpl();
  ref.onDispose(() {
    try {
      service.dispose();
    } catch (_) {
      // Ignore disposal errors
    }
  });
  return service;
});