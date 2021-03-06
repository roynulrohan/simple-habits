import 'package:simple_habits/models/habit.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart';

class DatabaseProvider {
  static const String TABLE_HABIT = "habit";
  static const String COLUMN_ID = "id";
  static const String COLUMN_TITLE = "title";
  static const String COLUMN_REMINDERS = "reminders";
  static const String COLUMN_DAYS = "days";
  static const String COLUMN_TIME = "time";
  static const String COLUMN_GOAL = "goal";
  static const String COLUMN_PROGRESS = "progress";
  static const String COLUMN_DONE = "done";

  DatabaseProvider._();
  static final DatabaseProvider db = DatabaseProvider._();

  Database _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database;
    }

    _database = await createDatabase();

    return _database;
  }

  // create db
  Future<Database> createDatabase() async {
    String dbPath = await getDatabasesPath();

    return await openDatabase(
      join(dbPath, 'habitDB.db'),
      version: 1,
      onCreate: (Database database, int version) async {
        print("Creating habit table");

        await database.execute(
          "CREATE TABLE $TABLE_HABIT ("
          "$COLUMN_ID INTEGER PRIMARY KEY,"
          "$COLUMN_TITLE TEXT,"
          "$COLUMN_REMINDERS INTEGER,"
          "$COLUMN_DAYS TEXT,"
          "$COLUMN_TIME TEXT,"
          "$COLUMN_GOAL INTEGER,"
          "$COLUMN_PROGRESS INTEGER,"
          "$COLUMN_DONE INTEGER"
          ")",
        );
      },
    );
  }

  // get all habits - takes parameters to see if weekly or daily progress needs to reset
  Future<List<Habit>> getHabits(
      {bool uncheck = false, bool resetProgress = false}) async {
    final db = await database;

    var habits = await db.query(TABLE_HABIT, columns: [
      COLUMN_ID,
      COLUMN_TITLE,
      COLUMN_REMINDERS,
      COLUMN_DAYS,
      COLUMN_TIME,
      COLUMN_GOAL,
      COLUMN_PROGRESS,
      COLUMN_DONE
    ]);

    List<Habit> habitList = List<Habit>();

    habits.forEach((element) {
      Habit habit = Habit.fromMap(element);

      // reset daily
      if (uncheck) {
        habit.isDone = false;
      }

      // reset weekly
      if (resetProgress) {
        habit.progress = 0;
      }

      // update
      db.update(
        TABLE_HABIT,
        habit.toMap(),
        where: "id = ?",
        whereArgs: [habit.id],
      );

      habitList.add(habit);
    });

    return habitList;
  }

  // insert habit
  Future<Habit> insert(Habit habit) async {
    final db = await database;
    habit.id = await db.insert(TABLE_HABIT, habit.toMap());
    return habit;
  }

  // delete habit
  Future<int> delete(int id) async {
    final db = await database;

    return await db.delete(
      TABLE_HABIT,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // delete all habits
  Future<int> deleteAll() async {
    final db = await database;

    return await db.delete(
      TABLE_HABIT,
    );
  }

  // update given habit
  Future<int> update(Habit habit) async {
    final db = await database;

    return await db.update(
      TABLE_HABIT,
      habit.toMap(),
      where: "id = ?",
      whereArgs: [habit.id],
    );
  }
}
