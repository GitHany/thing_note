import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 自定义主题配置
class CustomThemeConfig {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;
  final Brightness brightness;

  const CustomThemeConfig({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
    this.brightness = Brightness.light,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'primaryColor': primaryColor.value,
        'secondaryColor': secondaryColor.value,
        'backgroundColor': backgroundColor.value,
        'surfaceColor': surfaceColor.value,
        'textColor': textColor.value,
        'accentColor': accentColor.value,
        'brightness': brightness.name,
      };

  factory CustomThemeConfig.fromJson(Map<String, dynamic> json) {
    return CustomThemeConfig(
      name: json['name'] as String,
      primaryColor: Color(json['primaryColor'] as int),
      secondaryColor: Color(json['secondaryColor'] as int),
      backgroundColor: Color(json['backgroundColor'] as int),
      surfaceColor: Color(json['surfaceColor'] as int),
      textColor: Color(json['textColor'] as int),
      accentColor: Color(json['accentColor'] as int),
      brightness: Brightness.values.firstWhere(
        (b) => b.name == json['brightness'],
        orElse: () => Brightness.light,
      ),
    );
  }
}

/// 预设主题
class PresetThemes {
  static const CustomThemeConfig ocean = CustomThemeConfig(
    name: '海洋',
    primaryColor: Color(0xFF1976D2),
    secondaryColor: Color(0xFF64B5F6),
    backgroundColor: Color(0xFFF5F9FC),
    surfaceColor: Colors.white,
    textColor: Color(0xFF212121),
    accentColor: Color(0xFF00BCD4),
  );

  static const CustomThemeConfig forest = CustomThemeConfig(
    name: '森林',
    primaryColor: Color(0xFF388E3C),
    secondaryColor: Color(0xFF81C784),
    backgroundColor: Color(0xFFF1F8E9),
    surfaceColor: Colors.white,
    textColor: Color(0xFF212121),
    accentColor: Color(0xFF8BC34A),
  );

  static const CustomThemeConfig sunset = CustomThemeConfig(
    name: '日落',
    primaryColor: Color(0xFFFF7043),
    secondaryColor: Color(0xFFFFAB91),
    backgroundColor: Color(0xFFFFF3E0),
    surfaceColor: Colors.white,
    textColor: Color(0xFF212121),
    accentColor: Color(0xFFFFCA28),
  );

  static const CustomThemeConfig purple = CustomThemeConfig(
    name: '紫罗兰',
    primaryColor: Color(0xFF7B1FA2),
    secondaryColor: Color(0xFFBA68C8),
    backgroundColor: Color(0xFFF3E5F5),
    surfaceColor: Colors.white,
    textColor: Color(0xFF212121),
    accentColor: Color(0xFFE91E63),
  );

  static const CustomThemeConfig midnight = CustomThemeConfig(
    name: '午夜',
    primaryColor: Color(0xFF5C6BC0),
    secondaryColor: Color(0xFF9FA8DA),
    backgroundColor: Color(0xFF1A1A2E),
    surfaceColor: Color(0xFF16213E),
    textColor: Color(0xFFE0E0E0),
    accentColor: Color(0xFF00D9FF),
    brightness: Brightness.dark,
  );

  static const CustomThemeConfig darkForest = CustomThemeConfig(
    name: '暗夜森林',
    primaryColor: Color(0xFF2E7D32),
    secondaryColor: Color(0xFF66BB6A),
    backgroundColor: Color(0xFF1B2B1C),
    surfaceColor: Color(0xFF243324),
    textColor: Color(0xFFE8F5E9),
    accentColor: Color(0xFFA5D6A7),
    brightness: Brightness.dark,
  );

  static List<CustomThemeConfig> get all => [
        ocean,
        forest,
        sunset,
        purple,
        midnight,
        darkForest,
      ];
}

/// 主题服务
class ThemeService {
  static const String _currentThemeKey = 'current_theme';
  static const String _customThemesKey = 'custom_themes';
  static const String _themeModeKey = 'theme_mode';

