import 'dart:core';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_example/publishing/home_screen.dart';

import 'publishing/publisher_settings_widget.dart';
import 'publishing/publisher_widget.dart';
import 'publishing/subscriber_widget.dart';

import 'src/get_display_media_sample.dart';
import 'src/route_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.sample');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (WebRTC.platformIsDesktop) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  } else if (WebRTC.platformIsAndroid) {
    await startForegroundService();
  }
  runApp(MyApp());
}

Future<bool> startForegroundService() async {
  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: 'Title of the notification',
    notificationText: 'Text of the notification',
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  return FlutterBackground.enableBackgroundExecution();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late List<RouteItem> items;

  @override
  void initState() {
    super.initState();
    _initItems();
  }

  ListBody _buildRow(context, item) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title),
        onTap: () => item.push(context),
        trailing: Icon(Icons.arrow_right),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        // '/': (context) => const HomeScreen(),
        // When navigating to the "/second" route, build the SecondScreen widget.
        '/publisher': (context) => const PublisherWidget(),
        '/subscriber': (context) => const SubscriberWidget(),
        '/settings': (context) => const PublisherSettingsWidget(
              isConnected: false,
              supportedCodecs: [],
            )
      },
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter-WebRTC example'),
        ),
        body: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(0.0),
          itemCount: items.length,
          itemBuilder: (context, i) {
            return _buildRow(context, items[i]);
          },
        ),
      ),
    );
  }

  void _initItems() {
    items = <RouteItem>[
      RouteItem(
        title: 'Homescreen',
        push: (BuildContext context) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => HomeScreen(),
            ),
          );
        },
      ),
      RouteItem(
        title: 'ScreenShare',
        push: (BuildContext context) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => GetDisplayMediaSample(),
            ),
          );
        },
      ),
    ];
  }
}
