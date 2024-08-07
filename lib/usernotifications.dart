import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class UserNotificationsPage extends StatefulWidget {
  @override
  _UserNotificationsPageState createState() => _UserNotificationsPageState();
}

class _UserNotificationsPageState extends State<UserNotificationsPage> {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _scheduleDailyNotification();
  }

  void _initializeNotifications() {
    final initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
  }

  void _scheduleDailyNotification() {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'daily_notification_channel_id',
      'Daily Notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    final notificationDetails = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final time = tz.TZDateTime.now(tz.local).add(Duration(
      hours: 7 - tz.TZDateTime.now(tz.local).hour,
      minutes: -tz.TZDateTime.now(tz.local).minute,
      seconds: -tz.TZDateTime.now(tz.local).second,
    ));

    _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Reminder',
      'JANGAN LUPA ABSEN HARI INI!!!',
      time,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, dd/MM/yyyy');
    return formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Notifications'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.blue),
            title: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${_getFormattedDate()}\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'JANGAN LUPA ABSEN HARI INI!!!',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: UserNotificationsPage()));
