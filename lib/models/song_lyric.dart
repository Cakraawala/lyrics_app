import 'package:uuid/uuid.dart';

/// A single saved song lyric.
class SongLyric {
  static const unknownArtist = 'Unknown Artist';
  static const _uuid = Uuid();

  final String id;
  final String title;
  final String artist;
  final String lyrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SongLyric({
    required this.id,
    required this.title,
    required this.artist,
    required this.lyrics,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a brand-new lyric with a fresh UUID and timestamps.
  factory SongLyric.create({
    required String title,
    String? artist,
    required String lyrics,
  }) {
    final now = DateTime.now();
    return SongLyric(
      id: _uuid.v4(),
      title: title.trim(),
      artist: normalizeArtist(artist),
      lyrics: lyrics,
      createdAt: now,
      updatedAt: now,
    );
  }

  static String normalizeArtist(String? artist) {
    final a = artist?.trim() ?? '';
    return a.isEmpty ? unknownArtist : a;
  }

  bool get hasKnownArtist => artist != unknownArtist;

  /// First non-empty line of the lyrics, used as a list preview.
  String get preview {
    for (final line in lyrics.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        artist.toLowerCase().contains(q) ||
        lyrics.toLowerCase().contains(q);
  }

  SongLyric copyWith({String? title, String? artist, String? lyrics}) {
    return SongLyric(
      id: id,
      title: title?.trim() ?? this.title,
      artist: artist == null ? this.artist : normalizeArtist(artist),
      lyrics: lyrics ?? this.lyrics,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'lyrics': lyrics,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SongLyric.fromMap(Map<dynamic, dynamic> map) {
    final created =
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now();
    return SongLyric(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: normalizeArtist(map['artist'] as String?),
      lyrics: map['lyrics'] as String,
      createdAt: created,
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? created,
    );
  }

  /// Lenient parser for imported records. Returns null when the record is
  /// unusable (missing title or lyrics, wrong types).
  static SongLyric? tryFromImport(Object? raw) {
    if (raw is! Map) return null;
    final title = raw['title'];
    final lyrics = raw['lyrics'];
    if (title is! String || title.trim().isEmpty) return null;
    if (lyrics is! String || lyrics.trim().isEmpty) return null;
    final artist = raw['artist'];
    final id = raw['id'];
    final now = DateTime.now();
    final created = DateTime.tryParse(raw['createdAt']?.toString() ?? '') ?? now;
    return SongLyric(
      id: (id is String && id.isNotEmpty) ? id : _uuid.v4(),
      title: title.trim(),
      artist: normalizeArtist(artist is String ? artist : null),
      lyrics: lyrics,
      createdAt: created,
      updatedAt: DateTime.tryParse(raw['updatedAt']?.toString() ?? '') ?? created,
    );
  }
}
