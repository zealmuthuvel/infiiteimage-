import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/favorites_provider.dart';
import '../../widgets/image_tile.dart';
import '../detail/image_detail_screen.dart' hide ImageTile;

/// Screen 3: images the user saved, kept on the device between launches.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, FavoritesProvider provider) {
    if (!provider.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final favorites = provider.favorites;
    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'No favorites yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap the heart on any image to save it here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final item = favorites[index];
        return ImageTile(
          item: item,
          heroTag: 'favorites-${item.id}',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ImageDetailScreen(
                item: item,
                heroTag: 'favorites-${item.id}',
              ),
            ),
          ),
          overlay: IconButton.filledTonal(
            tooltip: 'Remove from favorites',
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () => provider.toggle(item),
          ),
        );
      },
    );
  }
}
