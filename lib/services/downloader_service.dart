import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

@pragma('vm:entry-point')
class DownloadService {
  static final ReceivePort _port = ReceivePort();
  static bool _isPortBound = false;

  static ValueChanged<int>? _onProgress;
  static VoidCallback? _onComplete;
  static ValueChanged<String>? _onFinished;

  static void initialize() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );

    FlutterDownloader.registerCallback(downloadCallback);

    if (!_isPortBound) {
      _port.listen((dynamic data) {
        String id = data[0];
        DownloadTaskStatus status = DownloadTaskStatus.values[data[1]];
        int progress = data[2];

        _onProgress?.call(progress);

        if (status == DownloadTaskStatus.complete) {
          _onComplete?.call();
          _onFinished?.call(id);
        }
      });
      _isPortBound = true;
    }
  }

  static Future<void> downloadFile({
    required String fileUrl,
    required String fileName,
    required ValueChanged<int> onProgress,
    required VoidCallback onComplete,
    required ValueChanged<String> onFinished,
  }) async {
    _onProgress = onProgress;
    _onComplete = onComplete;
    _onFinished = onFinished;

    // final dir = await getApplicationDocumentsDirectory();
    // var localPath = dir.path + fileName;
    // final savedDir = Directory(localPath);

    Directory? dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await FlutterDownloader.enqueue(
      url: fileUrl,
      fileName: fileName,
      savedDir: dir.path,
      showNotification: true,
      openFileFromNotification: true,
    );
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      'downloader_send_port',
    );
    send?.send([id, status, progress]);
  }
}
