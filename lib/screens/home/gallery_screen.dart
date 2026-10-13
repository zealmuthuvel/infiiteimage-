import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../providers/gallery_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/image_tile.dart';
import '../detail/image_detail_screen.dart';

/// Screen 1: responsive grid with search, categories, pull-to-refresh and
/// infinite scrolling.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      final provider = context.read<GalleryProvider>();
      if (provider.canLoadMore) provider.loadMore();
    }
  }

  // On big screens the first page may not fill the viewport, so there is
  // nothing to scroll. Keep loading until it does.
  void _fillViewportIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final provider = context.read<GalleryProvider>();
      if (_scrollController.position.maxScrollExtent <= 0 &&
          provider.canLoadMore) {
        provider.loadMore();
      }
    });
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _onSearch(String text) {
    _scrollToTop();
    context.read<GalleryProvider>().search(text);
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearch('');
  }

  Future<void> _onRefresh() async {
    final provider = context.read<GalleryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.refresh();
    if (provider.error != null && provider.items.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(provider.error!.message)));
    }
  }

  void _openDetail(BuildContext context, int index) {
    final item = context.read<GalleryProvider>().items[index];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ImageDetailScreen(item: item, heroTag: 'gallery-${item.id}'),
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    _fillViewportIfNeeded();

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSearchField()),
            SliverToBoxAdapter(child: _buildCategories(provider)),
            ..._buildContent(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _onSearch,
        decoration: InputDecoration(
          hintText: 'Search images',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (_, value, __) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(GalleryProvider provider) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: AppConfig.categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = index == 0 ? null : AppConfig.categories[index - 1];
          return ChoiceChip(
            label: Text(category == null ? 'All' : _capitalize(category)),
            selected: provider.category == category,
            onSelected: (_) {
              _scrollToTop();
              provider.selectCategory(category);
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildContent(GalleryProvider provider) {
    switch (provider.status) {
      case GalleryStatus.initial:
      case GalleryStatus.loading:
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case GalleryStatus.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(
              message: provider.error?.message ?? 'Something went wrong.',
              onRetry: () => provider.fetchFirstPage(),
            ),
          ),
        ];
      case GalleryStatus.loaded:
        if (provider.items.isEmpty) {
          return const [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No images found. Try another search.')),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            sliver: SliverGrid(
              // Cells are at most 200 wide, so the column count adapts to
              // phones, tablets and landscape automatically.
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = provider.items[index];
                  return ImageTile(
                    item: item,
                    heroTag: 'gallery-${item.id}',
                    onTap: () => _openDetail(context, index),
                  );
                },
                childCount: provider.items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildFooter(provider)),
        ];
    }
  }

  Widget _buildFooter(GalleryProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.loadMoreError != null) {
      return ErrorView(
        message: provider.loadMoreError!.message,
        onRetry: () => provider.loadMore(),
      );
    }
    if (!provider.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            "You've reached the end  ·  Images from Pixabay",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}
