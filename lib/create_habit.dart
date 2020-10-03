import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple_habits/globals.dart';
import 'package:simple_habits/models/habit.dart';
import 'package:weekday_selector/weekday_selector.dart';

import 'db/database_providers.dart';

class CreateHabitScreen extends StatefulWidget {
  CreateHabitScreen(this.habit, this.mode,
      {this.updateList, this.editCallback});

  final Habit habit; // habit instance will be passed if updating, else null
  final int mode; // track if creating new habit or updating existing one
  final Function updateList; // updateList callback
  final Function editCallback; // widget editCallback

  @override
  _CreateHabitScreenState createState() => _CreateHabitScreenState(habit);
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  _CreateHabitScreenState(this._habit);

  Habit _habit;

  bool _isSwitched = false; // reminders switch
  TimeOfDay _pickedTime = TimeOfDay.now(); // picked time
  TextEditingController _titleController =
      TextEditingController(); // title text controller
  var _weekdayValues = List.filled(7, false); // weekday selector _weekdayValues
  double _currentSliderValue = 1; // goal slider

  // color variables
  Color _background = Colors.white;
  Color _textColor = Colors.black;

  @override
  void initState() {
    super.initState();

    // if mode is to update, then set current values to existing values of _habit
    if (widget.mode == 1) {
      _isSwitched = _habit.reminders;
      _pickedTime = TimeOfDay.fromDateTime(DateFormat.jm().parse(_habit.time));
      _titleController.text = _habit.title;
      _currentSliderValue = _habit.goal.toDouble();

      var temp = _habit.days.split(',').map(int.parse).toList();

      for (int i = 0; i < 7; i++) {
        _weekdayValues[i] = temp[i] == 1;
      }
    }
  }

  // create/update habit
  void create() async {
    String days = _weekdayValues.map((i) => i ? 1 : 0.toString()).join(",");

    // create habit instance with current values
    Habit habit = Habit(
        title: _titleController.text,
        reminders: _isSwitched,
        days: days,
        time: _pickedTime.format(context).toString(),
        goal: _currentSliderValue.toInt(),
        progress: widget.mode == 0 ? 0 : _habit.progress,
        isDone: widget.mode == 0 ? false : _habit.isDone);

    // storing to database if creating new one
    if (widget.mode == 0) {
      await DatabaseProvider.db.insert(habit);

      // update list callback
      widget.updateList();
    } else {
      // if updating
      // setting id to the same as the passed _habit instance
      habit.id = _habit.id;

      // update individual widget callback
      widget.editCallback(habit);
    }

    Navigator.pop(context);
  }

  // time picker
  Widget _selectTime() {
    return CupertinoDatePicker(
      initialDateTime: widget.mode == 0
          ? DateTime(0, 0, 0, _pickedTime.hour, 0)
          : DateTime(0, 0, 0, _pickedTime.hour, _pickedTime.minute),
      onDateTimeChanged: (DateTime newdate) {
        setState(() {
          _pickedTime = TimeOfDay.fromDateTime(newdate);
        });
      },
      minuteInterval: 1,
      mode: CupertinoDatePickerMode.time,
    );
  }

  // function to create card's, avoiding unnecessary repitition of code
  Widget _makeCard(Widget child) {
    return Expanded(
        child: Container(
      padding: EdgeInsets.only(top: 5),
      child: Card(
          elevation: 10,
          child: Container(
              child: Container(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        width: 2,
                        color: Colors.white,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  child: child))),
    ));
  }

