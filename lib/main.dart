import 'package:flutter/material.dart';
import 'package:infiiteimage/core/app_config.dart';
import 'package:provider/provider.dart';

import 'data/repositories/download_service.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/gallery_repository.dart';
import 'providers/favorites_provider.dart';
import 'providers/gallery_provider.dart';
import 'screens/home_shell.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const GalleryApp());
// }
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Key length: ${AppConfig.pixabayApiKey.length}');
  runApp(const GalleryApp());
}

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  ThemeData _theme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2B4386),
        brightness: brightness,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GalleryRepository>(create: (_) => PixabayGalleryRepository()),
        Provider<DownloadService>(create: (_) => DownloadService()),
        ChangeNotifierProvider<GalleryProvider>(
          create: (context) =>
              GalleryProvider(context.read<GalleryRepository>())
                ..fetchFirstPage(),
        ),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider(FavoritesRepository())..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Image Gallery',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}
