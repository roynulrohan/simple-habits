import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

    // get habits from db and add to blocprovider
    DatabaseProvider.db.getHabits().then(
      (habitList) {
        BlocProvider.of<HabitBloc>(context).add(SetHabits(habitList));
      },
    );
  }

  // function to delete habit
  void _removeHabit(int key) {
    DatabaseProvider.db.delete(key).then((_) {
      BlocProvider.of<HabitBloc>(context).add(
        DeleteHabit(key),
      );
    });
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
                      deleteFunc: () => _removeHabit(habit.id));
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
                      deleteFunc: () => _removeHabit(habit.id));
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
