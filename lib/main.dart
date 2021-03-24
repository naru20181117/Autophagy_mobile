import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/subjects.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Streams are created so that app can respond to notification-related events
/// since the plugin is initialised in the `main` function
final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String> selectNotificationSubject =
BehaviorSubject<String>();

// const MethodChannel platform =
//   MethodChannel('dexterx.dev/flutter_local_notifications_example');

class ReceivedNotification {
  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}

// Future void main() async {
//   runApp(MyApp());
// }

Future<void> main() async {
  // needed if you intend to initialize in the `main` function
  WidgetsFlutterBinding.ensureInitialized();

  await _configureLocalTimeZone();

  final NotificationAppLaunchDetails notificationAppLaunchDetails =
  await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  String initialRoute = '/';

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  // final IOSInitializationSettings initializationSettingsIOS =
  // IOSInitializationSettings(
  //     requestAlertPermission: false,
  //     requestBadgePermission: false,
  //     requestSoundPermission: false,
  //     onDidReceiveLocalNotification:
  //         (int id, String title, String body, String payload) async {
  //       didReceiveLocalNotificationSubject.add(ReceivedNotification(
  //           id: id, title: title, body: body, payload: payload));
  //     });
  // const MacOSInitializationSettings initializationSettingsMacOS =
  // MacOSInitializationSettings(
  //     requestAlertPermission: false,
  //     requestBadgePermission: false,
  //     requestSoundPermission: false);
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid);
      // iOS: initializationSettingsIOS,
      // macOS: initializationSettingsMacOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
        if (payload != null) {
          debugPrint('notification payload: $payload');
        }
        selectedNotificationPayload = payload;
        selectNotificationSubject.add(payload);
      });
  runApp(
    MaterialApp(
      initialRoute: initialRoute,
      routes: <String, WidgetBuilder>{
        '/': (context) => MyHomePage(title: 'Autophagy App')
      },
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    ),
  );
}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  // final String timeZoneName = await platform.invokeMethod('getTimeZoneName');
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
}


// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       // home: MyHomePage(title: 'Autophagy App'),
//       routes:{'/': (context) => MyHomePage(title: 'Autophagy App')}
//     );
//   }
// }

String selectedNotificationPayload;

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  var f = new NumberFormat("00");
  Duration _restTime = null;
  DateTime _endTime = null;
  Text _changeButton = Text('START Autophagy');

  void _startTime() {

    _endTime = tz.TZDateTime.now(tz.getLocation('Asia/Tokyo')).add(Duration(seconds: 10));
    _showNotificationWithTag(_endTime);
    Timer.periodic(Duration(seconds: 1), (timer) { setState(() {
      _restTime = _endTime.difference(DateTime.now());
        if (_restTime.isNegative)
          {
            timer.cancel();
            _changeButton = Text('START Autophagy');
          }
        });
    });
    _changeButton = Text('RESET Autophagy');
    Alert(
      closeIcon: Icon(Icons.close),
        context: context,
        title: "Start",
        desc: "Autophagy has started.",
      buttons: [
        DialogButton(
          child: Text(
          "GOT IT",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          width: 120,
          )
      ],
    ).show();
  }

  Future<void> _showNotificationWithTag(end_time) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.max, priority: Priority.high, tag: 'tag');
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.zonedSchedule(
        // notificationDetails, uiLocalNotificationDateInterpretation: null )schedule(
        0, 'Autophagy is done!', null, end_time, platformChannelSpecifics, androidAllowWhileIdle: true );;
  }

  @override
  void initState() {
    setState(() {
      _restTime = Duration(hours: 16);
      _changeButton = Text('START Autophagy');
    });
    super.initState();
    // For not android
    // _requestPermissions();
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();
  }
  // For not android
  // void _requestPermissions() {
  //   flutterLocalNotificationsPlugin
  //       .resolvePlatformSpecificImplementation<
  //       IOSFlutterLocalNotificationsPlugin>()
  //       ?.requestPermissions(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );
  //   flutterLocalNotificationsPlugin
  //       .resolvePlatformSpecificImplementation<
  //       MacOSFlutterLocalNotificationsPlugin>()
  //       ?.requestPermissions(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );
  // }

  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body)
              : null,
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        MyHomePage(),
                  ),
                );
              },
              child: const Text('Ok'),
            )
          ],
        ),
      );
    });
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      await Navigator.pushNamed(context, '/');
    });
  }

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '${_restTime.inHours}:${f.format(_restTime.inMinutes%60)}:${f.format(_restTime.inSeconds%60%60)}',
              style: Theme.of(context).textTheme.headline4,
            ),
            RaisedButton(
              child: _changeButton,
              color: Colors.blue,
              shape: const StadiumBorder(),
              onPressed: _startTime,
            ),
          ],
        ),
      ),

    );
  }
}
