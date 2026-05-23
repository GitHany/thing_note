import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_checkin_widget/domain/habit_checkin_widget_provider.dart';

final habitCheckinRepositoryProvider = Provider<HabitCheckinWidgetRepository>((ref) {
  return HabitCheckinWidgetRepository();
});

final todayHabitsProvider = FutureProvider<List<HabitCheckin>>((ref) async {
  final repository = ref.watch(habitCheckinRepositoryProvider);
  return repository.getTodayHabits();
});

class HabitCheckinNotifier extends StateNotifier<AsyncValue<List<HabitCheckin>>> {
  final HabitCheckinWidgetRepository _repository;

  HabitCheckinNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await _repository.getTodayHabits();
      state = AsyncValue.data(habits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleCheckin(int habitId, bool completed) async {
    try {
      await _repository.toggleCheckin(habitId, completed);
      await _loadHabits();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addHabit(String name) async {
    try {
      await _repository.addHabit(name);
      await _loadHabits();
    } catch (e) {
      rethrow;
    }
  }
}

final habitCheckinNotifierProvider = StateNotifierProvider<HabitCheckinNotifier, AsyncValue<List<HabitCheckin>>>((ref) {
  return HabitCheckinNotifier(ref.watch(habitCheckinRepositoryProvider));
});