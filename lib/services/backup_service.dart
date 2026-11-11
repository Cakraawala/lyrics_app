import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/song_lyric.dart';

enum ExportFormat { json, txtZip }

enum ExportTarget { saveToDevice, share }

class ImportParseResult {
  final List<SongLyric> valid;
  final int skipped;
  const ImportParseResult(this.valid, this.skipped);
}

/// Batch export / import of lyrics.
class BackupService {
  static const formatId = 'lyricsme.backup';
  static const formatVersion = 1;

  // ---------- Encoding ----------

  static Uint8List encodeJson(List<SongLyric> lyrics) {
    final payload = {
      'format': formatId,
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'count': lyrics.length,
      'lyrics': lyrics.map((l) => l.toMap()).toList(),
    };
    return Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)));
  }

  /// A zip with one human-readable .txt per song.
  static Uint8List encodeTxtZip(List<SongLyric> lyrics) {
    final archive = Archive();
    final used = <String>{};
    for (final l in lyrics) {
      var base = _safeName('${l.artist} - ${l.title}');
      var name = '$base.txt';
      var n = 2;
      while (!used.add(name)) {
        name = '$base ($n).txt';
        n++;
      }
      final body = '${l.title}\n${l.artist}\n\n${l.lyrics}\n';
      archive.addFile(ArchiveFile.bytes(name, utf8.encode(body)));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static String _safeName(String s) {
    final cleaned = s.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_').trim();
    return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
  }

  // ---------- Decoding ----------

  /// Accepts either the LyricsMe backup object or a bare JSON array of songs.
  /// Throws [FormatException] if the file is not JSON or has no song list.
  static ImportParseResult parseJson(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: true));
    final List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map && decoded['lyrics'] is List) {
      items = decoded['lyrics'] as List;
    } else {
      throw const FormatException('No lyrics list found in this file.');
    }
    final valid = <SongLyric>[];
    var skipped = 0;
    for (final item in items) {
      final l = SongLyric.tryFromImport(item);
      if (l == null) {
        skipped++;
      } else {
        valid.add(l);
      }
    }
    return ImportParseResult(valid, skipped);
  }

  // ---------- IO ----------

  /// Returns true if the file was saved / shared (false if user cancelled).
  static Future<bool> export(
    List<SongLyric> lyrics, {
    required ExportFormat format,
    required ExportTarget target,
  }) async {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final (bytes, fileName, mime) = switch (format) {
      ExportFormat.json => (
          encodeJson(lyrics),
          'lyricsme_backup_$stamp.json',
          'application/json'
        ),
      ExportFormat.txtZip => (
          encodeTxtZip(lyrics),
          'lyricsme_lyrics_$stamp.zip',
          'application/zip'
        ),
    };

    if (target == ExportTarget.saveToDevice) {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save LyricsMe export',
        fileName: fileName,
        bytes: bytes,
        mimeType: mime,
      );
      return uri != null;
    }

    final result = await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, name: fileName, mimeType: mime)],
      fileNameOverrides: [fileName],
      subject: 'LyricsMe export',
    ));
    return result.status != ShareResultStatus.dismissed;
  }

  /// Lets the user pick a .json backup. Returns null if cancelled.
  static Future<ImportParseResult?> pickAndParse() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Import LyricsMe backup',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return parseJson(await file.readAsBytes());
  }
}
