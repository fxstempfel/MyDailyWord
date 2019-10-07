import 'package:flutter/material.dart';

import 'favorites_page.dart';
import 'history_page.dart';
import 'utils.dart';
import 'word_page.dart';

// for alarm manager, see https://github.com/marcmo/flutter_alarm_manager_example/tree/master/lib
// for notifications, see https://github.com/robindijkhof/flutter_noti
// to use both: https://stackoverflow.com/questions/57501404/flutter-android-combine-alarmmanager-with-notifications
void main() => runApp(DailyWordApp());

class DailyWordApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Daily Word',
        color: colorPrimary,
        initialRoute: '/',
        routes: {
          WordInfoPage.routeName: (context) => WordInfoPage(),
          FavoritesPage.routeName: (context) => FavoritesPage()
        },
        home: Scaffold(
          body: Center(
            child: History(),
          ),
        ),
        theme: ThemeData(
            primaryColorDark: colorPrimaryDark,
            primaryColor: colorPrimary,
            accentColor: colorAccent,
            dividerColor: colorPrimaryDark,
            scaffoldBackgroundColor: colorSecondary,
            dialogBackgroundColor: colorSecondary,
            appBarTheme: AppBarTheme(
                color: colorPrimaryDark,
                brightness: Brightness.dark,
                textTheme: TextTheme(
                    title: TextStyle(color: colorSecondary, fontSize: 20))),
            textTheme: TextTheme(
              display1: TextStyle(
                  fontSize: 42,
                  fontFamily: 'DancingScript',
                  color: colorTextOnPrimary,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.normal),
              title: TextStyle(
                  color: colorTextOnPrimary,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal),
              subtitle: TextStyle(
                  color: colorTextOnPrimary,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic),
              subhead: TextStyle(
                  color: colorTextOnPrimary,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic),
              body2: TextStyle(
                  color: colorTextOnPrimary,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal),
              body1: TextStyle(
                  color: colorTextOnPrimary,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic),
              caption: TextStyle(
                  color: colorTextOnPrimary,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic),
              button: TextStyle(
                  color: colorTextOnPrimary,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal),
            )),
      );
}