  // Scaffold -> GestureDetector -> Container -> Column of Card Widgets
  // GestureDetector to unfocus keyboard on touch anywhere other than title
  // Container that expands to 60% of context
  // Each Card widget contains Row of Expanded Widgets for Text and Value Selectors(button, slider etc)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.mode == 0 ? 'New Habit' : 'Update Habit'),
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: _background,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: Container(
          height: MediaQuery.of(context).size.height * .70,
          padding: EdgeInsets.only(left: 15, right: 15, top: 5),
          child: Column(
            children: [
              // TITLE FORM
              _makeCard(Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(left: 10, right: 10),
                margin: EdgeInsets.only(top: 5, bottom: 5),
                child: TextField(
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    controller: _titleController,
                    cursorColor: themeColor,
                    style: TextStyle(fontSize: 24.0, color: themeColor),
                    maxLength: 20,
                    maxLengthEnforced: true,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: "Title",
                      hintText: "Name your habit",
                      labelStyle: TextStyle(
                        fontSize: 18,
                        color: _textColor,
                      ),
                      hintStyle: TextStyle(fontSize: 22),
                      counterText: '',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    )),
              )),

              // WEEKDAY SELECTOR
              _makeCard(
                Column(
                  children: [
                    Expanded(
                        flex: 2,
                        child: WeekdaySelector(
                          selectedFillColor: themeColor,
                          elevation: 5,
                          onChanged: (int day) {
                            FocusScope.of(context)
                                .requestFocus(new FocusNode());
                            setState(() {
                              // Use module % 7 as Sunday's index in the array is 0 and
                              // DateTime.sunday constant integer value is 7.
                              final index = day % 7;

                              _weekdayValues[index] = !_weekdayValues[index];
                            });
                          },
                          values: _weekdayValues,
                        )),
                    Expanded(
                        flex: 1,
                        child: Container(
                            padding: EdgeInsets.only(bottom: 5),
                            child: FlatButton(
                                onPressed: () {
                                  if (_weekdayValues.contains(false)) {
                                    setState(() {
                                      _weekdayValues = List.filled(7, true);
                                    });
                                  } else {
                                    setState(() {
                                      _weekdayValues = List.filled(7, false);
                                    });
                                  }
                                },
                                child: Text(
                                  "Select/Deselect All",
                                  style: TextStyle(color: themeColor),
                                ))))
                  ],
                ),
              ),

              // GOAL SLIDER
              _makeCard(
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                          padding: EdgeInsets.only(left: 10, right: 5),
                          child: Text(
                            "Weekly Goal",
                            style: TextStyle(fontSize: 18.0, color: _textColor),
                          )),
                    ),
                    Expanded(
                        flex: 7,
                        child: Container(
                            padding: EdgeInsets.only(right: 10),
                            alignment: Alignment.centerRight,
                            child: Slider(
                              inactiveColor: themeColor.withOpacity(0.4),
                              activeColor: themeColor,
                              value: _currentSliderValue,
                              min: 1,
                              max: 7,
                              divisions: 6,
                              label: _currentSliderValue.round().toString(),
                              onChanged: (double value) {
                                setState(() {
                                  _currentSliderValue = value;
                                });
                              },
                            ))),
                    Expanded(
                      flex: 1,
                      child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.only(left: 10, right: 10),
                          child: Text(
                            _currentSliderValue.round().toString(),
                            style: TextStyle(fontSize: 20.0, color: themeColor),
                          )),
                    )
                  ],
                ),
              ),

              // REMINDERS SWITCH
              _makeCard(
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                          padding: EdgeInsets.only(left: 10),
                          child: Text(
                            "Reminders",
                            style: TextStyle(fontSize: 18.0, color: _textColor),
                          )),
                    ),
                    Container(
                        padding: EdgeInsets.only(right: 10),
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: _isSwitched,
                          inactiveThumbColor: themeColor,
                          activeColor: themeColor,
                          onChanged: (value) {
                            FocusScope.of(context)
                                .requestFocus(new FocusNode());
                            setState(() {
                              _isSwitched = value;
                            });
                          },
                        )),
                  ],
                ),
              ),

              // TIME PICKER
              // not using _makeCard for this to implement GestureDetector for time picker
              Expanded(
                  child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext builder) {
                              return Container(
                                  height: MediaQuery.of(context)
                                          .copyWith()
                                          .size
                                          .height /
                                      3,
                                  child: _selectTime());
                            });
                      },
                      child: Container(
                        padding: EdgeInsets.only(top: 5),
                        child: Card(
                            elevation: 10,
                            child: Container(
                                child: Container(
                                    padding: EdgeInsets.only(
                                      left: 10,
                                      right: 10,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          width: 2,
                                          color: Colors.white,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5.0))),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Container(
                                              padding:
                                                  EdgeInsets.only(left: 10),
                                              child: Text(
                                                "Time",
                                                style: TextStyle(
                                                    fontSize: 18.0,
                                                    color: _textColor),
                                              )),
                                        ),
                                        Container(
                                            padding: EdgeInsets.only(right: 10),
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              "${_pickedTime.format(context)}",
                                              style: TextStyle(
                                                  fontSize: 21.0,
                                                  color: themeColor),
                                            )),
                                      ],
                                    )))),
                      )))
            ],
          ),
        ),
      ),

      // used Builder for FAB to be able to use SnackBar
      floatingActionButton: new Builder(builder: (BuildContext context) {
        return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          FloatingActionButton(
            elevation: 10,
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            child: Icon(Icons.check),
            onPressed: () {
              // validate title first
              if (_titleController.text != '') {
                var weekdayCount = _weekdayValues
                    .where((element) => element == true)
                    .toList()
                    .length;

                // validate at least 1 weekday selected
                if (_weekdayValues.contains(true)) {
                  // validate for goal to <= day's selected
                  if (_currentSliderValue <= weekdayCount) {
                    create();
                  } else {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content:
                          Text("Goal cannot be greater than day's selected."),
                    ));
                  }
                } else {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.red,
                    content: Text("You must select at least 1 day."),
                  ));
                }
              } else {
                Scaffold.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('Please enter a title.'),
                ));
              }
            },
          ),
        ]);
      }),
    );
  }
}
