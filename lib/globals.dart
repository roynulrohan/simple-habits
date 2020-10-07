// global library

library simple_habits.globals;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
Color themeColor = Colors.pink; // global Color for theme accent

// function to launch mail app at directed email
launchURL() async {
  const url = 'mailto:<work.roynulrohan@gmail.com>';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

// sets Color into sharedpreferences
void setColor(int value, String name) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('colorValue', value);
  prefs.setString('color', name);
}

// String to Color
Color toColor(String value) {
  if (value == 'Pink') {
    return Colors.pink;
  } else if (value == 'Green') {
    return Colors.green;
  } else if (value == 'Blue') {
    return Colors.blue;
  } else {
    return Colors.black.withOpacity(0.75);
  }
}

// function to convert int to Day of local_notifications library
Day toDay(int i) {
  const days = [
    Day.Sunday,
    Day.Monday,
    Day.Tuesday,
    Day.Wednesday,
    Day.Thursday,
    Day.Friday,
    Day.Saturday
  ];

  return days[i];
}

// function to match DateTime.weekday to Day since DateTime ranges from 1-7 but Day ranges from 0-6
int dayCorrector(int i) {
  const days = [1, 2, 3, 4, 5, 6, 0];

  return days[i];
}

// function that takes in id, day, time, and title and pushes future notification
Future<void> scheduleNotification(
    int channel, Day day, String time, String title) async {
  var timeOfDay = TimeOfDay.fromDateTime(DateFormat.jm().parse(time));
  var scheduledNotificationDateTime = Time(timeOfDay.hour, timeOfDay.minute, 0);
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'reminders', 'Reminders', 'Habit reminder notifications',
      icon: 'notification_icon',
      largeIcon: DrawableResourceAndroidBitmap('app_icon'),
      autoCancel: true);
  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.showWeeklyAtDayAndTime(
      channel,
      'Habit Reminder for \"' + title + '\"',
      'Tap to open app',
      day,
      scheduledNotificationDateTime,
      platformChannelSpecifics);
}

// function to cancel nofitication at given id
Future<void> cancelNotification(int channel) async {
  await flutterLocalNotificationsPlugin.cancel(channel);
}
