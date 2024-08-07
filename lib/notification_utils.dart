import 'dart:isolate';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationUtils {
  NotificationUtils._();

  factory NotificationUtils() => _instance;
  static final NotificationUtils _instance = NotificationUtils._();
  final AwesomeNotifications awesomeNotifications = AwesomeNotifications();
  static ReceivePort? receivePort;

  Future<void> configuration() async {
    await awesomeNotifications.initialize(
        null,
        [
          NotificationChannel(
              channelKey: 'basic_channel',
              channelName: 'Basic Notifications',
              channelDescription: 'Basic Instant Notification',
              defaultColor: Colors.teal,
              importance: NotificationImportance.High,
              channelShowBadge: true,
              channelGroupKey: 'basic_channel_group')
        ],
        debug: true);
  }

  Future<void> createScheduleNotification() async {
    try {
      await awesomeNotifications.createNotification(
          content: NotificationContent(
              id: -1,
              channelKey: 'basic_channel',
              title: 'Absence',
              body: 'Jangan lupa absen masuk!'));
    } catch (e) {}
  }

  
}
