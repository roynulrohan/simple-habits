// habit model

import 'package:simple_habits/db/database_providers.dart';

class Habit {
  int id;
  String title;
  bool reminders;
  String days;
  String time;
  int progress;
  int goal;
  bool isDone;

  Habit(
      {this.id,
      this.title,
      this.reminders,
      this.days,
      this.time,
      this.goal,
      this.progress,
      this.isDone});

  // map habit instance from database
  Habit.fromMap(Map<String, dynamic> map) {
    id = map[DatabaseProvider.COLUMN_ID];
    title = map[DatabaseProvider.COLUMN_TITLE];
    reminders = map[DatabaseProvider.COLUMN_REMINDERS] == 1;
    days = map[DatabaseProvider.COLUMN_DAYS];
    time = map[DatabaseProvider.COLUMN_TIME];
    goal = map[DatabaseProvider.COLUMN_GOAL];
    progress = map[DatabaseProvider.COLUMN_PROGRESS];
    isDone = map[DatabaseProvider.COLUMN_DONE] == 1;
  }

  // map habit to database
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      DatabaseProvider.COLUMN_TITLE: title,
      DatabaseProvider.COLUMN_REMINDERS: reminders ? 1 : 0,
      DatabaseProvider.COLUMN_DAYS: days,
      DatabaseProvider.COLUMN_TIME: time,
      DatabaseProvider.COLUMN_GOAL: goal,
      DatabaseProvider.COLUMN_PROGRESS: progress,
      DatabaseProvider.COLUMN_DONE: isDone ? 1 : 0
    };

    if (id != null) {
      map[DatabaseProvider.COLUMN_ID] = id;
    }

    return map;
  }
}
