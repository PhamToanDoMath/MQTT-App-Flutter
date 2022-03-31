import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:advanced_splashscreen/advanced_splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gesture_zoom_box/gesture_zoom_box.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter_config/flutter_config.dart';

// import 'blinkingTimer.dart';
import 'videoUtil.dart';
void main() {
  // WidgetsFlutterBinding.ensureInitialized(); // Required by FlutterConfig
  // await FlutterConfig.loadEnvVariables();
  runApp(SplashScreen());
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AdvancedSplashScreen(
        child: MyApp(),
        seconds: 6,
        colorList: [
          Color(0xffffffff),
        ],
        appIcon: "assets/icon.png",
      )
    );
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // theme: ThemeData.dark(),
      title: 'SOS',
      home: Home(
      ),
    );
  }
}

class Home extends StatefulWidget {
  

  // Home({Key key, @required this.channel}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final String title = 'SOS';
  final String ngrok = 'http://42ca-34-136-100-187.ngrok.io/';

  final WebSocketChannel channel = IOWebSocketChannel.connect(Uri.parse('ws://192.168.1.9:8000/'));
  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
  StreamController streamController = new StreamController.broadcast();
  
  bool isLandscape = false;
  bool isRecording = false;
  int frameNum = 0;
  var data = [1,2,3];
  var _globalKey = new GlobalKey();

  bool isStop = true;
  bool isListening = false;
  var result = 'Press Start';

  @override
  void initState() {
    super.initState();
    VideoUtil.workPath = 'images';
    VideoUtil.getAppTempDirectory();

    streamController.addStream(channel.stream);

    streamController.stream.listen((data) {
      if (data.runtimeType == String){
        if(data == 'START'){
          setText('Recording...');
          isRecording = true;
        }
        else if(data == 'STOP'){
          isRecording = false;
          frameNum = 0;
          setText("Start Processing...");
          makeVideoWithFFMpeg(() => sendRequestToServer());
        }
      }
    }, onDone: () {
      print('Local websocket connection with ESP32: closed\n');
    });
  }

  @override
  void dispose() {
    streamController.close();
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title:  Text("SOS Demo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Center(
                child: Text(
                  result,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 35.0,
                    color: Colors.grey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              flex: 2,
            ),
            Expanded(
              child: Container(
                color: Colors.black,
                child: StreamBuilder(
                  stream: streamController.stream,
                  builder: (context, snapshot) => handleDataStream(snapshot),
                ),
              ),
              flex: 2,
            ),
          ],
        ),
      ),
    );
  }


  Widget handleDataStream(snapshot) {
    
    Widget loadingScreen = Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    ));

    if (!snapshot.hasData) 
      return loadingScreen;

    if (isRecording && snapshot.data.length > 5) {
      VideoUtil.saveImageFileToDirectory(
          snapshot.data, 'image_$frameNum.jpg');
      print(frameNum++);

      return Center(
        child:
          RepaintBoundary(
            key: _globalKey,
            child: GestureZoomBox(
              maxScale: 5.0,
              doubleTapScale: 2.0,
              duration: Duration(milliseconds: 200),
              child: Image.memory(
                Uint8List.fromList(snapshot.data as List<int>),
                gaplessPlayback: true,
                width: 320,
                height: 240,
              ),
            ),
          ),
      );
    }
    else{
      return loadingScreen;
    }
  }

  makeVideoWithFFMpeg(callback) {
    // pr.show();
    String tempVideofileName = "video.mp4";
    execute(VideoUtil.generateEncodeVideoScript("mpeg4", tempVideofileName))
        .then((rc) {
      // pr.hide();
      if (rc == 0) {
        print("Video complete");

        String outputPath = VideoUtil.appTempDir + "/$tempVideofileName";
        _saveVideo(outputPath);

        callback();
      }
    });
  }


  _saveVideo(String path) async {

    print("File Saved: ${path}");
    Fluttertoast.showToast(
        msg: "Video Saved",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);

  }

  Future<int> execute(String command) async {
    return await _flutterFFmpeg.execute(command);
  }

  void sendRequestToServer() async {
    print('Send request to server ....');

    var request = new http.MultipartRequest("POST", Uri.parse('${ngrok}sign2text'));
    request.files.add( await http.MultipartFile.fromPath(
        'vid',
        '${VideoUtil.appTempDir}/video.mp4',
        filename: 'video.mp4',
        contentType: MediaType.parse('video/mp4'),
    ));

    request.send().then((response) async{
      VideoUtil.deleteTempDirectory();

      if (response.statusCode == 200){
        Map<String, dynamic>  res = jsonDecode(await response.stream.bytesToString());

        //Display new result on screen
        if (res['status'] == 'successful'){
          setText(res['result'][0]);
          print("Result: " + result);
        }else{
          setText("Failed to translate. Please try again");
          print("Failed to recognize");
        }

      }
      else{
        print('Error when requesting');
        return null;
      }
    });
  }

  setText(String text){
    setState((){
      result = text;
    });
  }


}