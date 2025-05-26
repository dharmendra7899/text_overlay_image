import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadHelper {
  final BuildContext context;

  DownloadHelper(this.context);

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) return true;
      if (await Permission.manageExternalStorage.isGranted) return true;

      await Permission.storage.request();
      await Permission.manageExternalStorage.request();

      return await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted;
    }
    return true;
  }

  Future<void> saveToDownloads(Uint8List imageBytes, String fileName) async {
    bool granted = await requestStoragePermission();

    if (!granted) {
      _showMessage('Storage permission denied');
      return;
    }

    try {
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final filePath =
          '${downloadsDir!.path}/$fileName${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      _showMessage('Downloaded to: $filePath');
      debugPrint("File saved at: $filePath");
    } catch (e) {
      debugPrint("Save Error: $e");
      _showMessage('Failed to save file');
    }
  }

  void _showMessage(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
