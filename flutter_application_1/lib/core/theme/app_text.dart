import 'package:flutter/material.dart';

/// Крупная сжатая гарнитура для заголовков и цифр.
/// Основной текст остаётся системным — так интерфейс остаётся читаемым
/// на любом размере экрана.
abstract final class AppText {
  static const TextStyle _displayBase = TextStyle(
    fontFamily: 'PTSansNarrow',
    fontWeight: FontWeight.w700,
    height: 1.04,
    letterSpacing: 0.3,
  );

  static TextStyle display(double size, Color color) =>
      _displayBase.copyWith(fontSize: size, color: color);

  static const TextStyle microLabel = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: 1.3,
  );
}
