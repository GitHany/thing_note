import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:thing_note/core/utils/file_storage.dart';
import 'package:thing_note/features/media/presentation/widgets/photo_picker.dart';
import 'package:thing_note/features/media/presentation/widgets/audio_recorder.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record/presentation/widgets/timer_widget.dart';
import 'package:thing_note/features/record/presentation/widgets/note_input.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  bool _isRecording = false;
  bool _hasReminder = false;
  bool _isDataLoaded = true;
  DateTime? _originalCreatedAt;
  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isLocating = false;
  List<String> _videoPaths = [];

  DateTime _initialOccurredAt = DateTime.now();
  int _initialDurationSec = 0;
  String _initialNote = '';
  List<String> _initialPhotoPaths = [];
  List<String> _initialAudioPaths = [];
  List<int> _initialAudioDurationsSec = [];
  int? _initialThingNameId;
  bool _initialHasReminder = false;
  double? _initialLatitude;
  double? _initialLongitude;
  String? _initialAddress;
  List<String> _initialVideoPaths = [];

  @override
  void initState() {
    super.initState();
    if (widget.recordId != null) {
      _isEditing = true;
      _isDataLoaded = false;
      _loadRecord();
    }
    _noteController.addListener(_onNoteChanged);
  }

  void _onNoteChanged() {
    _checkChanged();
  }

  void _checkChanged() {
    if (!_isEditing) {
      final hasData = _noteController.text.isNotEmpty ||
          _durationSec > 0 ||
          _photoPaths.isNotEmpty ||
          _audioPaths.isNotEmpty ||
          _videoPaths.isNotEmpty ||
          _thingNameId != null ||
          _hasReminder;

      if (hasData != _isChanged) {
        setState(() => _isChanged = hasData);
      }
      return;
    }

    final changed = _occurredAt != _initialOccurredAt ||
        _durationSec != _initialDurationSec ||
        _noteController.text != _initialNote ||
        _thingNameId != _initialThingNameId ||
        _hasReminder != _initialHasReminder ||
        _latitude != _initialLatitude ||
        _longitude != _initialLongitude ||
        _address != _initialAddress ||
        !_listEquals(_photoPaths, _initialPhotoPaths) ||
        !_listEquals(_audioPaths, _initialAudioPaths) ||
        !_listEquals(_videoPaths, _initialVideoPaths) ||
        !_intListEquals(_audioDurationsSec, _initialAudioDurationsSec);

    if (changed != _isChanged) {
      setState(() => _isChanged = changed);
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _intListEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    if (!_isChanged) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.unsavedChanges),
        content: Text(AppLocalizations.of(ctx)!.unsavedChangesDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx)!.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx)!.discard),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _loadRecord() async {
    try {
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
          _hasReminder = record.hasReminder;
          _originalCreatedAt = record.createdAt;
          _latitude = record.latitude;
          _longitude = record.longitude;
          _address = record.address;
          _videoPaths = List.from(record.videoPaths);
          _initialOccurredAt = record.occurredAt;
          _initialDurationSec = record.durationSec;
          _initialNote = record.note;
          _initialPhotoPaths = List.from(record.photoPaths);
          _initialAudioPaths = List.from(record.audioPaths);
          _initialAudioDurationsSec = List.from(record.audioDurationsSec);
          _initialThingNameId = record.thingNameId;
          _initialHasReminder = record.hasReminder;
          _initialLatitude = record.latitude;
          _initialLongitude = record.longitude;
          _initialAddress = record.address;
          _initialVideoPaths = List.from(record.videoPaths);
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loadFailed(e.toString()))),
        );
        Navigator.pop(context);
      }
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
      final appDirPath = (await FileStorage.appDocumentsDirectory).path;

      final List<String> savedPhotoPaths = [];
      for (final path in _photoPaths) {
        final file = File(path);
        if (await file.exists()) {
          if (path.startsWith(appDirPath)) {
            savedPhotoPaths.add(path);
          } else {
            final savedPath = await FileStorage.savePhotoFile(path);
            savedPhotoPaths.add(savedPath);
          }
        }
      }

      final List<String> savedAudioPaths = [];
      for (final path in _audioPaths) {
        final file = File(path);
        if (await file.exists()) {
          if (path.startsWith(appDirPath)) {
            savedAudioPaths.add(path);
          } else {
            final savedPath = await FileStorage.saveAudioFile(path);
            savedAudioPaths.add(savedPath);
          }
        }
      }

      final List<String> savedVideoPaths = [];
      for (final path in _videoPaths) {
        final file = File(path);
        if (await file.exists()) {
          if (path.startsWith(appDirPath)) {
            savedVideoPaths.add(path);
          } else {
            final savedPath = await FileStorage.saveVideoFile(path);
            savedVideoPaths.add(savedPath);
          }
        }
      }

      int? thingNameId = _thingNameId;
      if (!_isEditing && thingNameId == null) {
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
        videoPaths: savedVideoPaths,
        thingNameId: thingNameId,
        hasReminder: _hasReminder,
        latitude: _latitude,
        longitude: _longitude,
        address: _address,
        createdAt: _originalCreatedAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await ref.read(recordNotifierProvider.notifier).update(record);
        ref.invalidate(recordDetailProvider(widget.recordId!));
      } else {
        await ref.read(recordNotifierProvider.notifier).create(record);
      }

      ref.invalidate(recordListProvider);
      ref.invalidate(reminderCountProvider);
      ref.invalidate(reminderRecordsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.save),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saveFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thingNamesAsync = ref.watch(thingNameListProvider);

    if (!_isDataLoaded) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.editRecord),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isEditing ? AppLocalizations.of(context)!.editRecord : AppLocalizations.of(context)!.newRecord),
              if (_isRecording) ...[
                const SizedBox(width: 8),
                const _PulseIndicator(color: Colors.red),
              ],
            ],
          ),
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
                  : Text(AppLocalizations.of(context)!.save),
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
                title: Text(AppLocalizations.of(context)!.occurredAt),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(_occurredAt),
                ),
                onTap: () => _pickDateTime(),
              ),
              const SizedBox(height: 8),
              thingNamesAsync.when(
                loading: () => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.category),
                  title: Text(AppLocalizations.of(context)!.thingName),
                  subtitle: Text(AppLocalizations.of(context)!.loading),
                ),
                error: (error, stack) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.category),
                  title: Text(AppLocalizations.of(context)!.thingName),
                  subtitle: Text(AppLocalizations.of(context)!.loadFailed(error.toString())),
                ),
                data: (thingNames) {
                  ThingName? selectedName;
                  for (final name in thingNames) {
                    if (name.id == _thingNameId) {
                      selectedName = name;
                      break;
                    }
                  }
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.category),
                    title: Text(AppLocalizations.of(context)!.thingName),
                    subtitle: Text(selectedName?.name ?? AppLocalizations.of(context)!.pleaseSelect),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.alarm),
                title: Text(AppLocalizations.of(context)!.reminder),
                value: _hasReminder,
                onChanged: (value) {
                  setState(() => _hasReminder = value);
                  _checkChanged();
                },
              ),
              const SizedBox(height: 16),
              _LocationPicker(
                address: _address,
                isLocating: _isLocating,
                onGetCurrentLocation: _getCurrentLocation,
                onManualInput: _showManualInputDialog,
                onClear: () {
                  setState(() {
                    _latitude = null;
                    _longitude = null;
                    _address = null;
                  });
                  _checkChanged();
                },
              ),
              const SizedBox(height: 16),
              PhotoPickerSection(
                initialPaths: _photoPaths,
                onPathsChanged: (paths) {
                  setState(() => _photoPaths = paths);
                  _checkChanged();
                },
              ),
              const SizedBox(height: 16),
              VideoPickerSection(
                initialPaths: _videoPaths,
                onPathsChanged: (paths) {
                  setState(() => _videoPaths = paths);
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
                onRecordingStateChanged: (isRecording) {
                  setState(() => _isRecording = isRecording);
                },
              ),
              const SizedBox(height: 16),
              NoteInput(controller: _noteController),
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

    final time = await _showCupertinoTimePicker(_occurredAt);
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
    _checkChanged();
  }

  Future<TimeOfDay?> _showCupertinoTimePicker(DateTime initialTime) async {
    TimeOfDay? selectedTime = TimeOfDay.fromDateTime(initialTime);

    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 260,
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(AppLocalizations.of(ctx)!.cancel),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  CupertinoButton(
                    child: Text(AppLocalizations.of(ctx)!.confirm),
                    onPressed: () => Navigator.pop(ctx, selectedTime),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: initialTime,
                  onDateTimeChanged: (dateTime) {
                    selectedTime = TimeOfDay.fromDateTime(dateTime);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    return result;
  }

  Future<void> _showThingNamePicker(List<ThingName> thingNames) async {
    final result = await showDialog<int?>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        String searchQuery = '';
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(dialogContext)!.selectThingName),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
            body: StatefulBuilder(
              builder: (context, setModalState) {
                final filtered = searchQuery.isEmpty
                    ? thingNames
                    : thingNames
                        .where((t) => t.name.contains(searchQuery))
                        .toList();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.searchThingName,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() => searchQuery = value);
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: Text(AppLocalizations.of(context)!.doNotSelect),
                      onTap: () => Navigator.pop(dialogContext, null),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(context)!.noMatchResult,
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
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final thingName = filtered[index];
                                return ListTile(
                                  title: Text(thingName.name),
                                  onTap: () =>
                                      Navigator.pop(dialogContext, thingName.id),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _thingNameId = result);
      _checkChanged();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.locationFailed('GPS is disabled'))),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.locationPermissionDenied)),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.locationPermissionDenied)),
          );
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 10),
            ),
          );
        }
      }

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.locationFailed('Failed to get location'))),
          );
        }
        return;
      }

      final pos = position!;

      String? addressText;
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude, pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
            if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) p.thoroughfare!,
            if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) p.subThoroughfare!,
            if (p.name != null && p.name!.isNotEmpty) p.name!,
          ];
          addressText = parts.where((s) => s.isNotEmpty).join('');
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _address = addressText ?? '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
        });
        _checkChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.locationFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _showManualInputDialog() async {
    final controller = TextEditingController(text: _address ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.manualInput),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(ctx)!.addressHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(AppLocalizations.of(ctx)!.confirm),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty && mounted) {
      setState(() {
        _address = result.trim();
        _latitude = null;
        _longitude = null;
      });
      _checkChanged();
    }
  }
}

class _PulseIndicator extends StatefulWidget {
  final Color color;
  const _PulseIndicator({required this.color});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.3).animate(_controller),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _LocationPicker extends StatelessWidget {
  final String? address;
  final bool isLocating;
  final VoidCallback onGetCurrentLocation;
  final VoidCallback onManualInput;
  final VoidCallback onClear;

  const _LocationPicker({
    required this.address,
    required this.isLocating,
    required this.onGetCurrentLocation,
    required this.onManualInput,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.location,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (address != null)
          Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    address!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                  tooltip: AppLocalizations.of(context)!.clearLocation,
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Row(
            children: [
              if (isLocating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(AppLocalizations.of(context)!.getCurrentLocation),
                  onPressed: onGetCurrentLocation,
                ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_location_alt, size: 18),
                label: Text(AppLocalizations.of(context)!.manualInput),
                onPressed: isLocating ? null : onManualInput,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
