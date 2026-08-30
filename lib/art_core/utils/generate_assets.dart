import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/logo/logo_widget.dart';
import '../theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../assets_manager.dart';

/// utility to render the branding into high-res PNGs for the web folder.
/// Run this using: flutter run -d macos lib/art_core/utils/generate_assets.dart
void main() {
  runApp(const AssetGeneratorApp());
}

class AssetGeneratorApp extends StatelessWidget {
  const AssetGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 1024),
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const Scaffold(
          backgroundColor: Color(0xFF0A0A0F),
          body: Center(
            child: IconRenderer(),
          ),
        ),
      ),
    );
  }
}

class IconRenderer extends StatefulWidget {
  const IconRenderer({super.key});

  @override
  State<IconRenderer> createState() => _IconRendererState();
}

class _IconRendererState extends State<IconRenderer> {
  final GlobalKey _globalKey = GlobalKey();
  String _status = 'Ready to generate assets...';

  Future<void> _captureAndSave() async {
    setState(() => _status = 'Rendering...');

    try {
      final boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Use pixelRatio 4.0 for high resolution (128 * 4 = 512px)
      final ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final projectRoot = Directory.current.path;
      
      // Paths
      final faviconPath = '$projectRoot/web/favicon.png';
      final icon192Path = '$projectRoot/web/icons/Icon-192.png';
      final icon512Path = '$projectRoot/web/icons/Icon-512.png';

      // Ensure directory
      final iconsDir = Directory('$projectRoot/web/icons');
      if (!await iconsDir.exists()) {
        await iconsDir.create(recursive: true);
      }

      // Write files
      await File(faviconPath).writeAsBytes(bytes);
      await File(icon192Path).writeAsBytes(bytes);
      await File(icon512Path).writeAsBytes(bytes);

      setState(() => _status = '✅ Success!\nAssets saved to web folder.');
      debugPrint('🟢 Assets Generated Successfully');
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
      debugPrint('🔴 Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // We capture a square area containing the joystick icon for branding
        RepaintBoundary(
          key: _globalKey,
          child: Container(
            width: 128,
            height: 128,
            padding: const EdgeInsets.all(16),
            color: Colors.transparent,
            child: Center(
              child: SvgPicture.asset(
                AssetsManager.joystickIcon,
                colorFilter: const ColorFilter.mode(
                  AppColors.neonBlue,
                  BlendMode.srcIn,
                ),
                width: 80,
                height: 80,
              ),
            ),
          ),
        ),
        const SizedBox(height: 50),
        Text(
          _status,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.neonBlue),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _captureAndSave,
          icon: const Icon(Icons.download),
          label: const Text('Generate & Overwrite Web Icons'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
