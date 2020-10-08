import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:simple_habits/bloc/habit_bloc.dart';
import 'package:simple_habits/create_habit.dart';
import 'package:simple_habits/db/database_providers.dart';
import 'package:simple_habits/globals.dart';
import 'package:simple_habits/models/habit.dart';

class HabitCard extends StatefulWidget {
  // takes in habit model, delete function, and edit callback
  HabitCard({Key key, this.habit, this.deleteFunc}) : super(key: key);

  final Habit habit;
  final Function deleteFunc;

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
  }

  @override
  void dispose() {
    super.dispose();

    // if habit is being deleted then cancels all future notifications
    if (_habit.reminders) {
      _cancelNotifications();
    }
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
  void _incrementProgress() {
    setState(() {});
    // switches state and increments or decrements based on case and then writes to database
    if (_habit.isDone) {
      setState(() {
        _habit.progress--;
        _habit.isDone = false;
      });

      // updates to database
      DatabaseProvider.db.update(_habit).then(
            (storedHabit) => BlocProvider.of<HabitBloc>(context).add(
              UpdateHabit(_habit.id, _habit),
            ),
          );
    } else {
      setState(() {
        _habit.progress++;
        _habit.isDone = true;
      });
      // updates to database
      DatabaseProvider.db.update(_habit).then(
            (storedHabit) => BlocProvider.of<HabitBloc>(context).add(
              UpdateHabit(_habit.id, _habit),
            ),
          );
    }
  }

  // toggles reminder notifications
  void toggleReminders() {
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
    DatabaseProvider.db.update(_habit).then(
          (storedHabit) => BlocProvider.of<HabitBloc>(context).add(
            UpdateHabit(_habit.id, _habit),
          ),
        );
  }

  // creates route to edit page with passing current state of habit
  void edit() {
    Navigator.of(context).push(_createRoute(_habit));
  }

  // callback function to updateCard current state to what's been passed from editing
  void updateCard(Habit habit) {
    _cancelNotifications();

    setState(() {
      _habit = habit;
    });

    if (_habit.reminders) {
      _setNotifications();
    }

    DatabaseProvider.db.update(_habit).then(
          (storedHabit) => BlocProvider.of<HabitBloc>(context).add(
            UpdateHabit(_habit.id, _habit),
          ),
        );
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
        padding: EdgeInsets.only(top: 5, left: 10, right: 10),
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
