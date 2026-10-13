import 'package:flutter/foundation.dart';

import '../data/models/image_item.dart';
import '../data/repositories/favorites_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider(this._repository);

  final FavoritesRepository _repository;

  final List<ImageItem> _favorites = [];
  bool _isLoaded = false;

  List<ImageItem> get favorites => List.unmodifiable(_favorites);
  bool get isLoaded => _isLoaded;

  bool isFavorite(int id) => _favorites.any((e) => e.id == id);

  Future<void> load() async {
    final saved = await _repository.load();
    _favorites
      ..clear()
      ..addAll(saved);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggle(ImageItem item) async {
    final index = _favorites.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.insert(0, item);
    }
    notifyListeners();
    await _repository.save(_favorites);
  }
}
