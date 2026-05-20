import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/app/theme/app_theme.dart';
import 'package:thing_note/app/theme/locale_provider.dart';
import 'package:thing_note/app/theme/theme_provider.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: AppTheme.softCardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.brightness_6),
                  title: Text(AppLocalizations.of(context)!.themeMode),
                  subtitle: Text(_themeModeLabel(context, themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemePicker(context, ref, themeMode),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.language),
                  title: Text(AppLocalizations.of(context)!.language),
                  subtitle: Text(_localeLabel(context, ref)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLocalePicker(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppTheme.softCardDecoration(context),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.folder_zip),
              title: Text(AppLocalizations.of(context)!.viewBackupZips),
              subtitle: Text(AppLocalizations.of(context)!.viewBackupZipsDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/backups'),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppTheme.softCardDecoration(
              context,
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                AppLocalizations.of(context)!.clearAllData,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => _showClearDataDialog(context, ref),
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              AppLocalizations.of(context)!.version('0.0.6'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _localeLabel(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    if (locale == null) return l10n.languageSystem;
    if (locale.languageCode == 'zh') return l10n.languageChinese;
    return l10n.languageEnglish;
  }

  void _showLocalePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.selectLanguage),
        children: [
          _buildLocaleOption(ctx, ref, null, l10n.languageSystem, current),
          _buildLocaleOption(ctx, ref, const Locale('zh', 'CN'), l10n.languageChinese, current),
          _buildLocaleOption(ctx, ref, const Locale('en', 'US'), l10n.languageEnglish, current),
        ],
      ),
    );
  }

  SimpleDialogOption _buildLocaleOption(
    BuildContext ctx, WidgetRef ref, Locale? locale, String label, Locale? current) {
    return SimpleDialogOption(
      onPressed: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.pop(ctx);
      },
      child: Row(
        children: [
          Radio<Locale?>(
            value: locale,
            groupValue: current,
            onChanged: (_) {
              ref.read(localeProvider.notifier).setLocale(locale);
              Navigator.pop(ctx);
            },
          ),
          Text(label),
        ],
      ),
    );
  }

  String _themeModeLabel(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.system:
        return l10n.themeModeSystem;
      case ThemeMode.light:
        return l10n.themeModeLight;
      case ThemeMode.dark:
        return l10n.themeModeDark;
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppLocalizations.of(ctx)!.selectTheme),
        children: ThemeMode.values.map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Radio<ThemeMode>(
                  value: mode,
                  groupValue: current,
                  onChanged: (_) {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    Navigator.pop(ctx);
                  },
                ),
                Text(_themeModeLabel(ctx, mode)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.confirmClear),
        content: Text(AppLocalizations.of(ctx)!.confirmClearData),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(recordRepositoryProvider).deleteAll();
              ref.invalidate(recordListProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.allDataCleared)),
                );
              }
            },
            child: Text(AppLocalizations.of(ctx)!.confirmClearBtn),
          ),
        ],
      ),
    );
  }
}