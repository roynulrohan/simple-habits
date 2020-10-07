import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_habits/bloc/habit_bloc.dart';
import 'package:simple_habits/db/database_providers.dart';
import 'package:simple_habits/globals.dart';
import 'package:simple_habits/habit_card.dart';
import 'package:simple_habits/models/habit.dart';

class HabitList extends StatefulWidget {
  HabitList(this.mode, {Key key}) : super(key: key);

  // indicate whether all habits or current day's habits will be shown
  final int mode;
  @override
  _HabitListState createState() => _HabitListState();
}

class _HabitListState extends State<HabitList> {
  @override
  void initState() {
    super.initState();

    // checks date then gets habitList from db and adds to BlocProvider based on return statement
    // to see if weekly and/or daily progress needs to reset
    checkDate().then((value) {
      if (value == 1) {
        DatabaseProvider.db.getHabits(uncheck: true).then(
          (habitList) {
            BlocProvider.of<HabitBloc>(context).add(SetHabits(habitList));
          },
        );
      } else if (value == 2) {
        DatabaseProvider.db.getHabits(uncheck: true, resetProgress: true).then(
          (habitList) {
            BlocProvider.of<HabitBloc>(context).add(SetHabits(habitList));
          },
        );
      } else {
        DatabaseProvider.db.getHabits().then(
          (habitList) {
            BlocProvider.of<HabitBloc>(context).add(SetHabits(habitList));
          },
        );
      }
    });
  }

  // function that compares current date to date stored in prefs to know if it's a new day
  Future<int> checkDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String prevDate = prefs.getString('prevDate') ?? DateTime.now().toString();
    var today = DateTime.now();

    // if it is a new day then it resets the checked status on habit
    if (today.day != DateTime.parse(prevDate).day) {
      prefs.setString('prevDate', today.toString());

      // if it's a monday then it resets all weekly progress
      if (today.weekday == DateTime.monday) {
        return 2;
      } else {
        return 1;
      }
    } else {
      prefs.setString('prevDate', prevDate.toString());
    }

    return 0;
  }

  // function to delete habit
  void _removeHabit(BuildContext context, Habit habit) {
    Widget confirmButton = FlatButton(
      child: Text("Delete",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      onPressed: () {
        DatabaseProvider.db.delete(habit.id).then((_) {
          BlocProvider.of<HabitBloc>(context).add(
            DeleteHabit(habit.id),
          );
        });
        Navigator.pop(context);
      },
    );
    Widget cancelButton = FlatButton(
      child: Text(
        "Cancel",
        style: TextStyle(color: themeColor),
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Deleting Habit"),
      content: Text("Are you sure you want to delete\n\"${habit.title}\"?"),
      actions: [
        confirmButton,
        cancelButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  // widget with full list of all HabitCards
  Widget _buildAllHabits() {
    return BlocConsumer<HabitBloc, List<Habit>>(
      builder: (context, habitList) {
        // check if habit's exist at all
        return habitList.isEmpty
            ? Center(
                child: Text(
                'You have no habits at all.\nTap the + button to add one!',
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ))
            : ListView.builder(
                itemBuilder: (context, int index) {
                  Habit habit = habitList[index];

                  return HabitCard(
                      key: ValueKey((habit.id.toString() + habit.title)),
                      habit: habit,
                      deleteFunc: () => _removeHabit(context, habit));
                },
                itemCount: habitList.length,
              );
      },
      // listener for state changes to list
      listener: (BuildContext context, habitList) {
        // on state change, sorts habitCards by time
        habitList.sort((a, b) {
          var x = DateFormat.jm().parse(a.time);
          var y = DateFormat.jm().parse(b.time);

          return x.compareTo(y);
        });
      },
    );
  }

  // wdiget with current day's habits only
  Widget _buildTodayHabits() {
    return BlocConsumer<HabitBloc, List<Habit>>(
      builder: (context, habitList) {
        // filtered list by matching day's to current day
        List<Habit> filteredList = [];
        filteredList = habitList
            .where((element) =>
                element.days
                    .split(',')
                    .map(int.parse)
                    .toList()[dayCorrector(DateTime.now().weekday - 1)] ==
                1)
            .toList();

        // first check if filtered list is empty to display text block
        // else returns ListView
        return filteredList.isEmpty
            ? Center(
                child: Text(
                'You have no habits for ' +
                    new DateFormat('EEEE').format(DateTime.now()) +
                    "s.",
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ))
            : ListView.builder(
                itemBuilder: (context, int index) {
                  Habit habit = filteredList[index];

                  return HabitCard(
                      key: ValueKey((habit.id.toString() + habit.title)),
                      habit: habit,
                      deleteFunc: () => _removeHabit(context, habit));
                },
                itemCount: filteredList.length,
              );
      },
      listener: (BuildContext context, habitList) {
        habitList.sort((a, b) {
          var x = DateFormat.jm().parse(a.time);
          var y = DateFormat.jm().parse(b.time);

          return x.compareTo(y);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 5, bottom: 5),
        // set child based on mode
        child: widget.mode == 0 ? _buildTodayHabits() : _buildAllHabits());
  }
}
