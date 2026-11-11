import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/song_lyric.dart';

/// Thin wrapper over Hive boxes. Lyrics are stored as plain maps keyed by id,
/// so no code generation / type adapters are needed.
class LocalDb {
  static const _lyricsBox = 'lyrics';
  static const _settingsBox = 'settings';

  late final Box<Map> _lyrics;
  late final Box _settings;

  Future<void> init() async {
    await Hive.initFlutter('lyricsme');
    _lyrics = await Hive.openBox<Map>(_lyricsBox);
    _settings = await Hive.openBox(_settingsBox);
  }

  // ---- Lyrics CRUD ----

  List<SongLyric> getAllLyrics() {
    final result = <SongLyric>[];
    for (final raw in _lyrics.values) {
      try {
        result.add(SongLyric.fromMap(raw));
      } catch (_) {
        // Skip corrupted records instead of crashing the whole list.
      }
    }
    return result;
  }

  Future<void> putLyric(SongLyric lyric) => _lyrics.put(lyric.id, lyric.toMap());

  Future<void> putLyrics(Iterable<SongLyric> lyrics) =>
      _lyrics.putAll({for (final l in lyrics) l.id: l.toMap()});

  Future<void> deleteLyric(String id) => _lyrics.delete(id);

  bool containsLyric(String id) => _lyrics.containsKey(id);

  // ---- Settings ----

  T? getSetting<T>(String key) {
    final v = _settings.get(key);
    return v is T ? v : null;
  }

  Future<void> setSetting(String key, Object value) => _settings.put(key, value);
}
