import 'package:flutter/material.dart';

import 'utils.dart';

class NotificationsPage extends StatefulWidget {
  static const routeName = '/notifications';

  @override
  State<StatefulWidget> createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  var notificationTime;
  var notificationIsEnabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context).settings.arguments
        as HistoryToNotificationsArguments;

    notificationIsEnabled = arguments.notificationIsEnabled;
    notificationTime = arguments.notificationTime;
  }

  @override
  void initState() {
    super.initState();

    getNotificationTime().then((time) {
      if (time != null) {
        setState(() {
          notificationTime = time;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
      child: Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorSecondary,
                ),
                onPressed: () => Navigator.of(context).pop(
                    HistoryToNotificationsArguments(
                        notificationIsEnabled, notificationTime))),
            title: Text('Réglages')),
        body: ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                      leading: Icon(
                        Icons.notifications,
                        color: colorPrimary,
                      ),
                      title: Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.title,
                      ));
                case 1:
                  return Divider();
                case 2:
                  return NotificationTimeTile(this);
                default:
                  return null;
              }
            }),
      ),
      onWillPop: () async => Navigator.of(context).pop(
          HistoryToNotificationsArguments(
              notificationIsEnabled, notificationTime)));
}

class NotificationTimeTile extends StatefulWidget {
  final NotificationsPageState notificationsPageState;

  const NotificationTimeTile(this.notificationsPageState);

  @override
  State<StatefulWidget> createState() => NotificationTimeTileState();
}

class NotificationTimeTileState extends State<NotificationTimeTile> {
  @override
  Widget build(BuildContext context) {
    var leadingText = widget.notificationsPageState.notificationIsEnabled
        ? 'Tous les jours à'
        : 'Jamais';
    var hourText = widget.notificationsPageState.notificationTime == null
        ? '00:00'
        : '${widget.notificationsPageState.notificationTime.hour.toString().padLeft(2, '0')}:${widget.notificationsPageState.notificationTime.minute.toString().padLeft(2, '0')}';
    var style = widget.notificationsPageState.notificationIsEnabled
        ? Theme.of(context).textTheme.body2
        : Theme.of(context)
            .textTheme
            .body2
            .copyWith(color: colorTextOnPrimaryGreyed);
    return SwitchListTile(
        activeColor: colorAccent,
        inactiveThumbColor: colorGrayAccent,
        value: widget.notificationsPageState.notificationIsEnabled,
        onChanged: (newValue) {
          setState(() {
            widget.notificationsPageState.notificationIsEnabled = newValue;
          });
          setNotificationIsEnabled(newValue);
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              leadingText,
              style: style,
            ),
            widget.notificationsPageState.notificationIsEnabled
                ? FlatButton(
                    child: Text(
                      hourText,
                      style: style.copyWith(
                          color: colorAccent, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _pickTime,
                  )
                : null
          ].where((e) => e != null).toList(),
        ));
  }

  void _pickTime() async {
    // TODO more beautiful timepicker
    var selectedTime = await showTimePicker(
        initialTime: widget.notificationsPageState.notificationTime ??
            TimeOfDay(hour: 12, minute: 0),
        context: context,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: widget,
        ));
    if (selectedTime != null) {
      setState(() {
        widget.notificationsPageState.notificationTime = selectedTime;
      });
      setNotificationTime(selectedTime.hour, selectedTime.minute);
    }
  }
}
