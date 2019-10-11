import 'dart:ui';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';

const colorPrimary = Color(0xFFE88229);
const colorSecondary = Color(0xFFFFFEE0);
const colorAccent = Color(0xFF992623);
const colorAccentSecond = Color(0xFF292B66);
// 4E5340 (green) OR E08E45 (orange)
const colorTextOnPrimary = Color(0xFF3A3335);
const colorTextOnAccent = Color(0xFFFFFEE0);

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
    backgroundColor: colorAccentSecond,
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
