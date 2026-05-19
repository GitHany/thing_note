import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/record/presentation/record_list_screen.dart';
import 'package:thing_note/features/record/presentation/record_form_screen.dart';
import 'package:thing_note/features/record/presentation/record_detail_screen.dart';
import 'package:thing_note/features/settings/presentation/settings_screen.dart';
import 'package:thing_note/features/thing_name/presentation/thing_name_manage_screen.dart';
import 'package:thing_note/features/thing_name/presentation/thing_name_detail_screen.dart';
import 'package:thing_note/features/export/presentation/backup_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _buildPageWithTransition({
  required LocalKey key,
  required Widget child,
  bool slideFromRight = true,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!slideFromRight) return child;
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RecordListScreen(),
          slideFromRight: false,
        ),
      ),
      GoRoute(
        path: '/record/new',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RecordFormScreen(),
        ),
      ),
      GoRoute(
        path: '/record/:id',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _buildPageWithTransition(
            key: state.pageKey,
            child: RecordDetailScreen(recordId: id),
          );
        },
      ),
      GoRoute(
        path: '/record/:id/edit',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _buildPageWithTransition(
            key: state.pageKey,
            child: RecordFormScreen(recordId: id),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/backups',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const BackupListScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/thing-names',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ThingNameManageScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/thing-names/:id',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _buildPageWithTransition(
            key: state.pageKey,
            child: ThingNameDetailScreen(thingNameId: id),
          );
        },
      ),
    ],
  );
});
