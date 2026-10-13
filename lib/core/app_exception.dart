/// A user-friendly error that the UI can show directly.
class AppException implements Exception {
  const AppException(this.message, {this.isNetwork = false});

  final String message;
  final bool isNetwork;

  @override
  String toString() => message;
}
