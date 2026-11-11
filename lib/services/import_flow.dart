import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lyrics_provider.dart';
import 'backup_service.dart';

/// Picks a JSON backup, merges it into the DB and reports the outcome.
Future<void> runImportFlow(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final provider = context.read<LyricsProvider>();
  try {
    final parsed = await BackupService.pickAndParse();
    if (parsed == null) return;
    if (parsed.valid.isEmpty) {
      messenger.showSnackBar(const SnackBar(
          content: Text('No valid lyrics found in that file.')));
      return;
    }
    final s = await provider.importBatch(parsed.valid, parsed.skipped);
    final parts = [
      'Imported ${s.added}',
      if (s.duplicates > 0) '${s.duplicates} already saved',
      if (s.skipped > 0) '${s.skipped} invalid skipped',
    ];
    messenger.showSnackBar(SnackBar(content: Text(parts.join(' · '))));
  } on FormatException catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text('Not a valid backup file: ${e.message}')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
  }
}
