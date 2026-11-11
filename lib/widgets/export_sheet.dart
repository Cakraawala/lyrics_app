import 'package:flutter/material.dart';

import '../models/song_lyric.dart';
import '../services/backup_service.dart';

/// Bottom sheet that asks for export format + destination, then exports.
Future<void> showExportSheet(BuildContext context, List<SongLyric> lyrics) async {
  if (lyrics.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Nothing to export yet.')));
    return;
  }
  final choice = await showModalBottomSheet<(ExportFormat, ExportTarget)>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _ExportSheet(count: lyrics.length),
  );
  if (choice == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    final done = await BackupService.export(lyrics,
        format: choice.$1, target: choice.$2);
    if (done) {
      messenger.showSnackBar(SnackBar(
          content: Text('Exported ${lyrics.length} '
              '${lyrics.length == 1 ? 'lyric' : 'lyrics'}.')));
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.count});
  final int count;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  ExportFormat _format = ExportFormat.json;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Export ${widget.count} '
                '${widget.count == 1 ? 'lyric' : 'lyrics'}',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SegmentedButton<ExportFormat>(
              segments: const [
                ButtonSegment(
                    value: ExportFormat.json,
                    icon: Icon(Icons.data_object),
                    label: Text('JSON backup')),
                ButtonSegment(
                    value: ExportFormat.txtZip,
                    icon: Icon(Icons.folder_zip_outlined),
                    label: Text('TXT (zip)')),
              ],
              selected: {_format},
              onSelectionChanged: (s) => setState(() => _format = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              _format == ExportFormat.json
                  ? 'Can be imported back into LyricsMe.'
                  : 'One readable .txt file per song, zipped.',
              style: text.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, (_format, ExportTarget.share)),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, (_format, ExportTarget.saveToDevice)),
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
