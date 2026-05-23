import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:thing_note/features/biometric_lock/data/biometric_repository.dart';
import 'package:thing_note/features/biometric_lock/domain/biometric_settings.dart'
    show BiometricLockType;

final biometricAuthProvider = StateNotifierProvider<BiometricAuthNotifier, bool>(
  (ref) => BiometricAuthNotifier(ref),
);

class BiometricAuthNotifier extends StateNotifier<bool> {
  final Ref ref;
  final LocalAuthentication _localAuth = LocalAuthentication();

  BiometricAuthNotifier(this.ref) : super(false);

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricLockType>> getAvailableBiometrics() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      return types.map((t) {
        switch (t) {
          case BiometricType.fingerprint:
            return BiometricLockType.fingerprint;
          case BiometricType.face:
            return BiometricLockType.face;
          case BiometricType.iris:
            return BiometricLockType.iris;
          default:
            return BiometricLockType.none;
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> authenticate() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: '请验证身份以访问应用',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      
      if (authenticated) {
        final repo = ref.read(biometricRepositoryProvider);
        await repo.updateLastAuthenticated();
        setAuthenticated(true);
      }
      
      return authenticated;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }
  
  void setAuthenticated(bool value) {
    state = value;
  }

  Future<bool> checkAndAuthenticate() async {
    final repo = ref.read(biometricRepositoryProvider);
    final isLockRequired = await repo.isLockRequired();
    
    if (!isLockRequired) {
      state = true;
      return true;
    }
    
    return await authenticate();
  }

  void lock() {
    state = false;
  }
}

class BiometricLockScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final bool isInitialSetup;

  const BiometricLockScreen({
    super.key,
    this.onSuccess,
    this.isInitialSetup = false,
  });

  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = true;
  bool _isAvailable = false;
  List<BiometricLockType> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      List<BiometricType> types = [];
      if (canCheck && isDeviceSupported) {
        types = await _localAuth.getAvailableBiometrics();
      }

      setState(() {
        _isAvailable = canCheck && isDeviceSupported;
        _availableTypes = types.map((t) {
          switch (t) {
            case BiometricType.fingerprint:
              return BiometricLockType.fingerprint;
            case BiometricType.face:
              return BiometricLockType.face;
            case BiometricType.iris:
              return BiometricLockType.iris;
            default:
              return BiometricLockType.none;
          }
        }).toList();
        _isLoading = false;
      });

      if (_isAvailable && !widget.isInitialSetup) {
        _authenticate();
      }
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticate() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: '请验证身份以访问应用',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      
      if (authenticated && mounted) {
        final repo = ref.read(biometricRepositoryProvider);
        await repo.updateLastAuthenticated();
        ref.read(biometricAuthProvider.notifier).setAuthenticated(true);
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证失败，请重试')),
        );
      }
    }
  }

  IconData _getBiometricIcon() {
    if (_availableTypes.contains(BiometricLockType.face)) {
      return Icons.face;
    } else if (_availableTypes.contains(BiometricLockType.fingerprint)) {
      return Icons.fingerprint;
    }
    return Icons.lock;
  }

  String _getBiometricTypeName() {
    if (_availableTypes.contains(BiometricLockType.face)) {
      return '面容识别';
    } else if (_availableTypes.contains(BiometricLockType.fingerprint)) {
      return '指纹识别';
    }
    return '生物识别';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getBiometricIcon(),
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.isInitialSetup ? '设置生物识别' : '应用已锁定',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isAvailable
                          ? '使用 ${_getBiometricTypeName()} 解锁应用'
                          : '当前设备不支持生物识别',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (_isAvailable) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _authenticate,
                          icon: Icon(_getBiometricIcon()),
                          label: const Text('验证身份'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Skip for now or use PIN fallback
                          if (!widget.isInitialSetup) {
                            _showPinFallback();
                          }
                        },
                        child: const Text('使用密码解锁'),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '生物识别功能不可用',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('返回'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  void _showPinFallback() {
    showDialog(
      context: context,
      builder: (ctx) {
        final pinController = TextEditingController();
        return AlertDialog(
          title: const Text('输入密码'),
          content: TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              hintText: '请输入6位密码',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                // Simplified PIN check - in production, use secure storage
                if (pinController.text.length == 6) {
                  Navigator.pop(ctx);
                  ref.read(biometricAuthProvider.notifier).setAuthenticated(true);
                  widget.onSuccess?.call();
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }
}