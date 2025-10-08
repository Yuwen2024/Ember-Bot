import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<ServerResponse> createRequest(double left, double midX, double midY, double right, String ip) async {
  final response = await http.post(
    Uri.parse(ip),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, double>{
      'left_position': left,
      'mid_x': midX,
      'mid_y': midY,
      'right_position': right}),
  );

  if (response.statusCode == 200) {
    // If the server did return a 201 CREATED response,
    // then parse the JSON.
    return ServerResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 201 CREATED response,
    // then throw an exception.
    print("Connection failed with IP $ip");
    return ServerResponse.fromJson({'null': null});
    // throw Exception('Failed to create request.');
  }
}

class ServerResponse {
  final String time;
  final String response;

  const ServerResponse({required this.time, required this.response});

  factory ServerResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'time': String time, 'response': String response} => ServerResponse(time: time, response: response),
      _ => throw const FormatException('Failed to load response.'),
    };
  }
}

void main() {
  runApp(const EmberBotApp());
}

class EmberBotApp extends StatefulWidget {
  const EmberBotApp({super.key});

  @override
  State<EmberBotApp> createState() => EmberBotAppState();
}

class EmberBotAppState extends State<EmberBotApp> with ChangeNotifier {
  var leftPadel = 0.0;
  var rightPadel = 0.0;
  var nozzleVertical = 0.0;
  var nozzleHorizontal = 0.0;
  String responseText = 'Initial reading';
  String videoIP = '192.168.0.1';
  String serverIP = 'http://127.0.0.1:8080';
  String streamUrl = "http://192.168.0.0.1";
  bool LEDOn = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EmberBotAppState(),
      child: MaterialApp(
        title: 'Ember Bot Controller',
        theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: MyHomePage(title: 'Ember Bot Controller'),
      )
    );
  }

  void updateLeftTrack(var val) {
    leftPadel = 215.0 - val;
    createRequest(leftPadel, nozzleHorizontal, nozzleVertical, rightPadel, serverIP);
    notifyListeners();
  }

  void updateRightTrack(var val) {
    rightPadel = 215.0 - val;
    createRequest(leftPadel, nozzleHorizontal, nozzleVertical, rightPadel, serverIP);
    notifyListeners();
  }

  void updateNozzleAim(var x, var y) {
    nozzleHorizontal = x - 466.0;
    nozzleVertical = y - 215.0;
    createRequest(leftPadel, nozzleHorizontal, nozzleVertical, rightPadel, serverIP);
    notifyListeners();
  }

  void updateServerIP(List<String> ip) {
    serverIP = ip[0];
    print("Server IP updated to $serverIP");
    streamUrl = ip[1];
    print("Video IP updated to $streamUrl");
    notifyListeners();
  }
}

class LeftMovementControlButton extends StatefulWidget {
  const LeftMovementControlButton({super.key});


  @override
  State<StatefulWidget> createState() => _LeftMovementControlButton();
}

class _LeftMovementControlButton extends State<LeftMovementControlButton> {

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<EmberBotAppState>();

    return Draggable(
      axis: Axis.vertical,
      feedback: SizedBox(
        height: 50.0,
        width: 50.0,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () {
              print("Drag button pressed");
            },
            heroTag: UniqueKey(),
            child: const Icon(Icons.height),
          ),
        ),
      ),
      childWhenDragging: Container(),
      onDragUpdate: (details) {
        print("Left moving: ${details.globalPosition.dy.toStringAsFixed(2)}");
        appState.updateLeftTrack(details.globalPosition.dy);
      },
      onDraggableCanceled: (velocity, offset) {
        print("Left cancelled: 215.0");
        appState.updateLeftTrack(215.0);
      },
      child: SizedBox(
        height: 50.0,
        width: 50.0,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () {
              print("Left button pressed");
            },
            heroTag: UniqueKey(),
            child: const Icon(Icons.height),
          ),
        ),
      ),
    );
  }
}

class RightMovementControlButton extends StatefulWidget {
  const RightMovementControlButton({super.key});


  @override
  State<StatefulWidget> createState() => _RightMovementControlButton();
}

class _RightMovementControlButton extends State<RightMovementControlButton> {
  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<EmberBotAppState>();

