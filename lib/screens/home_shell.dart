import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import 'favorites/favorites_screen.dart';
import 'home/gallery_screen.dart';

/// Bottom navigation between the Gallery and Favorites tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final favoriteCount = context.select<FavoritesProvider, int>(
      (p) => p.favorites.length,
    );

    return Scaffold(
      // IndexedStack keeps each tab's scroll position when switching.
      body: IndexedStack(
        index: _index,
        children: const [GalleryScreen(), FavoritesScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: favoriteCount,
              isLabelVisible: favoriteCount > 0,
              child: const Icon(Icons.favorite_border),
            ),
            selectedIcon: const Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
