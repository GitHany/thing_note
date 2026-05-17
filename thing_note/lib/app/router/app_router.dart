import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/record/presentation/record_list_screen.dart';
import 'package:thing_note/features/record/presentation/record_form_screen.dart';
import 'package:thing_note/features/record/presentation/record_detail_screen.dart';
import 'package:thing_note/features/settings/presentation/settings_screen.dart';
import 'package:thing_note/features/thing_name/presentation/thing_name_manage_screen.dart';
import 'package:thing_note/features/thing_name/presentation/thing_name_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RecordListScreen(),
      ),
      GoRoute(
        path: '/record/new',
        builder: (context, state) => const RecordFormScreen(),
      ),
      GoRoute(
        path: '/record/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return RecordDetailScreen(recordId: id);
        },
      ),
      GoRoute(
        path: '/record/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return RecordFormScreen(recordId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/thing-names',
        builder: (context, state) => const ThingNameManageScreen(),
      ),
      GoRoute(
        path: '/settings/thing-names/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ThingNameDetailScreen(thingNameId: id);
        },
      ),
    ],
  );
});