    return Draggable(
      axis: Axis.vertical,
      feedback: SizedBox(
        height: 50.0,
        width: 50.0,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () {
              print("Drag button pressed");
            },
            heroTag: UniqueKey(),
            child: const Icon(Icons.height),
          ),
        ),
      ),
      childWhenDragging: Container(),
      onDragUpdate: (details) {
        print("Right moving: ${details.globalPosition.dy.toStringAsFixed(2)}");
        appState.updateRightTrack(details.globalPosition.dy);
      },
      onDraggableCanceled: (velocity, offset) {
        print("Right cancelled: 215.0");
        appState.updateRightTrack(215.0);
      },
      child: SizedBox(
        height: 50.0,
        width: 50.0,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () {
              print("Right button pressed");
            },
            heroTag: UniqueKey(),
            child: const Icon(Icons.height),
          ),
        ),
      ),
    );
  }
}

class NozzleMovementControlButton extends StatefulWidget {
  const NozzleMovementControlButton({super.key});

  @override
  State<StatefulWidget> createState() => _NozzleMovementControlButton();
}

class _NozzleMovementControlButton extends State<NozzleMovementControlButton> {
  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<EmberBotAppState>();

    return Draggable(
      feedback: SizedBox(
        height: 50.0,
        width: 50.0,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () {
              print("Drag button pressed");
            },
            heroTag: UniqueKey(),
            child: const Icon(Icons.local_drink),
          ),
        ),
      ),
      childWhenDragging: Container(),
      onDragUpdate: (details) {
        print("Nozzle moving: ${details.globalPosition.dx.toStringAsFixed(2)} ${details.globalPosition.dy.toStringAsFixed(2)}");
        appState.updateNozzleAim(details.globalPosition.dx, details.globalPosition.dy);
      },
      onDraggableCanceled: (velocity, offset) {
        print("Nozzle cancelled: 466.0, 215.0");
        appState.updateNozzleAim(466.0, 215.0);
      },
      child: SizedBox(
        height: 50.0,
        width: 50.0,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () {
              print("Nozzle button pressed");
            },
            heroTag: UniqueKey(),
            child: const Icon(Icons.local_drink),
          ),
        ),
      ),
    );
  }
}

class WaterButton extends StatefulWidget {
  const WaterButton({super.key});

  @override
  State<StatefulWidget> createState() => _WaterButton();
}

class _WaterButton extends State<WaterButton> {
  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<EmberBotAppState>();
    bool pressed = false;

    return FloatingActionButton(onPressed: () {
      setState(() {
        print("Water control button pressed");
        pressed = !pressed;
      });
    }, 
    child: Icon(Icons.shower));

    // return Draggable(
    //   axis: Axis.vertical,
    //   maxSimultaneousDrags: 0,
    //   feedback: SizedBox(
    //     height: 50.0,
    //     width: 50.0,
    //     child: FittedBox(
    //       child: FloatingActionButton(
    //         onPressed: () {
    //           print("LED control button pressed");
    //           pressed = !pressed;
    //         },
    //         heroTag: UniqueKey(),
    //         child: Icon(Icons.lightbulb_outline),
    //       ),
    //     ),
    //   ),
    //   childWhenDragging: Container(),
    //   child: SizedBox(
    //     height: 50.0,
    //     width: 50.0,
    //     child: FittedBox(
    //       child: FloatingActionButton(
    //         onPressed: () {
    //           print("LED control button dragged");
    //           pressed = !pressed;
    //         },
    //         heroTag: UniqueKey(),
    //         child: const Icon(Icons.lightbulb),
    //       ),
    //     ),
    //   ),
    // );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  late final WebViewController _webview_controller;
  
