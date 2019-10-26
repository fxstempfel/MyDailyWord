import 'dart:ui';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const colorPrimary = Color(0xFFE88229);
const colorSecondary = Color(0xFFFFFEE0);
const colorAccent = Color(0xFF992623);
const colorAccentGreyed = Color(0xFF8E5E5C);
const colorTextOnPrimary = Color(0xFF3A3335);
const colorTextOnPrimaryGreyed = Color(0xFF7C6D72);
const colorTextOnAccent = Color(0xFFFFFEE0);

const notificationHours = 'notificationHours';
const notificationMinutes = 'notificationMinutes';
const notificationIsEnabled = 'notificationIsSet';

Future<TimeOfDay> getNotificationTime() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var hours = prefs.getInt(notificationHours);
  var minutes = prefs.getInt(notificationMinutes);
  if (hours == null || minutes == null) {
    return null;
  } else {
    return TimeOfDay(hour: hours, minute: minutes);
  }
}

Future<bool> getNotificationIsEnabled() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(notificationIsEnabled);
}

Future setNotificationTime(int hours, int minutes) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt(notificationHours, hours);
  prefs.setInt(notificationMinutes, minutes);
}

Future setNotificationIsEnabled(bool enabled) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool(notificationIsEnabled, enabled);
}

void flushbarFactory(
    {@required context,
    @required messageString,
    buttonOnPressed,
    buttonString,
    titleString,
    onStatusChanged}) {
  Flushbar(
    titleText: (titleString == null)
        ? null
        : Text(titleString,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colorTextOnAccent,
                fontStyle: FontStyle.normal)),
    backgroundColor: colorAccent,
    duration: Duration(seconds: 4),
    messageText: Text(messageString,
        style: TextStyle(
            fontSize: 18,
            color: colorTextOnAccent,
            fontStyle: FontStyle.normal)),
    mainButton: (buttonOnPressed == null || buttonString == null)
        ? null
        : FlatButton(
            onPressed: buttonOnPressed,
            child: Text(
              buttonString.toUpperCase(),
              style: TextStyle(fontSize: 18, color: colorSecondary),
            )),
    onStatusChanged: onStatusChanged,
  ).show(context);
}

class HistoryToWordInfoArguments {
  String wordName;
  bool isFavorite;

  HistoryToWordInfoArguments(this.wordName, this.isFavorite);
}

class WordInfoToHistoryArguments {
  bool toDelete;
  bool isFavorite;

  WordInfoToHistoryArguments.toDelete() {
    toDelete = true;
  }

  WordInfoToHistoryArguments.favorite(bool isFavorite) {
    this.toDelete = false;
    this.isFavorite = isFavorite;
  }
}

class HistoryToFavoritesArguments {
  List<String> favoritesNames;

  HistoryToFavoritesArguments(this.favoritesNames);
}

class FavoritesToHistoryArguments {
  List<String> favoritesNames;
  List<String> toDeleteFromHistoryNames;

  FavoritesToHistoryArguments(
      this.favoritesNames, this.toDeleteFromHistoryNames);
}

class HistoryToNotificationsArguments {
  bool notificationIsEnabled;
  TimeOfDay notificationTime;

  HistoryToNotificationsArguments(
      this.notificationIsEnabled, this.notificationTime);
}
