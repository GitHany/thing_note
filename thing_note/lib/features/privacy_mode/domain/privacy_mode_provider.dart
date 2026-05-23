import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Privacy mode state provider
final privacyModeProvider = StateNotifierProvider<PrivacyModeNotifier, bool>((ref) {
  return PrivacyModeNotifier();
});

class PrivacyModeNotifier extends StateNotifier<bool> {
  static const _key = 'privacy_mode_enabled';

  PrivacyModeNotifier() : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final newState = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, newState);
    state = newState;
  }

  Future<void> enable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = true;
  }

  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
    state = false;
  }
}

/// Quick hide settings
class QuickHideSettings {
  final bool hidePhotos;
  final bool hideVideos;
  final bool hideAudio;
  final bool hideNotes;
  final bool hideLocation;
  final bool blurContent;

  QuickHideSettings({
    this.hidePhotos = true,
    this.hideVideos = true,
    this.hideAudio = true,
    this.hideNotes = false,
    this.hideLocation = false,
    this.blurContent = false,
  });

  QuickHideSettings copyWith({
    bool? hidePhotos,
    bool? hideVideos,
    bool? hideAudio,
    bool? hideNotes,
    bool? hideLocation,
    bool? blurContent,
  }) {
    return QuickHideSettings(
      hidePhotos: hidePhotos ?? this.hidePhotos,
      hideVideos: hideVideos ?? this.hideVideos,
      hideAudio: hideAudio ?? this.hideAudio,
      hideNotes: hideNotes ?? this.hideNotes,
      hideLocation: hideLocation ?? this.hideLocation,
      blurContent: blurContent ?? this.blurContent,
    );
  }
}

final quickHideSettingsProvider =
    StateNotifierProvider<QuickHideSettingsNotifier, QuickHideSettings>((ref) {
  return QuickHideSettingsNotifier();
});

class QuickHideSettingsNotifier extends StateNotifier<QuickHideSettings> {
  QuickHideSettingsNotifier() : super(QuickHideSettings());

  void updateSetting({
    bool? hidePhotos,
    bool? hideVideos,
    bool? hideAudio,
    bool? hideNotes,
    bool? hideLocation,
    bool? blurContent,
  }) {
    state = state.copyWith(
      hidePhotos: hidePhotos,
      hideVideos: hideVideos,
      hideAudio: hideAudio,
      hideNotes: hideNotes,
      hideLocation: hideLocation,
      blurContent: blurContent,
    );
  }
}