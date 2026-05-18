import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dateFormatKey = 'date_format';

enum DateFormatOption {
  ymd,
  mdy,
  dmy,
}

class DateFormatNotifier extends StateNotifier<DateFormatOption> {
  DateFormatNotifier() : super(DateFormatOption.ymd) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_dateFormatKey);
    if (index != null && index < DateFormatOption.values.length) {
      state = DateFormatOption.values[index];
    }
  }

  Future<void> setDateFormat(DateFormatOption option) async {
    state = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dateFormatKey, option.index);
  }
}

final dateFormatProvider =
    StateNotifierProvider<DateFormatNotifier, DateFormatOption>((ref) {
  return DateFormatNotifier();
});
