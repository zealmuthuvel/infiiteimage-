import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/image_item.dart';

/// Stores favorites locally as JSON strings in SharedPreferences.
class FavoritesRepository {
  static const _key = 'favorites_v1';

  Future<List<ImageItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? const <String>[];
      return raw
          .map((s) => ImageItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupted data should never crash the app.
      return [];
    }
  }

  Future<void> save(List<ImageItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
