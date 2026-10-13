import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_exception.dart';
import '../../data/models/image_item.dart';
import '../../data/repositories/download_service.dart';
import '../../providers/favorites_provider.dart';

/// Screen 2: large image, description, tags, stats, favorite and download.
class ImageDetailScreen extends StatefulWidget {
  const ImageDetailScreen({
    super.key,
    required this.item,
    required this.heroTag,
  });

  final ImageItem item;
  final String heroTag;

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  // null = idle, 0..1 = downloading
  final ValueNotifier<double?> _progress = ValueNotifier<double?>(null);

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    if (_progress.value != null) return;
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<DownloadService>();

    _progress.value = 0;
    try {
      await service.saveToGallery(
        widget.item.largeImageUrl,
        onProgress: (p) {
          if (mounted) _progress.value = p;
        },
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Image saved to your gallery')),
      );
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Download failed. Please try again.')),
      );
    } finally {
      if (mounted) _progress.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final isFavorite = context.select<FavoritesProvider, bool>(
      (p) => p.isFavorite(item.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () => context.read<FavoritesProvider>().toggle(item),
          ),
        ],
      ),
      body: ListView(
        children: [
          Hero(
            tag: widget.heroTag,
            child: AspectRatio(
              aspectRatio: item.aspectRatio,
              child: CachedNetworkImage(
                imageUrl: item.largeImageUrl,
                fit: BoxFit.cover,
                // Show the already-cached thumbnail while the big one loads.
                placeholder: (_, __) => CachedNetworkImage(
                  imageUrl: item.webformatUrl,
                  fit: BoxFit.cover,
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(item.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in item.tagList) Chip(label: Text(tag)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(icon: Icons.thumb_up_outlined, value: item.likes),
                    _Stat(icon: Icons.visibility_outlined, value: item.views),
                    _Stat(icon: Icons.download_outlined, value: item.downloads),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${item.width} × ${item.height} px  ·  Photo by ${item.user}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<double?>(
            valueListenable: _progress,
            builder: (context, value, _) {
              final percent = value == null ? null : (value * 100).round();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(value: value),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: percent == null ? _download : null,
                      icon: const Icon(Icons.download),
                      label: Text(
                        percent == null ? 'Download' : 'Downloading $percent%',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Icon(icon), const SizedBox(height: 4), Text(_compact(value))],
    );
  }
}
