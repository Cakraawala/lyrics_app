import 'package:url_launcher/url_launcher.dart';

/// Opens a Google search for a song's lyrics in the external browser.
/// Returns false if no browser could handle it.
Future<bool> searchLyricsOnWeb(String title, String? artist) {
  final a = artist?.trim() ?? '';
  final q = [title.trim(), if (a.isNotEmpty) a, 'lyrics'].join(' ');
  final uri = Uri.https('www.google.com', '/search', {'q': q});
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
