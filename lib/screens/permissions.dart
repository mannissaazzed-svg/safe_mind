import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Future<bool> mic() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> camera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}