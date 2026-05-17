import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/utils/file_storage.dart';
import 'package:thing_note/features/media/presentation/widgets/photo_picker.dart';
import 'package:thing_note/features/media/presentation/widgets/audio_recorder.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record/presentation/widgets/timer_widget.dart';
import 'package:thing_note/features/record/presentation/widgets/note_input.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';

class RecordFormScreen extends ConsumerStatefulWidget {
  final int? recordId;

  const RecordFormScreen({super.key, this.recordId});

  @override
  ConsumerState<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends ConsumerState<RecordFormScreen> {
  final _noteController = TextEditingController();
  DateTime _occurredAt = DateTime.now();
  int _durationSec = 0;
  List<String> _photoPaths = [];
  List<String> _audioPaths = [];
  List<int> _audioDurationsSec = [];
  int? _thingNameId;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isChanged = false;
  final GlobalKey<AudioRecorderSectionState> _audioRecorderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.recordId != null) {
      _isEditing = true;
      _loadRecord();
    }
    _noteController.addListener(_onNoteChanged);
  }

  void _onNoteChanged() {
    _checkChanged();
  }

  void _checkChanged() {
    if (_isEditing) return;

    final hasData = _noteController.text.isNotEmpty ||
        _durationSec > 0 ||
        _photoPaths.isNotEmpty ||
        _audioPaths.isNotEmpty ||
        _thingNameId != null;

    if (hasData != _isChanged) {
      setState(() {
        _isChanged = hasData;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isChanged && !_isEditing) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认离开'),
        content: const Text('您有未保存的更改，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('离开'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _loadRecord() async {
    final record = await ref.read(recordDetailProvider(widget.recordId!).future);
    if (record != null && mounted) {
      setState(() {
        _occurredAt = record.occurredAt;
        _durationSec = record.durationSec;
        _noteController.text = record.note;
        _photoPaths = List.from(record.photoPaths);
        _audioPaths = List.from(record.audioPaths);
        _audioDurationsSec = List.from(record.audioDurationsSec);
        _thingNameId = record.thingNameId;
      });
    }
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _stopRecordingIfNeeded() async {
    final audioRecorderState = _audioRecorderKey.currentState;
    if (audioRecorderState != null && audioRecorderState.isRecording) {
      await audioRecorderState.stopRecording();
    }
  }

  Future<void> _save() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _stopRecordingIfNeeded();

      final now = DateTime.now();

      List<String> savedPhotoPaths = [];
      for (final path in _photoPaths) {
        final file = File(path);
        if (await file.exists()) {
          if (path.contains((await FileStorage.appDocumentsDirectory).path)) {
            savedPhotoPaths.add(path);
          } else {
            final savedPath = await FileStorage.savePhotoFile(path);
            savedPhotoPaths.add(savedPath);
          }
        }
      }

      List<String> savedAudioPaths = [];
      for (final path in _audioPaths) {
        final file = File(path);
        if (await file.exists()) {
          if (path.contains((await FileStorage.appDocumentsDirectory).path)) {
            savedAudioPaths.add(path);
          } else {
            final savedPath = await FileStorage.saveAudioFile(path);
            savedAudioPaths.add(savedPath);
          }
        }
      }

      int? thingNameId = _thingNameId;
      if (thingNameId == null) {
        final defaultThingName = await ref.read(defaultThingNameProvider.future);
        thingNameId = defaultThingName?.id;
      }

      final record = EpisodeRecord(
        id: widget.recordId,
        occurredAt: _occurredAt,
        durationSec: _durationSec,
        note: _noteController.text,
        photoPaths: savedPhotoPaths,
        audioPaths: savedAudioPaths,
        audioDurationsSec: _audioDurationsSec,
        thingNameId: thingNameId,
        createdAt: _isEditing ? now : now,
        updatedAt: now,
      );

      if (_isEditing) {
        await ref.read(recordNotifierProvider.notifier).update(record);
      } else {
        await ref.read(recordNotifierProvider.notifier).create(record);
      }

      ref.invalidate(recordListProvider);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thingNamesAsync = ref.watch(thingNameListProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? '编辑记录' : '新建记录'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('发生时间'),
                subtitle: Text(
                  '${_occurredAt.year}年${_occurredAt.month}月${_occurredAt.day}日 ${_occurredAt.hour.toString().padLeft(2, '0')}:${_occurredAt.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () => _pickDateTime(),
              ),
              const SizedBox(height: 8),
              thingNamesAsync.when(
                loading: () => const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.category),
                  title: Text('事件名称'),
                  subtitle: Text('加载中...'),
                ),
                error: (error, stack) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.category),
                  title: const Text('事件名称'),
                  subtitle: Text('加载失败: $error'),
                ),
                data: (thingNames) {
                  ThingName? selectedName;
                  try {
                    selectedName = thingNames.firstWhere(
                      (name) => name.id == _thingNameId,
                    );
                  } catch (_) {
                    selectedName = null;
                  }
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.category),
                    title: const Text('事件名称'),
                    subtitle: Text(selectedName?.name ?? '请选择'),
                    onTap: () => _showThingNamePicker(thingNames),
                  );
                },
              ),
              const SizedBox(height: 8),
              TimerWidget(
                initialDuration: Duration(seconds: _durationSec),
                onDurationChanged: (duration) {
                  setState(() => _durationSec = duration.inSeconds);
                  _checkChanged();
                },
              ),
              const SizedBox(height: 16),
              NoteInput(controller: _noteController),
              const SizedBox(height: 16),
              PhotoPickerSection(
                initialPaths: _photoPaths,
                onPathsChanged: (paths) {
                  setState(() => _photoPaths = paths);
                  _checkChanged();
                },
              ),
              const SizedBox(height: 16),
              AudioRecorderSection(
                key: _audioRecorderKey,
                initialAudioPaths: _audioPaths,
                initialAudioDurationsSec: _audioDurationsSec,
                onAudioChanged: (paths, durationsSec) {
                  setState(() {
                    _audioPaths = paths;
                    _audioDurationsSec = durationsSec;
                  });
                  _checkChanged();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _showThingNamePicker(List<ThingName> thingNames) async {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.5;
    
    final result = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = searchQuery.isEmpty
                ? thingNames
                : thingNames
                    .where((t) => t.name.contains(searchQuery))
                    .toList();
            return Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '搜索事件名称',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setModalState(() => searchQuery = value);
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('不选择'),
                      onTap: () => Navigator.pop(context, null),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                '无匹配结果',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline,
                                    ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final thingName = filtered[index];
                                return ListTile(
                                  title: Text(thingName.name),
                                  onTap: () =>
                                      Navigator.pop(context, thingName.id),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() => _thingNameId = result);
      _checkChanged();
    }
  }
}