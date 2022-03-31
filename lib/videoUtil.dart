import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
// import 'package:path_provider_windows/path_provider_windows.dart';

class VideoUtil {
  static String workPath = '';
  static String appTempDir = '';
  // final PathProviderWindows provider = PathProviderWindows();

  static Future<void> getAppTempDirectory() async {
    // appTempDir = '${(await PathProviderWindows().getTemporaryPath())}';
    appTempDir = '${(await getTemporaryDirectory()).path}';
  }

  static Future<void> saveImageFileToDirectory(
      byteData, String localName) async {
    Directory(appTempDir).create().then((Directory directory) async {
      final file = File('${directory.path}/$localName');

      file.writeAsBytesSync(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      print("filePath : ${file.path}");
    });
  }

  static void deleteTempDirectory() {
    Directory(appTempDir ).deleteSync(recursive: true);
  }

  static String generateEncodeVideoScript(String videoCodec, String fileName) {
    String outputPath = appTempDir + '/' + fileName;
    return "-hide_banner -y -i '" +
        appTempDir +
        "/" +
        "image_%d.jpg" +
        "' " +
        "-c:v " +
        videoCodec +
        " -r 12 " +
        outputPath;
  }
}