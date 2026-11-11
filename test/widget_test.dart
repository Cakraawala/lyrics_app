import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lyricsme/models/song_lyric.dart';
import 'package:lyricsme/services/backup_service.dart';
import 'package:lyricsme/services/lyrics_formatter.dart';

void main() {
  group('LyricsFormatter', () {
    test('trims, collapses spaces and blank lines', () {
      const raw = '\r\n\r\n  Hello   world  \r\n\r\n\r\n\r\nSecond\tline  \n\n';
      expect(LyricsFormatter.clean(raw), 'Hello world\n\nSecond line');
    });
  });

  group('SongLyric', () {
    test('falls back to Unknown Artist', () {
      final l = SongLyric.create(title: ' A ', artist: '  ', lyrics: 'x');
      expect(l.title, 'A');
      expect(l.artist, SongLyric.unknownArtist);
    });

    test('search matches title, artist and lyrics', () {
      final l = SongLyric.create(title: 'Rain', artist: 'Me', lyrics: 'drops fall');
      expect(l.matches('rai'), isTrue);
      expect(l.matches('ME'), isTrue);
      expect(l.matches('fall'), isTrue);
      expect(l.matches('sun'), isFalse);
    });
  });

  group('BackupService', () {
    test('JSON round-trip keeps records and skips invalid ones', () {
      final a = SongLyric.create(title: 'One', lyrics: 'la la');
      final bytes = BackupService.encodeJson([a]);
      final decoded = jsonDecode(utf8.decode(bytes)) as Map;
      (decoded['lyrics'] as List).add({'title': '', 'lyrics': 'x'});
      final parsed =
          BackupService.parseJson(utf8.encode(jsonEncode(decoded)));
      expect(parsed.valid.single.id, a.id);
      expect(parsed.skipped, 1);
    });

    test('rejects non-backup JSON', () {
      expect(() => BackupService.parseJson(utf8.encode('{"a":1}')),
          throwsFormatException);
    });
  });
}
