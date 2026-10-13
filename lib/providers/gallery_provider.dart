import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../data/models/image_item.dart';
import '../data/repositories/gallery_repository.dart';

enum GalleryStatus { initial, loading, loaded, error }

/// Holds the gallery list, pagination, search and category state.
class GalleryProvider extends ChangeNotifier {
  GalleryProvider(this._repository);

  final GalleryRepository _repository;

  final List<ImageItem> _items = [];
  GalleryStatus _status = GalleryStatus.initial;
  AppException? _error;
  AppException? _loadMoreError;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = '';
  String? _category;

  // Incremented on every new "first page" request so slow, outdated
  // responses (for example from a previous search) are ignored.
  int _requestId = 0;

  List<ImageItem> get items => List.unmodifiable(_items);
  GalleryStatus get status => _status;
  AppException? get error => _error;
  AppException? get loadMoreError => _loadMoreError;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get query => _query;
  String? get category => _category;

  bool get canLoadMore =>
      _status == GalleryStatus.loaded &&
      _hasMore &&
      !_isLoadingMore &&
      _loadMoreError == null;

  /// Loads page 1. With [refresh] the current list stays visible meanwhile
  /// (pull-to-refresh); otherwise the loading state is shown.
  Future<void> fetchFirstPage({bool refresh = false}) async {
    final requestId = ++_requestId;
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    _loadMoreError = null;
    _error = null;

    if (!refresh) {
      _items.clear();
      _status = GalleryStatus.loading;
      notifyListeners();
    }

    try {
      final result = await _repository.fetchImages(
        page: 1,
        query: _query,
        category: _category,
      );
      if (requestId != _requestId) return;
      _items
        ..clear()
        ..addAll(result.items);
      _hasMore = result.items.isNotEmpty && _items.length < result.totalHits;
      _status = GalleryStatus.loaded;
    } on AppException catch (e) {
      if (requestId != _requestId) return;
      _error = e;
      if (!refresh || _items.isEmpty) _status = GalleryStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => fetchFirstPage(refresh: true);

  /// Loads the next page and appends it (infinite scroll).
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _status != GalleryStatus.loaded) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final result = await _repository.fetchImages(
        page: _page + 1,
        query: _query,
        category: _category,
      );
      if (requestId != _requestId) return;
      final existing = _items.map((e) => e.id).toSet();
      _items.addAll(result.items.where((e) => !existing.contains(e.id)));
      _page += 1;
      _hasMore = result.items.isNotEmpty && _items.length < result.totalHits;
    } on AppException catch (e) {
      if (requestId != _requestId) return;
      _loadMoreError = e;
    } finally {
      if (requestId == _requestId) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> search(String text) {
    final trimmed = text.trim();
    if (trimmed == _query) return Future.value();
    _query = trimmed;
    return fetchFirstPage();
  }

  Future<void> selectCategory(String? category) {
    if (category == _category) return Future.value();
    _category = category;
    return fetchFirstPage();
  }
}
