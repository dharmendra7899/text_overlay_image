import 'package:permission_handler/permission_handler.dart';

class Utils {
  static Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw Exception('Camera permission denied');
    }
  }
}