  Future<void> saveTheme(CustomThemeConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final json = config.toJson();
    await prefs.setString(_currentThemeKey, json.toString());
  }

  Future<CustomThemeConfig?> getCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_currentThemeKey);
    if (jsonStr == null) return null;
    // 简单的解析，实际应该用更好的方式
    return null;
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  Future<void> saveCustomTheme(CustomThemeConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final themes = await _getCustomThemes();
    final index = themes.indexWhere((t) => t.name == config.name);
    if (index >= 0) {
      themes[index] = config;
    } else {
      themes.add(config);
    }
    await prefs.setString(_customThemesKey, themes.length.toString());
  }

  Future<List<CustomThemeConfig>> _getCustomThemes() async {
    // 简化实现
    return [];
  }
}

final themeServiceProvider = Provider<ThemeService>((ref) => ThemeService());

/// 主题状态
class ThemeState {
  final CustomThemeConfig currentTheme;
  final List<CustomThemeConfig> customThemes;
  final ThemeMode mode;

  const ThemeState({
    required this.currentTheme,
    this.customThemes = const [],
    this.mode = ThemeMode.system,
  });

  ThemeState copyWith({
    CustomThemeConfig? currentTheme,
    List<CustomThemeConfig>? customThemes,
    ThemeMode? mode,
  }) {
    return ThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      customThemes: customThemes ?? this.customThemes,
      mode: mode ?? this.mode,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState(currentTheme: PresetThemes.ocean)) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    // 加载保存的主题
  }

  void setTheme(CustomThemeConfig theme) {
    state = state.copyWith(currentTheme: theme);
  }

  void setMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
  }

  void addCustomTheme(CustomThemeConfig theme) {
    final themes = List<CustomThemeConfig>.from(state.customThemes)..add(theme);
    state = state.copyWith(customThemes: themes);
  }
}

final themeStateProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// 主题选择界面
class ThemeSelectorScreen extends ConsumerWidget {
  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: '主题模式',
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'light', label: Text('浅色')),
                ButtonSegment(value: 'dark', label: Text('深色')),
                ButtonSegment(value: 'system', label: Text('跟随系统')),
              ],
              selected: {themeState.mode.name},
              onSelectionChanged: (selected) {
                ref.read(themeStateProvider.notifier).setMode(
                      ThemeMode.values.firstWhere((m) => m.name == selected.first),
                    );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: '预设主题',
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: PresetThemes.all.length,
              itemBuilder: (context, index) {
                final theme = PresetThemes.all[index];
                return _ThemeCard(
                  theme: theme,
                  isSelected: themeState.currentTheme.name == theme.name,
                  onTap: () => ref.read(themeStateProvider.notifier).setTheme(theme),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: '自定义主题',
            child: ElevatedButton.icon(
              onPressed: () => _showCustomThemeDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('创建自定义主题'),
            ),
          ),
          if (themeState.customThemes.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...themeState.customThemes.map((theme) => _ThemeCard(
                  theme: theme,
                  isSelected: themeState.currentTheme.name == theme.name,
                  onTap: () => ref.read(themeStateProvider.notifier).setTheme(theme),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  void _showCustomThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _CustomThemeDialog(),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final CustomThemeConfig theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.primaryColor, theme.secondaryColor],
                  ),
                ),
                child: Center(
                  child: Text(
                    theme.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ColorDot(color: theme.primaryColor),
                  _ColorDot(color: theme.secondaryColor),
                  _ColorDot(color: theme.accentColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!),
      ),
    );
  }
}

class _CustomThemeDialog extends StatefulWidget {
  const _CustomThemeDialog();

  @override
  State<_CustomThemeDialog> createState() => _CustomThemeDialogState();
}

class _CustomThemeDialogState extends State<_CustomThemeDialog> {
  final _nameController = TextEditingController();
  final Color _primaryColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建自定义主题'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '主题名称'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('主色调: '),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _pickColor(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            // 创建自定义主题
            Navigator.pop(context);
          },
          child: const Text('创建'),
        ),
      ],
    );
  }

  void _pickColor() {
    // 显示颜色选择器
  }
}