import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/custom_theme/data/custom_theme_repository.dart';
import 'package:thing_note/features/custom_theme/domain/custom_theme.dart';

final customThemeRepositoryProvider = Provider((ref) => CustomThemeRepository(ref));

final allThemesProvider = FutureProvider<List<CustomTheme>>((ref) async {
  final repo = ref.read(customThemeRepositoryProvider);
  return repo.getAllThemes();
});

final activeThemeProvider = FutureProvider<CustomTheme?>((ref) async {
  final repo = ref.read(customThemeRepositoryProvider);
  return repo.getActiveTheme();
});