import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/song_lyric.dart';
import '../providers/lyrics_provider.dart';
import '../providers/settings_provider.dart';
import '../services/lyrics_formatter.dart';
import '../services/lyrics_search.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

/// Distraction-free reader with font size, alignment and auto-scroll.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.lyricId});

  final String lyricId;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  bool _playing = false;
  bool _chromeVisible = true;
  bool _showSpeed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------- Auto-scroll ----------

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_scroll.hasClients) return;
    final speed = context.read<SettingsProvider>().scrollSpeed;
    final pos = _scroll.position;
    final next = pos.pixels + speed * dt;
    if (next >= pos.maxScrollExtent) {
      _scroll.jumpTo(pos.maxScrollExtent);
      _setPlaying(false);
    } else {
      _scroll.jumpTo(next);
    }
  }

  void _setPlaying(bool play) {
    if (play == _playing) return;
    setState(() {
      _playing = play;
      if (play) {
        _showSpeed = true;
        _chromeVisible = true;
      }
    });
    if (play) {
      // Restart from the top if we're already at the end.
      if (_scroll.hasClients &&
          _scroll.position.pixels >= _scroll.position.maxScrollExtent) {
        _scroll.jumpTo(0);
      }
      _lastTick = Duration.zero;
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  // ---------- Actions ----------

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lyrics copied.')));
  }

  Future<void> _searchWeb(SongLyric lyric) async {
    final ok = await searchLyricsOnWeb(
      lyric.title,
      lyric.hasKnownArtist ? lyric.artist : null,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal membuka browser.')));
    }
  }

  /// Replaces the placeholder with the clipboard text and saves immediately.
  Future<void> _pasteAndSave(SongLyric lyric) async {
    final provider = context.read<LyricsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = LyricsFormatter.clean(data?.text ?? '');
    if (pasted.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Clipboard kosong. Copy liriknya dulu dari browser.'),
        ),
      );
      return;
    }
    final previous = lyric;
    await provider.update(lyric.copyWith(lyrics: pasted));
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Lirik disimpan.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => provider.update(previous.copyWith()),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final provider = context.read<LyricsProvider>();
    final lyric = provider.byId(widget.lyricId);
    if (lyric == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete lyrics?'),
        content: Text('"${lyric.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _setPlaying(false);
    Navigator.pop(context);
    await provider.delete(lyric.id);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final lyric = context.select<LyricsProvider, SongLyric?>(
      (p) => p.byId(widget.lyricId),
    );
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (lyric == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final align = settings.centered ? TextAlign.center : TextAlign.left;
    final cross = settings.centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Scaffold(
      appBar: _chromeVisible
          ? AppBar(
              actions: [
                IconButton(
                  tooltip: 'Copy lyrics',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () => _copy(lyric.lyrics),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    _setPlaying(false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditorScreen(existing: lyric),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _delete,
                ),
                const SizedBox(width: 4),
              ],
            )
          : null,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _chromeVisible = !_chromeVisible),
          // Manual drag pauses auto-scroll so the reader is never fought.
          onVerticalDragDown: (_) => _setPlaying(false),
          child: Scrollbar(
            controller: _scroll,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 160),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: cross,
                    children: [
                      const SizedBox(width: double.infinity),
                      Text(
                        lyric.title,
                        textAlign: align,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lyric.artist,
                        textAlign: align,
                        style: text.titleSmall?.copyWith(color: scheme.primary),
                      ),
                      const SizedBox(height: 28),
                      if (lyric.needsLyrics)
                        _MissingLyricsCard(
                          onSearch: () => _searchWeb(lyric),
                          onPaste: () => _pasteAndSave(lyric),
                        )
                      else
                        SelectableText(
                          lyric.lyrics,
                          textAlign: align,
                          style: AppTheme.readerStyle(
                            context,
                            settings.fontSize,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        child: _chromeVisible
            ? _controls(settings, scheme)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _controls(SettingsProvider s, ColorScheme scheme) {
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            if (_showSpeed)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Slider(
                        value: s.scrollSpeed,
                        min: SettingsProvider.minSpeed,
                        max: SettingsProvider.maxSpeed,
                        label: '${s.scrollSpeed.round()} px/s',
                        divisions: 23,
                        onChanged: s.setScrollSpeed,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${s.scrollSpeed.round()}',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Smaller text',
                    icon: const Icon(Icons.text_decrease_rounded),
                    onPressed: s.fontSize > SettingsProvider.minFont
                        ? () => s.setFontSize(s.fontSize - 2)
                        : null,
                  ),
                  Text(
                    '${s.fontSize.round()}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  IconButton(
                    tooltip: 'Larger text',
                    icon: const Icon(Icons.text_increase_rounded),
                    onPressed: s.fontSize < SettingsProvider.maxFont
                        ? () => s.setFontSize(s.fontSize + 2)
                        : null,
                  ),
                  IconButton(
                    tooltip: s.centered ? 'Align left' : 'Align center',
                    icon: Icon(
                      s.centered
                          ? Icons.format_align_center_rounded
                          : Icons.format_align_left_rounded,
                    ),
                    onPressed: s.toggleCentered,
                  ),
                  IconButton(
                    tooltip: 'Scroll speed',
                    isSelected: _showSpeed,
                    icon: const Icon(Icons.speed_rounded),
                    onPressed: () => setState(() => _showSpeed = !_showSpeed),
                  ),
                  IconButton.filled(
                    tooltip: _playing
                        ? 'Pause auto-scroll'
                        : 'Start auto-scroll',
                    icon: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    ),
                    onPressed: () => _setPlaying(!_playing),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of the lyric body when a template song has no lyrics yet.
class _MissingLyricsCard extends StatelessWidget {
  const _MissingLyricsCard({required this.onSearch, required this.onPaste});

  final VoidCallback onSearch;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lirik belum diisi',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '1. Tap "Cari lirik" untuk membuka Google.\n'
            '2. Copy liriknya di browser.\n'
            '3. Balik ke sini, tap "Tempel & simpan".',
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.travel_explore_rounded),
            label: const Text('Cari lirik'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onPaste,
            icon: const Icon(Icons.content_paste_rounded),
            label: const Text('Tempel & simpan'),
          ),
        ],
      ),
    );
  }
}
