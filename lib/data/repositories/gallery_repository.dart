import 'package:dio/dio.dart';

import '../../core/app_config.dart';
import '../../core/app_exception.dart';
import '../models/image_item.dart';

abstract class GalleryRepository {
  Future<PagedImages> fetchImages({
    required int page,
    String query = '',
    String? category,
  });
}

class PixabayGalleryRepository implements GalleryRepository {
  PixabayGalleryRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  final Dio _dio;

  @override
  Future<PagedImages> fetchImages({
    required int page,
    String query = '',
    String? category,
  }) async {
    if (AppConfig.pixabayApiKey.isEmpty) {
      throw const AppException(
        'API key missing. Run the app with '
        '--dart-define=PIXABAY_API_KEY=your_key',
      );
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '',
        queryParameters: {
          'key': AppConfig.pixabayApiKey,
          'page': page,
          'per_page': AppConfig.pageSize,
          'image_type': 'photo',
          'safesearch': 'true',
          if (query.isNotEmpty) 'q': query,
          if (category != null) 'category': category,
        },
      );

      final data = response.data ?? const <String, dynamic>{};
      final hits = (data['hits'] as List<dynamic>? ?? const [])
          .map((e) => ImageItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (data['totalHits'] as num?)?.toInt() ?? hits.length;
      return PagedImages(items: hits, totalHits: total);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AppException _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          'No internet connection, or the server took too long to respond.',
          isNetwork: true,
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 429) {
          return const AppException(
            'Too many requests. Please wait a moment and try again.',
          );
        }
        if (code == 400 || code == 401 || code == 403) {
          return const AppException(
            'The request was rejected. Please check your API key.',
          );
        }
        return AppException('Server error ($code). Please try again.');
      default:
        return const AppException('Something went wrong. Please try again.');
    }
  }
}
