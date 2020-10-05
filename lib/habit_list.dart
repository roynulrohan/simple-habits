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

  final int mode;
  @override
  _HabitListState createState() => _HabitListState();
}

class _HabitListState extends State<HabitList> {
  @override
  void initState() {
    super.initState();

    DatabaseProvider.db.getHabits().then(
      (habitList) {
        BlocProvider.of<HabitBloc>(context).add(SetHabits(habitList));
      },
    );
  }

  // delete habit from db
  void _removeHabit(int key) {
    DatabaseProvider.db.delete(key).then((_) {
      BlocProvider.of<HabitBloc>(context).add(
        DeleteHabit(key),
      );
    });
  }

  // build full list of HabitCard
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
      listener: (BuildContext context, habitList) {
        habitList.sort((a, b) {
          var x = DateFormat.jm().parse(a.time);
          var y = DateFormat.jm().parse(b.time);

          return x.compareTo(y);
        });
      },
    );
  }

  // build list with current day's habits only
  Widget _buildTodayHabits() {
    return BlocConsumer<HabitBloc, List<Habit>>(
      builder: (context, habitList) {
        // filtered list by matching day's to current day
        var filteredList = habitList.where((element) =>
            element.days
                .split(',')
                .map(int.parse)
                .toList()[dayCorrector(DateTime.now().weekday - 1)] ==
            1);

        // first check if filtered list is empty to display text block
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
                  Habit habit = habitList[index];

                  // returning habitCards if day matches
                  if (habit.days
                          .split(',')
                          .map(int.parse)
                          .toList()[dayCorrector(DateTime.now().weekday - 1)] ==
                      1) {
                    return HabitCard(
                        key: ValueKey((habit.id.toString() + habit.title)),
                        habit: habit,
                        deleteFunc: () => _removeHabit(habit.id));
                  }
                },
                itemCount: habitList.length,
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
        child: widget.mode == 0 ? _buildTodayHabits() : _buildAllHabits());
  }
}
