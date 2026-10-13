import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/content_repository.dart';
import 'screens/splash_screen.dart';
import 'state/auth_state.dart';
import 'state/content_state.dart';
import 'state/progress_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final content = await ContentRepository.load(prefs);
  runApp(BugHunterApp(prefs: prefs, content: content));
}

class BugHunterApp extends StatelessWidget {
  const BugHunterApp({super.key, required this.prefs, required this.content});

  final SharedPreferences prefs;
  final ContentData content;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>(create: (_) => AuthState(prefs)),
        ChangeNotifierProvider<ContentState>(create: (_) => ContentState(prefs, content)),
        ChangeNotifierProvider<ProgressState>(
          create: (ctx) => ProgressState(prefs, ctx.read<AuthState>(), ctx.read<ContentState>()),
        ),
      ],
      child: MaterialApp(
        title: nazvanieProekta,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
