import 'package:flutter/material.dart';

import '../database/local_db.dart';

/// App-wide preferences, persisted in the Hive settings box.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._db)
      : _themeMode = ThemeMode.values[
            (_db.getSetting<int>(_kTheme) ?? 0).clamp(0, ThemeMode.values.length - 1)],
        _fontSize = _db.getSetting<double>(_kFont) ?? 20,
        _centered = _db.getSetting<bool>(_kCenter) ?? false,
        _scrollSpeed = _db.getSetting<double>(_kSpeed) ?? 30;

  static const _kTheme = 'themeMode';
  static const _kFont = 'readerFontSize';
  static const _kCenter = 'readerCentered';
  static const _kSpeed = 'readerScrollSpeed';

  static const minFont = 14.0;
  static const maxFont = 44.0;
  static const minSpeed = 5.0; // logical pixels per second
  static const maxSpeed = 120.0;

  final LocalDb _db;
  ThemeMode _themeMode;
  double _fontSize;
  bool _centered;
  double _scrollSpeed;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  bool get centered => _centered;
  double get scrollSpeed => _scrollSpeed;

  void setThemeMode(ThemeMode m) {
    _themeMode = m;
    _db.setSetting(_kTheme, m.index);
    notifyListeners();
  }

  void setFontSize(double v) {
    _fontSize = v.clamp(minFont, maxFont);
    _db.setSetting(_kFont, _fontSize);
    notifyListeners();
  }

  void toggleCentered() {
    _centered = !_centered;
    _db.setSetting(_kCenter, _centered);
    notifyListeners();
  }

  void setScrollSpeed(double v) {
    _scrollSpeed = v.clamp(minSpeed, maxSpeed);
    _db.setSetting(_kSpeed, _scrollSpeed);
    notifyListeners();
  }
}
