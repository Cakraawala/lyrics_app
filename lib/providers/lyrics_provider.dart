import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/local_db.dart';
import '../models/song_lyric.dart';

class ImportSummary {
  final int added;
  final int duplicates;
  final int skipped;
  const ImportSummary(this.added, this.duplicates, this.skipped);
}

class LyricsProvider extends ChangeNotifier {
  LyricsProvider(this._db) {
    _items = _db.getAllLyrics();
    _sort();
  }

  final LocalDb _db;
  late List<SongLyric> _items;
  String _query = '';

  String get query => _query;
  List<SongLyric> get all => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  List<SongLyric> get filtered =>
      _query.isEmpty ? all : _items.where((l) => l.matches(_query)).toList();

  SongLyric? byId(String id) {
    for (final l in _items) {
      if (l.id == id) return l;
    }
    return null;
  }

  void setQuery(String q) {
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }

  void _sort() => _items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<SongLyric> add({
    required String title,
    String? artist,
    required String lyrics,
  }) async {
    final l = SongLyric.create(title: title, artist: artist, lyrics: lyrics);
    await _db.putLyric(l);
    _items.insert(0, l);
    notifyListeners();
    return l;
  }

  Future<SongLyric> update(SongLyric updated) async {
    await _db.putLyric(updated);
    _items = [for (final l in _items) l.id == updated.id ? updated : l];
    _sort();
    notifyListeners();
    return updated;
  }

  Future<void> delete(String id) async {
    await _db.deleteLyric(id);
    _items.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  /// Deletes several lyrics and returns them (so the caller can offer undo).
  Future<List<SongLyric>> deleteMany(Iterable<String> ids) async {
    final idSet = ids.toSet();
    final removed = _items.where((l) => idSet.contains(l.id)).toList();
    if (removed.isEmpty) return removed;
    await _db.deleteLyrics(idSet);
    _items.removeWhere((l) => idSet.contains(l.id));
    notifyListeners();
    return removed;
  }

  /// Puts previously deleted lyrics back exactly as they were (undo).
  Future<void> restore(List<SongLyric> lyrics) async {
    if (lyrics.isEmpty) return;
    await _db.putLyrics(lyrics);
    final existing = _items.map((l) => l.id).toSet();
    _items.addAll(lyrics.where((l) => !existing.contains(l.id)));
    _sort();
    notifyListeners();
  }

  /// Inserts imported lyrics without ever overwriting existing records:
  /// - same id + same content  -> counted as duplicate, ignored
  /// - same id + different one -> stored as a new record with a fresh id
  Future<ImportSummary> importBatch(List<SongLyric> incoming, int skipped) async {
    const uuid = Uuid();
    final existing = {for (final l in _items) l.id: l};
    final toInsert = <SongLyric>[];
    var duplicates = 0;

    for (final l in incoming) {
      final current = existing[l.id];
      if (current == null) {
        toInsert.add(l);
        existing[l.id] = l; // guard against duplicates inside the same file
      } else if (current.title == l.title &&
          current.artist == l.artist &&
          current.lyrics == l.lyrics) {
        duplicates++;
      } else {
        final copy = SongLyric(
          id: uuid.v4(),
          title: l.title,
          artist: l.artist,
          lyrics: l.lyrics,
          createdAt: l.createdAt,
          updatedAt: l.updatedAt,
        );
        toInsert.add(copy);
        existing[copy.id] = copy;
      }
    }

    if (toInsert.isNotEmpty) {
      await _db.putLyrics(toInsert);
      _items.addAll(toInsert);
      _sort();
      notifyListeners();
    }
    return ImportSummary(toInsert.length, duplicates, skipped);
  }
}
