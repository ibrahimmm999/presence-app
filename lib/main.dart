import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:presensi/login-page.dart';
import 'package:presensi/notification/notification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  HttpOverrides.global = new MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  // initialize notification
  await NotificationService.init();
  // Initialize timezone
  tz.initializeTimeZones();

  runApp(const MyApp());
  scheduleDailyNotifications();
}

void scheduleDailyNotifications() {
  // setup notification schedule
  List<TimeOfDay> notificationTimes = [
    const TimeOfDay(hour: 7, minute: 0),
    const TimeOfDay(hour: 7, minute: 30),
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 8, minute: 30),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 16, minute: 30),
    const TimeOfDay(hour: 16, minute: 45),
    const TimeOfDay(hour: 17, minute: 0),
  ];

  for (int i = 0; i < notificationTimes.length; i++) {
    DateTime scheduledDate = _nextInstanceOfTime(notificationTimes[i]);
    NotificationService.scheduleNotification(
      i,
      "Absensi",
      "Jangan lupa untuk melakukan absen",
      scheduledDate,
    );
  }
}

DateTime _nextInstanceOfTime(TimeOfDay time) {
  final now = DateTime.now();
  DateTime scheduledDate =
      DateTime(now.year, now.month, now.day, time.hour, time.minute);

  // If the scheduled time is before now, schedule for the next day
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  return scheduledDate;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
      routes: {
        '/another': (context) => AnotherPage(), // Define your AnotherPage route
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      print('notification payload: $payload');
    }
    Navigator.pushNamed(context, '/another', arguments: payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter Local Notifications")),
      body: Container(
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.notifications_outlined),
                onPressed: () async {
                  await flutterLocalNotificationsPlugin.show(
                    0,
                    'Simple Notification',
                    'This is a simple notification',
                    NotificationDetails(
                      android: AndroidNotificationDetails(
                        'your_channel_id',
                        'your_channel_name',
                        channelDescription: 'your_channel_description',
                        importance: Importance.max,
                        priority: Priority.high,
                      ),
                    ),
                    payload: 'This is simple data',
                  );
                },
                label: Text("Simple Notification"),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.timer_outlined),
                onPressed: () async {
                  await flutterLocalNotificationsPlugin.periodicallyShow(
                    1,
                    'Periodic Notification',
                    'This is a periodic notification',
                    RepeatInterval.everyMinute,
                    NotificationDetails(
                      android: AndroidNotificationDetails(
                        'your_channel_id',
                        'your_channel_name',
                        channelDescription: 'your_channel_description',
                        importance: Importance.max,
                        priority: Priority.high,
                      ),
                    ),
                    payload: 'This is periodic data',
                    androidAllowWhileIdle: true,
                  );
                },
                label: Text("Periodic Notifications"),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.timer_outlined),
                onPressed: () async {
                  await flutterLocalNotificationsPlugin.zonedSchedule(
                    2,
                    'Scheduled Notification',
                    'This is a scheduled notification',
                    tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
                    NotificationDetails(
                      android: AndroidNotificationDetails(
                        'your_channel_id',
                        'your_channel_name',
                        channelDescription: 'your_channel_description',
                        importance: Importance.max,
                        priority: Priority.high,
                      ),
                    ),
                    androidAllowWhileIdle: true,
                    payload: 'This is schedule data',
                    uiLocalNotificationDateInterpretation:
                        UILocalNotificationDateInterpretation.absoluteTime,
                  );
                },
                label: Text("Schedule Notifications"),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.delete_outline),
                onPressed: () async {
                  await flutterLocalNotificationsPlugin.cancel(1);
                },
                label: Text("Close Periodic Notifications"),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.delete_forever_outlined),
                onPressed: () async {
                  await flutterLocalNotificationsPlugin.cancelAll();
                },
                label: Text("Cancel All Notifications"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnotherPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String? payload =
        ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Payload"),
      ),
      body: Center(
        child: Text(payload ?? "No data"),
      ),
    );
  }
}
