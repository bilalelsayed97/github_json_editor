import 'package:go_router/go_router.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/json_editor_page.dart';
import '../../presentation/pages/settings_page.dart';

class AppRouter {
  static const String home = '/';
  static const String jsonEditor = '/json-editor';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: jsonEditor,
        builder: (context, state) {
          final filePath = state.uri.queryParameters['filePath'] ?? '';
          final fileName = state.uri.queryParameters['fileName'] ?? '';
          final sha = state.uri.queryParameters['sha'] ?? '';
          return JsonEditorPage(
            filePath: filePath,
            fileName: fileName,
            sha: sha,
          );
        },
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}