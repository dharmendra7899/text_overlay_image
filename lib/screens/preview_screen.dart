import 'dart:io';
import 'dart:typed_data';

import 'package:chat_bot/services/downloader_service.dart';
import 'package:chat_bot/services/location_service.dart';
import 'package:chat_bot/widgets/my_text_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class PreviewScreen extends StatefulWidget {
  final String croppedImagePath;

  const PreviewScreen({super.key, required this.croppedImagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  Uint8List? unitListImage;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final location = await LocationService.getLocationWithAddress();
      final imageBytes = await File(widget.croppedImagePath).readAsBytes();
      final mapThumb = await rootBundle.load('assets/images/map_thumb.png');
      final gpsIcon = await rootBundle.load('assets/images/gps.png');

      final result = await MyTextOverlay().addOverlayToImage(
        imageBytes: imageBytes,
        hindiAddress: location.hindiAddress,
        fullAddress: location.address,
        latitude: location.latLng.latitude,
        longitude: location.latLng.longitude,
        timestamp: DateTime.now(),
        mapThumbnailBytes: mapThumb.buffer.asUint8List(),
        gpsCameraIconBytes: gpsIcon.buffer.asUint8List(),
      );

      if (mounted) {
        setState(() {
          unitListImage = result;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error: $e\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Center(
        child:
            unitListImage == null
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.memory(unitListImage!),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final helper = DownloadHelper(context);
                        await helper.saveToDownloads(
                          unitListImage!,
                          'overlay_image',
                        );
                      },
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
