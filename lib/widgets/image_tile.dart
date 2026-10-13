import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/models/image_item.dart';

/// One grid cell: a cached, resized thumbnail with a Hero transition.
class ImageTile extends StatelessWidget {
  const ImageTile({
    super.key,
    required this.item,
    required this.heroTag,
    required this.onTap,
    this.overlay,
  });

  final ImageItem item;
  final String heroTag;
  final VoidCallback onTap;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: heroTag,
              child: CachedNetworkImage(
                imageUrl: item.webformatUrl,
                fit: BoxFit.cover,
                memCacheWidth: 500,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => ColoredBox(color: color),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: color,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            if (overlay != null) Positioned(top: 4, right: 4, child: overlay!),
          ],
        ),
      ),
    );
  }
}
