/// App-wide constants. The API key is NOT hard-coded: pass it at run time with
/// `--dart-define=PIXABAY_API_KEY=your_key`.
class AppConfig {
  static const String pixabayApiKey = String.fromEnvironment('PIXABAY_API_KEY');
  static const String baseUrl = 'https://pixabay.com/api/';
  static const int pageSize = 24;

  /// Valid Pixabay categories (subset) used for the filter chips.
  static const List<String> categories = [
    'nature',
    'animals',
    'travel',
    'food',
    'sports',
    'buildings',
    'business',
    'music',
    'science',
    'people',
  ];
}