  String ip = "127.0.0.1";
  String streamUrl = "http://10.0.40.140:5001";

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      ),
    );
    _controller = VideoPlayerController.asset("assets/butterfly.mp4");
    _controller.setLooping(true);

    _initializeVideoPlayerFuture = _controller.initialize();

    _webview_controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(streamUrl))
      ..enableZoom(false)
      ..setOverScrollMode(WebViewOverScrollMode.never)
      ..setVerticalScrollBarEnabled(false)
      ..setHorizontalScrollBarEnabled(false);
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<EmberBotAppState>();
    // bool LEDOn = false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: Text(widget.title),
        leading: 
          IconButton(
            onPressed: () {
              print("Menu button pressed");
            }, icon: Icon(Icons.menu)
          ),
        actions: [
          IconButton(onPressed: () {
            setState(() {
              appState.LEDOn = !appState.LEDOn;
              print("LED button pressed $appState.LEDOn");
            });
            //_navigateAndDisplaySettings(appState, context);
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => const UserSettingPage()),
            // );
          },
          icon: appState.LEDOn ? Icon(Icons.lightbulb) : Icon(Icons.lightbulb_outline)),

          IconButton(onPressed: () {
            print("Settings button pressed");
            _navigateAndDisplaySettings(appState, context);
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => const UserSettingPage()),
            // );
          },
          icon: Icon(Icons.settings)),

          IconButton(onPressed: () {
            print("Build button pressed");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserManualPage()),
            );
          }, 
          icon: Icon(Icons.build))
        ],
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(appState.leftPadel.toStringAsFixed(2)),
                  SizedBox(height: 114,),
                  LeftMovementControlButton(),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  WebViewWidget(controller: _webview_controller),
                  // FutureBuilder(
                  //   future: _initializeVideoPlayerFuture, 
                  //   builder: (context, snapshot) {
                  //     if (snapshot.connectionState == ConnectionState.done) {
                  //       // If the VideoPlayerController has finished initialization, use
                  //       // the data it provides to limit the aspect ratio of the video.
                  //       return AspectRatio(
                  //         aspectRatio: _controller.value.aspectRatio,
                  //         // Use the VideoPlayer widget to display the video.
                  //         child: VideoPlayer(_controller),
                  //       );
                  //     } else {
                  //       // If the VideoPlayerController is still initializing, show a
                  //       // loading spinner.
                  //       return const Center(child: CircularProgressIndicator());
                  //     }
                  //   },
                  // ),
                  Center(
                    child: Column(
                      children: [
                      Text("x = ${appState.nozzleHorizontal.toStringAsFixed(2)}, y = ${appState.nozzleVertical.toStringAsFixed(2)}"),
                      SizedBox(height: 114,),
                      NozzleMovementControlButton(),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(appState.rightPadel.toStringAsFixed(2)),
                  SizedBox(height: 114),
                  RightMovementControlButton(),
                  SizedBox(height: 54,),
                  WaterButton(),
                ],
              ),
            ),
          ],
        ),
      ),
      //   floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Wrap the play or pause in a call to `setState`. This ensures the
      //     // correct icon is shown.
      //     setState(() {
      //       // If the video is playing, pause it.
      //       if (_controller.value.isPlaying) {
      //         _controller.pause();
      //       } else {
      //         // If the video is paused, play it.
      //         _controller.play();
      //       }
      //     });
      //   },
      //   // Display the correct icon depending on the state of the player.
      //   child: Icon(
      //     _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
      //   ),
      // ),
    );
  }

  void _navigateAndDisplaySettings(var appState, BuildContext context) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    final result = await Navigator.push(
      context,
      // Create the SelectionScreen in the next step.
      MaterialPageRoute(builder: (context) => const UserSettingPage()),
    );

    appState.updateServerIP(result);
    _webview_controller.loadRequest(Uri.parse(result[1]));
    // _webview_controller.setNavigationDelegate(
    //   NavigationDelegate(
    //     onPageFinished: (url) async {
    //       await _webview_controller.runJavaScript('''
    //         if (!document.querySelector(;meta[name="viewport"]')) {
    //         var meta = document.createElement('meta');
    //         meta.name = "viewport";
    //         meta.content = "width=device-width, initial-scale=1.0, maxium-scale=1.0,
    //         document.getElementsByTagName('head')[0].appendChild(meta);
    //         }
    //         ''');

    //       await _webview_controller.runJavaScript('''
    //         document.body.style.overflowX = 'hidden';
    //         document.body.style.margin = '0';
    //         document.body.style.padding = '0';
    //         ''');
    //     }
    //   )
    // );



    print("Returned $result");
  }
}

class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Manual')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("How to use the app"),
            SizedBox(height: 200.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go back!'),
            ),
          ],
        ),
      ),
    );
  }
}

class UserSettingPage extends StatefulWidget {
  const UserSettingPage({super.key});

@override
  State<UserSettingPage> createState() => _UserSettingPage();
}

class _UserSettingPage extends State<UserSettingPage> {
  final myController = TextEditingController(text: 'http://');
  final videoIPController = TextEditingController(text: 'http://');

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    videoIPController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Settings"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 6),
              child: TextField(controller: myController),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 6),
              child: TextField(controller: videoIPController),
            ),
            ElevatedButton(
              onPressed: () {
                print(myController.text);
                print(videoIPController.text);

                if (myController.text.length == 0) {
                  myController.text = "http://";
                }

                if (videoIPController.text.length == 0) {
                  videoIPController.text = "http://";
                }

                Navigator.pop(context, [myController.text, videoIPController.text]);
              },
              child: const Text('Go back!'),
            ),
          ],
        ),
      ),
    );
  }
}