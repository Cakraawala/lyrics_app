import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lyrics_provider.dart';
import '../services/import_flow.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_state.dart';
import '../widgets/export_sheet.dart';
import '../widgets/lyric_tile.dart';
import 'editor_screen.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  final Set<String> _selected = {};

  bool get _selecting => _selected.isNotEmpty;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  Future<void> _deleteWithUndo(Iterable<String> ids) async {
    final provider = context.read<LyricsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final removed = await provider.deleteMany(ids);
    if (removed.isEmpty) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          removed.length == 1
              ? '"${removed.first.title}" dihapus.'
              : '${removed.length} lagu dihapus.',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => provider.restore(removed),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSelected() async {
    final count = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus $count lagu?'),
        content: const Text('Lagu yang dipilih akan dihapus dari perangkat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final ids = _selected.toList();
    setState(_selected.clear);
    await _deleteWithUndo(ids);
  }

  Future<void> _onMenu(String value) async {
    final provider = context.read<LyricsProvider>();
    switch (value) {
      case 'export':
        await showExportSheet(context, provider.all);
      case 'import':
        await runImportFlow(context);
      case 'select':
        if (provider.all.isNotEmpty) {
          setState(() => _selected.add(provider.all.first.id));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LyricsProvider>();
    final items = provider.filtered;
    final scheme = Theme.of(context).colorScheme;

    // Drop selections that no longer exist (e.g. deleted from reader).
    _selected.removeWhere((id) => provider.byId(id) == null);

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: _selecting ? _selectionBar(provider) : _mainBar(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: provider.setQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search title, artist or lyrics',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: provider.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            provider.setQuery('');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: provider.isEmpty
                  ? const EmptyState(
                      icon: Icons.queue_music_rounded,
                      title: 'No lyrics yet',
                      message: 'Tap + to write or paste your first song.',
                    )
                  : items.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      message: 'Try a different word.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const Divider(indent: 20, endIndent: 20),
                      itemBuilder: (context, i) {
                        final l = items[i];
                        final tile = LyricTile(
                          lyric: l,
                          selectionMode: _selecting,
                          selected: _selected.contains(l.id),
                          onLongPress: () => _toggle(l.id),
                          onTap: () => _selecting
                              ? _toggle(l.id)
                              : Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReaderScreen(lyricId: l.id),
                                  ),
                                ),
                        );
                        if (_selecting) return tile;
                        return Dismissible(
                          key: ValueKey(l.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: scheme.error,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.onError,
                            ),
                          ),
                          onDismissed: (_) => _deleteWithUndo([l.id]),
                          child: tile,
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: _selecting
            ? null
            : FloatingActionButton(
                tooltip: 'Add lyrics',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditorScreen()),
                ),
                child: const Icon(Icons.add),
              ),
        backgroundColor: scheme.surface,
      ),
    );
  }

  PreferredSizeWidget _mainBar() => AppBar(
    titleSpacing: 20,
    title: const Row(
      children: [AppLogo(size: 30), SizedBox(width: 12), Text('LyricsMe')],
    ),
    actions: [
      PopupMenuButton<String>(
        tooltip: 'Backup',
        icon: const Icon(Icons.swap_vert_rounded),
        onSelected: _onMenu,
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'export',
            child: ListTile(
              leading: Icon(Icons.upload_outlined),
              title: Text('Export all'),
            ),
          ),
          PopupMenuItem(
            value: 'select',
            child: ListTile(
              leading: Icon(Icons.checklist_rounded),
              title: Text('Select (export / delete)'),
            ),
          ),
          PopupMenuItem(
            value: 'import',
            child: ListTile(
              leading: Icon(Icons.download_outlined),
              title: Text('Import JSON backup'),
            ),
          ),
        ],
      ),
      IconButton(
        tooltip: 'Settings',
        icon: const Icon(Icons.tune_rounded),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
      ),
      const SizedBox(width: 4),
    ],
  );

  PreferredSizeWidget _selectionBar(LyricsProvider provider) {
    final visible = provider.filtered;
    final allSelected =
        visible.isNotEmpty && visible.every((l) => _selected.contains(l.id));
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancel',
        icon: const Icon(Icons.close),
        onPressed: () => setState(_selected.clear),
      ),
      title: Text('${_selected.length} selected'),
      actions: [
        IconButton(
          tooltip: allSelected ? 'Deselect all' : 'Select all',
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
          onPressed: () => setState(() {
            if (allSelected) {
              _selected.removeAll(visible.map((l) => l.id));
            } else {
              _selected.addAll(visible.map((l) => l.id));
            }
          }),
        ),
        IconButton(
          tooltip: 'Delete selected',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: _confirmDeleteSelected,
        ),
        IconButton(
          tooltip: 'Export selected',
          icon: const Icon(Icons.upload_outlined),
          onPressed: () async {
            final chosen = provider.all
                .where((l) => _selected.contains(l.id))
                .toList();
            await showExportSheet(context, chosen);
            if (mounted) setState(_selected.clear);
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
