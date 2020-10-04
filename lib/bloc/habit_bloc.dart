import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_habits/models/habit.dart';

class HabitBloc extends Bloc<HabitEvent, List<Habit>> {
  HabitBloc() : super(List<Habit>());
  @override
  Stream<List<Habit>> mapEventToState(HabitEvent event) async* {
    if (event is SetHabits) {
      yield event.habitList;
    } else if (event is AddHabit) {
      List<Habit> newState = List.from(state);
      if (event.newHabit != null) {
        newState.add(event.newHabit);
      }
      yield newState;
    } else if (event is DeleteHabit) {
      List<Habit> newState = List.from(state);
      newState.removeAt(
          newState.indexWhere((element) => element.id == event.habitKey));
      yield newState;
    } else if (event is UpdateHabit) {
      List<Habit> newState = List.from(state);
      newState[newState.indexWhere((element) => element.id == event.habitKey)] =
          event.newHabit;

      yield newState;
    }
  }
}

abstract class HabitEvent {}

class SetHabits extends HabitEvent {
  List<Habit> habitList;

  SetHabits(List<Habit> habits) {
    habitList = habits;
  }
}

class AddHabit extends HabitEvent {
  Habit newHabit;

  AddHabit(Habit habit) {
    newHabit = habit;
  }
}

class DeleteHabit extends HabitEvent {
  int habitKey;

  DeleteHabit(int key) {
    habitKey = key;
  }
}

class UpdateHabit extends HabitEvent {
  Habit newHabit;
  int habitKey;

  UpdateHabit(int key, Habit habit) {
    newHabit = habit;
    habitKey = key;
  }
}
