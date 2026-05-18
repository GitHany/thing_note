import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _timeFormatKey = 'time_format_24h';

class TimeFormatNotifier extends StateNotifier<bool> {
  TimeFormatNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_timeFormatKey) ?? true;
  }

  Future<void> set24Hour(bool use24Hour) async {
    state = use24Hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_timeFormatKey, use24Hour);
  }
}

final timeFormatProvider =
    StateNotifierProvider<TimeFormatNotifier, bool>((ref) {
  return TimeFormatNotifier();
});
