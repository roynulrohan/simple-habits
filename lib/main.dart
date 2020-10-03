import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_habits/about_page.dart';
import 'package:simple_habits/db/database_providers.dart';

import 'package:simple_habits/globals.dart';
import 'package:simple_habits/habit_card.dart';
import 'package:simple_habits/create_habit.dart';
import 'package:simple_habits/models/habit.dart';

void main() {
  runApp(MyApp());
}

// root widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // locking orientation to portrait only
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    return DefaultTabController(
        length: 2,
        child: MaterialApp(
          title: 'Simple Habits',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              primaryColor: Colors.white,
              textSelectionHandleColor: Colors.white,
              fontFamily: 'Poppins'),
          home: MyHomePage(title: 'My Habits'),
        ));
  }
}

// Main Home Page
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Habit> _habitList = [];
  final _dropdownValues = ['Pink', 'Green', 'Blue'];
  String _currentDropdownValue;

  @override
  void initState() {
    super.initState();

    // init notifications plugin
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOs = IOSInitializationSettings();
    var initSetttings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOs);
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    flutterLocalNotificationsPlugin.initialize(initSetttings);

    _getColor();
    updateList();
  }

  // updates List of Habits
  void updateList() {
    DatabaseProvider.db.getHabits().then((list) {
      setState(() {
        _habitList = list;
      });
    });

    print("Called");
  }

  // delete habit from db
  void _removeHabit(int key) async {
    await DatabaseProvider.db.delete(key);
    updateList();
  }

  // gets color from sharedPreferences and sets state
  void _getColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String selection = prefs.getString('color') ?? 'Pink';
    int value = prefs.getInt('colorValue') ?? Colors.pink.value;

    setState(() {
      themeColor = Color(value);
      _currentDropdownValue = selection;
    });
  }

  // build full list of HabitCard
  Widget _buildAllHabits() {
    // check if habit's exist at all
    return _habitList.isEmpty
        ? Center(
            child: Text(
            'You have no habits at all.\nTap the + button to add one!',
            style: TextStyle(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ))
        : ListView.builder(
            padding: EdgeInsets.only(left: 10, right: 10),
            itemBuilder: (BuildContext context, int index) {
              Habit habit = _habitList[index];

              // initialize HabitCard by passing habit model, deleting function and editing callback
              return HabitCard(
                  habit: habit,
                  deleteFunc: () => _removeHabit(habit.id),
                  updateList: updateList);
            },
            itemCount: _habitList.length,
          );
  }

  // build list with current day's habits only
  Widget _buildTodayHabits() {
    // filtered list by matching day's to current day
    var filteredList = _habitList.where((element) =>
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
            padding: EdgeInsets.only(left: 10, right: 10),
            itemBuilder: (BuildContext context, int index) {
              Habit habit = _habitList[index];

              // returning habitCards if day matches
              if (habit.days
                      .split(',')
                      .map(int.parse)
                      .toList()[dayCorrector(DateTime.now().weekday - 1)] ==
                  1) {
                return HabitCard(
                    habit: habit,
                    deleteFunc: () => _removeHabit(habit.id),
                    updateList: updateList);
              }
            },
            itemCount: _habitList.length,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // DRAWER
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // DRAWER HEADER
              DrawerHeader(
                child: Container(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text('Simple Habits',
                              style: TextStyle(fontSize: 20))),
                      Expanded(
                          flex: 4,
                          child: Container(
                            padding: EdgeInsets.only(bottom: 10),
                            child:
                                Image(image: AssetImage('assets/img/icon.png')),
                          )),
                      Expanded(
                          flex: 1,
                          child: Text('by Roynul Rohan',
                              style: TextStyle(fontSize: 14)))
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  color: themeColor,
                ),
              ),

              // DRAWER TILES
              Container(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.only(top: 10),
                        child: ListTile(
                            title: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Container(
                                  child: Text(
                                "Theme Color",
                                style: TextStyle(fontSize: 14),
                              )),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                  child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                  hint: Text("Select Color"),
                                  value: _currentDropdownValue,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _currentDropdownValue = newValue;
                                      themeColor = toColor(newValue);
                                      setColor(
                                          toColor(newValue).value, newValue);
                                    });
                                  },
                                  items: _dropdownValues.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(color: toColor(value)),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )),
                            )
                          ],
                        )),
                      ),
                      Container(
                          padding: EdgeInsets.only(top: 10),
                          child: ListTile(
                            title:
                                Text('About', style: TextStyle(fontSize: 14)),
                            subtitle: Text(
                              'Info, Credits, Support, Version',
                              style: TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.of(context)
                                  .push(_createRoute(AboutPage()));
                            },
                          ))
                    ],
                  ))
            ],
          ),
        ),
        appBar: AppBar(
            centerTitle: true,
            title: Text(widget.title),
            bottom: TabBar(
              indicatorColor: themeColor,
              labelColor: themeColor,
              unselectedLabelColor: Colors.black,
              onTap: (index) {
                updateList();
              },
              tabs: [
                Tab(
                  child: Text("Today"),
                ),
                Tab(child: Text("All Habits")),
              ],
            )),
        body: Container(
          padding: EdgeInsets.only(top: 5, bottom: 5),
          child: TabBarView(
            children: [_buildTodayHabits(), _buildAllHabits()],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          elevation: 10,
          tooltip: 'New Habit',
          backgroundColor: themeColor,
          onPressed: () {
            Navigator.of(context).push(_createRoute(CreateHabitScreen(
              Habit(),
              0,
              updateList: updateList,
            )));
          },
        ));
  }

  // animation to create_habit page
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
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
}
