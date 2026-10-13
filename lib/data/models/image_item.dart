class ImageItem {
  const ImageItem({
    required this.id,
    required this.previewUrl,
    required this.webformatUrl,
    required this.largeImageUrl,
    required this.width,
    required this.height,
    required this.tags,
    required this.user,
    required this.likes,
    required this.views,
    required this.downloads,
    required this.pageUrl,
  });

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    int toInt(Object? v) => (v as num?)?.toInt() ?? 0;
    String toStr(Object? v) => (v as String?) ?? '';

    final web = toStr(json['webformatURL']);
    final large = toStr(json['largeImageURL']);
    return ImageItem(
      id: toInt(json['id']),
      previewUrl: toStr(json['previewURL']),
      webformatUrl: web,
      largeImageUrl: large.isEmpty ? web : large,
      width: toInt(json['imageWidth']),
      height: toInt(json['imageHeight']),
      tags: toStr(json['tags']),
      user: toStr(json['user']),
      likes: toInt(json['likes']),
      views: toInt(json['views']),
      downloads: toInt(json['downloads']),
      pageUrl: toStr(json['pageURL']),
    );
  }

  final int id;
  final String previewUrl;
  final String webformatUrl;
  final String largeImageUrl;
  final int width;
  final int height;
  final String tags;
  final String user;
  final int likes;
  final int views;
  final int downloads;
  final String pageUrl;

  /// Uses the same keys as the Pixabay API so [fromJson] can read it back.
  Map<String, dynamic> toJson() => {
        'id': id,
        'previewURL': previewUrl,
        'webformatURL': webformatUrl,
        'largeImageURL': largeImageUrl,
        'imageWidth': width,
        'imageHeight': height,
        'tags': tags,
        'user': user,
        'likes': likes,
        'views': views,
        'downloads': downloads,
        'pageURL': pageUrl,
      };

  double get aspectRatio => (width <= 0 || height <= 0) ? 1.0 : width / height;

  List<String> get tagList => tags
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  String get title {
    if (tagList.isEmpty) return 'Untitled';
    final first = tagList.first;
    return first[0].toUpperCase() + first.substring(1);
  }

  /// Pixabay has no description field, so one is built from the metadata.
  String get description {
    final tagText = tagList.isEmpty ? 'no tags' : tagList.join(', ');
    return 'A photo by $user, tagged $tagText. It has been viewed $views '
        'times, downloaded $downloads times and liked by $likes people.';
  }
}

class PagedImages {
  const PagedImages({required this.items, required this.totalHits});

  final List<ImageItem> items;
  final int totalHits;
}
