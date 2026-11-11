import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers/lyrics_provider.dart';
import '../providers/settings_provider.dart';
import '../services/import_flow.dart';
import '../widgets/app_logo.dart';
import '../widgets/export_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget header(String label) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(label.toUpperCase(),
              style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant, letterSpacing: 1.2)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('System')),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light')),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
          ),
          header('Backup'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export all lyrics'),
            subtitle: const Text('JSON backup or TXT files in a zip'),
            onTap: () =>
                showExportSheet(context, context.read<LyricsProvider>().all),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import JSON backup'),
            subtitle: const Text('Adds songs, never overwrites existing ones'),
            onTap: () => runImportFlow(context),
          ),
          header('About'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              final v = snap.data;
              return ListTile(
                leading: const AppLogo(size: 36),
                title: const Text('LyricsMe'),
                subtitle: Text(v == null
                    ? 'Version …'
                    : 'Version ${v.version} (${v.buildNumber})'),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Text(
              'Your personal lyrics notebook. Everything stays on this device — '
              'no account, no cloud.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
