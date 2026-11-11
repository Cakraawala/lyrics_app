# LyricsMe App

A minimalist, 100% offline notebook for your own song lyrics. Write or paste lyrics, find them instantly, and read them distraction-free, with auto-scroll for when you're singing or playing along.

No account, no cloud: everything stays on the device.

## Features

- **Home**: list of songs (title, artist, 1-line preview), real-time search across title, artist and lyrics, empty states, and a FAB to add a song.
- **Editor**: title, optional artist (falls back to "Unknown Artist") and a large lyrics field. **Auto-format** trims whitespace, normalises line breaks and collapses extra blank lines. It can be undone.
- **Reader**: font size −/+, left/center alignment, auto-scroll with adjustable speed, copy to clipboard, edit and delete. Tap the text to hide or show the controls. Dragging the text pauses auto-scroll. Reader preferences are remembered.
- **Backup**
  - Export all songs, or long-press to select some, as a **JSON backup** or a **TXT zip** (one `.txt` per song). You can save it to the device or share it.
  - Import a JSON backup. Existing records are never overwritten: an identical song is skipped, a song whose id clashes but whose content differs is added as a new record, and invalid entries are skipped and counted.
- **Settings**: theme (System / Light / Dark with an OLED true-black palette), backup shortcuts and the app version.

## Architecture

```
lib/
├── main.dart                 # bootstrap: open DB, register providers
├── models/song_lyric.dart    # SongLyric data model (+ map/JSON conversion)
├── database/local_db.dart    # Hive boxes: lyrics + settings
├── providers/                # state (ChangeNotifier + Provider)
│   ├── lyrics_provider.dart  # CRUD, search, batch import merge
│   └── settings_provider.dart# theme, reader font/alignment/scroll speed
├── services/
│   ├── lyrics_formatter.dart # auto-format / clean-up logic
│   ├── backup_service.dart   # JSON / TXT-zip encode, JSON parse, save/share
│   └── import_flow.dart      # pick file → merge → user feedback
├── screens/                  # home, editor, reader, settings
├── theme/app_theme.dart      # light + OLED dark themes
└── widgets/                  # lyric tile, empty state, export sheet, logo
```

**Data flow:** screens → providers → `LocalDb` (Hive). Lyrics are stored as plain maps keyed by UUID, so there is no code generation and no type adapters.

### Data model: `SongLyric`

| field       | type     | notes                         |
|-------------|----------|-------------------------------|
| `id`        | String   | UUID v4                       |
| `title`     | String   | required                      |
| `artist`    | String   | defaults to `Unknown Artist`  |
| `lyrics`    | String   | required                      |
| `createdAt` | DateTime | ISO-8601 in storage/export    |
| `updatedAt` | DateTime | ISO-8601 in storage/export    |

### JSON backup format

```json
{
  "format": "lyricsme.backup",
  "version": 1,
  "exportedAt": "2026-11-11T10:00:00.000",
  "count": 1,
  "lyrics": [
    { "id": "…", "title": "…", "artist": "…", "lyrics": "…",
      "createdAt": "…", "updatedAt": "…" }
  ]
}
```

Import also accepts a bare JSON array of song objects.

## Dependencies

| package | purpose |
|---|---|
| `provider` | state management |
| `hive_ce`, `hive_ce_flutter` | fast local storage that works on mobile, desktop and web |
| `google_fonts` | Inter (UI) and Literata (reader). Pinned to v8 because v9 targets the separate `material_ui` package. |
| `flutter_svg` | in-app logo |
| `file_picker` | open a backup / save an export |
| `share_plus` | share sheet export |
| `archive` | TXT zip export |
| `path_provider`, `uuid`, `intl`, `package_info_plus` | utilities |
| `flutter_launcher_icons` (dev) | generates app icons from `assets/icon/` |

> Note: `google_fonts` downloads the two fonts the first time the app runs online and then caches them. While offline it falls back to the system font. To be fully offline from the first launch, bundle the `.ttf` files under `assets/google_fonts/`.

## Run

Requires Flutter 3.47+ (Dart 3.13+).

```bash
flutter pub get
flutter run            # pick a device: Android, iOS, Windows or Chrome
```

Other useful commands:

```bash
flutter analyze
flutter test
dart run flutter_launcher_icons   # regenerate icons after editing assets/icon/*.png
flutter build apk --release
```

## Branding

- `assets/icon/logo.svg`: vector logo (a lyric sheet blended with a music note)
- `assets/icon/app_icon.png` / `app_icon_foreground.png`: 1024px rasters used for the launcher icons
