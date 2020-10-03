import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_habits/create_habit.dart';
import 'package:simple_habits/db/database_providers.dart';
import 'package:simple_habits/globals.dart';
import 'package:simple_habits/models/habit.dart';

class HabitCard extends StatefulWidget {
  // takes in habit model, delete function, and edit callback
  HabitCard({Key key, this.habit, this.deleteFunc, this.updateList})
      : super(key: key);

  final Function deleteFunc;
  final Habit habit;
  final Function updateList;

  @override
  _HabitCard createState() => _HabitCard(habit);
}

class _HabitCard extends State<HabitCard> {
  _HabitCard(this._habit);

  Habit _habit;

  @override
  void initState() {
    super.initState();

    // if reminders are enabled then pushes future notifications
    if (_habit.reminders) {
      _setNotifications();
    }

    checkDate();
  }

  @override
  void dispose() {
    super.dispose();

    // if habit is being deleted then cancels all future notifications
    if (_habit.reminders) {
      _cancelNotifications();
    }
  }

  // function that compares current date to date stored in prefs to know if it's a new day
  void checkDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String prevDate = prefs.getString('prevDate') ?? DateTime.now().toString();
    var today = DateTime.now();

    // if it is a new day then it resets the checked status on habit
    if (today.day != DateTime.parse(prevDate).day) {
      if (_habit.isDone) {
        _habit.isDone = false;
      } else {
        prefs.setString('prevDate', today.toString());
      }
    } else {
      prefs.setString('prevDate', prevDate.toString());
    }

    // if it's a monday then it resets all weekly progress
    if (today.weekday == DateTime.monday && !_habit.isDone) {
      _habit.progress = 0;
    }

    DatabaseProvider.db.update(_habit);
  }

  // checks selected weekdays and pushes weekly notifications for those days
  // each weekly notification is uniquely identified with '_habit.id + weekday index'
  void _setNotifications() {
    var days = _habit.days.split(',').map(int.parse).toList();

    for (int i = 0; i < 7; i++) {
      if (days[i] == 1) {
        scheduleNotification(int.parse(_habit.id.toString() + i.toString()),
            toDay(i), _habit.time, _habit.title);
      }
    }
  }

  // cancels future nofications
  void _cancelNotifications() {
    var days = _habit.days.split(',').map(int.parse).toList();

    for (int i = 0; i < 7; i++) {
      if (days[i] == 1) {
        cancelNotification(int.parse(_habit.id.toString() + i.toString()));
      }
    }
  }

  // called every time the check button is pressed
  void _incrementProgress() async {
    // first calls checkDate to see if it's a new day or not
    checkDate();
    setState(() {});
    // switches state and increments or decrements based on case and then writes to database
    if (_habit.isDone) {
      setState(() {
        _habit.progress--;
        _habit.isDone = false;
      });

      await DatabaseProvider.db.update(_habit);
    } else {
      setState(() {
        _habit.progress++;
        _habit.isDone = true;
      });

      await DatabaseProvider.db.update(_habit);
    }
  }

  // toggles reminder notifications
  void toggleReminders() async {
    // toggle
    if (_habit.reminders) {
      setState(() {
        _habit.reminders = false;
      });
      _cancelNotifications(); // cancels all future notifications
    } else {
      setState(() {
        _habit.reminders = true;
      });
      _setNotifications(); // sets future notifications
    }

    // updates to database

    await DatabaseProvider.db.update(_habit);
  }

  // creates route to edit page with passing current state of habit
  void edit() {
    Navigator.of(context).push(_createRoute(_habit));
  }

  // callback function to updateCard current state to what's been passed from editing
  void updateCard(Habit habit) async {
    _cancelNotifications();

    setState(() {
      _habit = habit;
    });

    if (_habit.reminders) {
      _setNotifications();
    }

    await DatabaseProvider.db.update(_habit);

    widget.updateList();
  }

  // creates transition to edit page
  Route _createRoute(Habit habit) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          CreateHabitScreen(
        habit,
        1,
        editCallback: updateCard,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Slidable library to implement swipe to delete
    return Container(
        padding: EdgeInsets.only(top: 5),
        child: Slidable(
            secondaryActions: [
              Container(
                  height: 90,
                  child: IconSlideAction(
                    caption: 'Delete',
                    color: Colors.red,
                    foregroundColor: Colors.black,
                    icon: Icons.delete,
                    onTap: widget.deleteFunc,
                  ))
            ],
            actionPane: SlidableBehindActionPane(),
            // GestureDetector to edit onTap or long press to delete
            child: GestureDetector(
                onTap: edit,
                onLongPress: widget.deleteFunc,
                child: Card(
                  elevation: 7,
                  child: Container(
                      width: double.infinity,
                      height: 90,
                      child: Row(
                        children: <Widget>[
                          // title and time
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(bottom: 5.0),
                                  child: Text(_habit.title,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Text(_habit.time),
                              ],
                            ),
                          ),

                          // notification button
                          Expanded(
                              flex: 1,
                              child: Container(
                                height: double.infinity,
                                color: Colors.orange,
                                child: FlatButton(
                                    onPressed: () => toggleReminders(),
                                    child: Icon(_habit.reminders
                                        ? Icons.notifications_active
                                        : Icons.notifications_off)),
                              )),

                          // goal progress
                          Expanded(
                            flex: 1,
                            child: Container(
                                height: double.infinity,
                                color: Colors.purple,
                                alignment: Alignment.center,
                                child: Text(
                                  _habit.progress.toString() +
                                      '/' +
                                      _habit.goal.toString(),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white),
                                )),
                          ),

                          // check button
                          Expanded(
                              flex: 1,
                              child: Container(
                                height: double.infinity,
                                color: _habit.isDone == true
                                    ? Colors.green
                                    : Colors.grey,
                                child: FlatButton(
                                    onPressed: () => _incrementProgress(),
                                    child: Icon(Icons.done)),
                              ))
                        ],
                      )),
                ))));
  }
}
