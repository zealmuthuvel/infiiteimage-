import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_exception.dart';

/// Downloads an image to a temp file (with progress) and saves it to the
/// device gallery, asking for permission when the platform needs it.
class DownloadService {
  DownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<void> saveToGallery(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    var hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      hasAccess = await Gal.requestAccess();
    }
    if (!hasAccess) {
      throw const AppException(
        'Permission denied. Allow photo access in Settings to save images.',
      );
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/gallery_${DateTime.now().millisecondsSinceEpoch}'
        '.${_extension(url)}';

    try {
      await _dio.download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
      await Gal.putImage(path);
    } on DioException {
      throw const AppException(
        'Download failed. Check your connection and try again.',
        isNetwork: true,
      );
    } on GalException {
      throw const AppException('Could not save the image to your gallery.');
    } finally {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  String _extension(String url) {
    final segments = Uri.parse(url).pathSegments;
    final last = segments.isEmpty ? '' : segments.last;
    final dot = last.lastIndexOf('.');
    final ext = dot == -1 ? '' : last.substring(dot + 1).toLowerCase();
    return (ext.isEmpty || ext.length > 4) ? 'jpg' : ext;
  }
}
