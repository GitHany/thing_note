import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/app/app.dart';
import 'package:thing_note/core/database/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(databaseProvider.future);

  runApp(UncontrolledProviderScope(
    container: container,
    child: const ThingNoteApp(),
  ));
}
