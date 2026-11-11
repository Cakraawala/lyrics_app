import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song_lyric.dart';
import '../providers/lyrics_provider.dart';
import '../services/lyrics_formatter.dart';

/// Add (when [existing] is null) or edit a lyric.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, this.existing});

  final SongLyric? existing;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _artist;
  late final TextEditingController _lyrics;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _artist = TextEditingController(
        text: (e != null && e.hasKnownArtist) ? e.artist : '');
    _lyrics = TextEditingController(text: e?.lyrics ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _lyrics.dispose();
    super.dispose();
  }

  bool get _dirty {
    final e = widget.existing;
    if (e == null) {
      return _title.text.trim().isNotEmpty ||
          _artist.text.trim().isNotEmpty ||
          _lyrics.text.trim().isNotEmpty;
    }
    return _title.text.trim() != e.title ||
        SongLyric.normalizeArtist(_artist.text) != e.artist ||
        _lyrics.text != e.lyrics;
  }

  void _autoFormat() {
    final cleaned = LyricsFormatter.clean(_lyrics.text);
    if (cleaned == _lyrics.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already looks clean.')));
      return;
    }
    final previous = _lyrics.text;
    setState(() => _lyrics.text = cleaned);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Lyrics tidied up.'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => setState(() => _lyrics.text = previous),
      ),
    ));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<LyricsProvider>();
    final lyrics = _lyrics.text.trimRight();
    if (_isEdit) {
      await provider.update(widget.existing!.copyWith(
        title: _title.text,
        artist: _artist.text,
        lyrics: lyrics,
      ));
    } else {
      await provider.add(title: _title.text, artist: _artist.text, lyrics: lyrics);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<bool> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved edits will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_dirty || await _confirmDiscard()) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit lyrics' : 'New lyrics'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextFormField(
                controller: _title,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Song title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _artist,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Artist (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Lyrics',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _autoFormat,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('Auto-format'),
                  ),
                ],
              ),
              TextFormField(
                controller: _lyrics,
                minLines: 14,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(height: 1.5),
                decoration: const InputDecoration(
                    hintText: 'Write or paste the lyrics here…'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Lyrics are empty' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
