import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/local_db.dart';
import 'providers/lyrics_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = LocalDb();
  await db.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(db)),
        ChangeNotifierProvider(create: (_) => LyricsProvider(db)),
      ],
      child: const LyricsMeApp(),
    ),
  );
}

class LyricsMeApp extends StatelessWidget {
  const LyricsMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<SettingsProvider, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'LyricsMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: const HomeScreen(),
    );
  }
}
