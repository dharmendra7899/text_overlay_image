import 'dart:io';

import 'package:chat_bot/services/downloader_service.dart';
import 'package:chat_bot/services/location_service.dart';
import 'package:chat_bot/widgets/my_text_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PreviewScreen extends StatefulWidget {
  final String croppedImagePath;

  const PreviewScreen({super.key, required this.croppedImagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  Uint8List? processedImage;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final location = await LocationService.getLocationWithAddress();

      final imageBytes = await File(widget.croppedImagePath).readAsBytes();

      final mapThumbnailData = await rootBundle.load(
        'assets/images/map_thumb.png',
      );
      final mapThumbnailBytes = mapThumbnailData.buffer.asUint8List();

      final gpsIconData = await rootBundle.load('assets/images/gps.png');
      final gpsIconBytes = gpsIconData.buffer.asUint8List();

      final result = await MyTextOverlay().addOverlayToImage(
        imageBytes: imageBytes,
        hindiAddress: location.hindiAddress,
        fullAddress: location.address,
        latitude: location.latLng.latitude,
        longitude: location.latLng.longitude,
        timestamp: DateTime.now(),
        mapThumbnailBytes: mapThumbnailBytes,
        gpsCameraIconBytes: gpsIconBytes,
      );

      if (mounted) {
        setState(() {
          processedImage = result;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) return true;

      if (await Permission.manageExternalStorage.isGranted) return true;

      if (await Permission.storage.request().isGranted) return true;

      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      return false;
    } else {
      return true;
    }
  }

  Future<void> startDownload() async {
    bool granted = await requestStoragePermission();

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
      }
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final tempFilePath =
        '${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.png';
    final tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(processedImage!);
    debugPrint("URL::: $tempFilePath");

    DownloadService.downloadFile(
      fileUrl: tempFilePath.toString(),
      fileName: "overlayImage",
      onProgress: (progress) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Downloading')));
      },
      onComplete: () {},
      onFinished: (id) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download completed!')));
      },
    );
  }

  String getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final ext = path.split('.').last;
      if (ext.length <= 5) return ext;
    } catch (e) {
      debugPrint(e.toString());
    }
    return 'file';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Center(
        child:
            processedImage == null
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.memory(processedImage!),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: startDownload,
                      icon: const Icon(Icons.save_alt, color: Colors.white),
                      label: const Text(
                        'Save to Gallery',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 6,
                        shadowColor: Colors.deepPurpleAccent,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
