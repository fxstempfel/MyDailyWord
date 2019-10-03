import 'package:flutter/material.dart';

import 'favorites_page.dart';
import 'history_page.dart';
import 'word_page.dart';


// for alarm manager, see https://github.com/marcmo/flutter_alarm_manager_example/tree/master/lib
// for notifications, see https://github.com/robindijkhof/flutter_noti
// to use both: https://stackoverflow.com/questions/57501404/flutter-android-combine-alarmmanager-with-notifications
void main() => runApp(DailyWordApp());

class DailyWordApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Daily Word',
      color: Colors.blue,
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
    );
  }
}
