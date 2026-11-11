/// Cleans up raw pasted lyrics so they read nicely.
///
/// - Normalises Windows / old-Mac line endings and odd unicode spaces.
/// - Trims trailing/leading whitespace on every line, collapses inner runs
///   of spaces/tabs to a single space.
/// - Collapses 2+ blank lines into a single blank line (stanza break).
/// - Removes blank lines at the start and end.
class LyricsFormatter {
  const LyricsFormatter._();

  static final _oddSpaces = RegExp('[  -​  　﻿]');
  static final _innerSpaces = RegExp(r'[ \t]+');

  static String clean(String raw) {
    final normalized = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_oddSpaces, ' ');

    final out = <String>[];
    var blankPending = false;
    for (final line in normalized.split('\n')) {
      final t = line.replaceAll(_innerSpaces, ' ').trim();
      if (t.isEmpty) {
        blankPending = out.isNotEmpty;
        continue;
      }
      if (blankPending) out.add('');
      blankPending = false;
      out.add(t);
    }
    return out.join('\n');
  }
}
