import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_habits/about_page.dart';
import 'package:simple_habits/bloc/habit_bloc.dart';
import 'package:simple_habits/db/database_providers.dart';

import 'package:simple_habits/globals.dart';
import 'package:simple_habits/create_habit.dart';
import 'package:simple_habits/habit_list.dart';
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

    return BlocProvider<HabitBloc>(
        create: (context) => HabitBloc(),
        child: DefaultTabController(
            length: 2,
            child: MaterialApp(
              title: 'Simple Habits',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                  primaryColor: Colors.white,
                  textSelectionHandleColor: Colors.white,
                  fontFamily: 'Poppins'),
              home: MyHomePage(title: 'My Habits'),
            )));
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
  final _colorValues = ['Pink', 'Green', 'Blue'];
  String _currentColor;

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
  }

  // gets color from sharedPreferences and sets state
  void _getColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String selection = prefs.getString('color') ?? 'Pink';
    int value = prefs.getInt('colorValue') ?? Colors.pink.value;

    setState(() {
      themeColor = Color(value);
      _currentColor = selection;
    });
  }

  _promptDeleteAll(BuildContext context) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("Delete All",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      onPressed: () {
        DatabaseProvider.db.deleteAll().then(
            (value) => BlocProvider.of<HabitBloc>(context).add(SetHabits([])));
        Navigator.pop(context);
      },
    );
    Widget continueButton = FlatButton(
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
      title: Text("Confirmation"),
      content: Text(
          "Are you sure you want to delete all your habits?\n\nNothing will be recoverable."),
      actions: [
        cancelButton,
        continueButton,
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
                          flex: 3,
                          child: Container(
                            padding: EdgeInsets.only(bottom: 15),
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
                                  value: _currentColor,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _currentColor = newValue;
                                      themeColor = toColor(newValue);
                                      setColor(
                                          toColor(newValue).value, newValue);
                                    });
                                  },
                                  items: _colorValues.map((String value) {
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
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value.toLowerCase() == 'delete all') {
                    _promptDeleteAll(context);
                  } else if (value.toLowerCase() == 'new habit') {
                    Navigator.of(context).push(_createRoute(CreateHabitScreen(
                      Habit(),
                      0,
                    )));
                  }
                },
                itemBuilder: (BuildContext context) {
                  return {'Delete All', 'New Habit'}.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Center(
                        child: Text(
                          choice,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }).toList();
                },
              ),
            ],
            bottom: TabBar(
              indicatorColor: themeColor,
              labelColor: themeColor,
              unselectedLabelColor: Colors.black,
              onTap: (index) {},
              tabs: [
                Tab(
                  child: Text("Today"),
                ),
                Tab(child: Text("All Habits")),
              ],
            )),
        body: TabBarView(
          children: [HabitList(0), HabitList(1)],
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
