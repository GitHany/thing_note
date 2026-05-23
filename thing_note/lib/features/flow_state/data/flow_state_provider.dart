import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../domain/flow_state.dart';
import '../data/flow_state_repository.dart';

final flowStateProvider = StateNotifierProvider<FlowStateNotifier, FlowStateState>((ref) {
  return FlowStateNotifier(ref.watch(flowStateRepositoryProvider));
});

final flowStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(flowStateRepositoryProvider);
  return await repo.getTodayStats();
});

class FlowStateState {
  final List<FlowState> flowStates;
  final FlowState? activeFlow;
  final bool isLoading;
  final String? error;

  FlowStateState({
    this.flowStates = const [],
    this.activeFlow,
    this.isLoading = false,
    this.error,
  });

  FlowStateState copyWith({
    List<FlowState>? flowStates,
    FlowState? activeFlow,
    bool? isLoading,
    String? error,
  }) {
    return FlowStateState(
      flowStates: flowStates ?? this.flowStates,
      activeFlow: activeFlow,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FlowStateNotifier extends StateNotifier<FlowStateState> {
  final FlowStateRepository _repository;
  Timer? _timer;

  FlowStateNotifier(this._repository) : super(FlowStateState()) {
    loadFlowStates();
  }

  Future<void> loadFlowStates() async {
    state = state.copyWith(isLoading: true);
    try {
      final flows = await _repository.getRecent(50);
      final active = await _repository.getActiveFlowState();
      state = state.copyWith(flowStates: flows, activeFlow: active, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> startFlow({String? note}) async {
    final flow = FlowState(
      startedAt: DateTime.now(),
      note: note,
      createdAt: DateTime.now(),
    );
    final id = await _repository.insert(flow);
    final newFlow = flow.copyWith(id: id);
    state = state.copyWith(activeFlow: newFlow);
    _startTimer();
  }

  Future<void> endFlow({int focusRating = 0, int distractionCount = 0, String? note}) async {
    if (state.activeFlow == null) return;
    
    final endTime = DateTime.now();
    final duration = endTime.difference(state.activeFlow!.startedAt).inMinutes;
    
    final updatedFlow = state.activeFlow!.copyWith(
      endedAt: endTime,
      durationMinutes: duration,
      focusRating: focusRating,
      distractionCount: distractionCount,
      note: note,
    );
    
    await _repository.update(updatedFlow);
    _stopTimer();
    await loadFlowStates();
  }

  Future<void> recordDistraction() async {
    if (state.activeFlow == null) return;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Force refresh to show elapsed time
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}