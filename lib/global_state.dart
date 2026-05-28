import 'package:flutter/material.dart';

import 'app_language.dart';
import 'auto_adjust_screen.dart';
import 'gym_engine.dart';
import 'periodization_engine.dart';

class GlobalTrainingState extends ChangeNotifier {
  AutoPhysiologyStatus physiologyStatus = AutoPhysiologyStatus.green;
  PlannedTrainingType plannedType = PlannedTrainingType.speed;
  AutoAdjustedSession? adjustedSession;

  List<GymExercise> selectedGymExercises = [];

  PeriodizationMicrocycle? currentMicrocycle;
  int currentMicrocycleDayIndex = 0;
  bool automaticPeriodizationEnabled = true;

  void updatePhysiology(AutoPhysiologyStatus status) {
    physiologyStatus = status;
    notifyListeners();
  }

  void updatePlannedType(PlannedTrainingType type) {
    plannedType = type;
    notifyListeners();
  }

  void generateAdjustment() {
    adjustedSession = AutoAdjustEngine.adjust(
      lang: AppLanguage.es,
      physiologyStatus: physiologyStatus,
      plannedType: plannedType,
      plannedLoad: 80,
      plannedMinutes: 90,
      plannedKm: 15,
    );

    notifyListeners();
  }

  void addExerciseToGym(GymExercise exercise) {
    selectedGymExercises.add(exercise);
    notifyListeners();
  }

  void removeExerciseFromGym(int index) {
    if (index < 0 || index >= selectedGymExercises.length) return;

    selectedGymExercises.removeAt(index);
    notifyListeners();
  }

  void clearGymExercises() {
    selectedGymExercises.clear();
    notifyListeners();
  }

  void setMicrocycle(PeriodizationMicrocycle microcycle) {
    currentMicrocycle = microcycle;
    currentMicrocycleDayIndex = 0;
    notifyListeners();
  }

  void clearMicrocycle() {
    currentMicrocycle = null;
    currentMicrocycleDayIndex = 0;
    notifyListeners();
  }

  void setCurrentMicrocycleDay(int index) {
    if (currentMicrocycle == null) return;
    if (index < 0 || index >= currentMicrocycle!.days.length) return;

    currentMicrocycleDayIndex = index;
    notifyListeners();
  }

  void nextMicrocycleDay() {
    if (currentMicrocycle == null) return;

    if (currentMicrocycleDayIndex < currentMicrocycle!.days.length - 1) {
      currentMicrocycleDayIndex++;
      notifyListeners();
    }
  }

  void previousMicrocycleDay() {
    if (currentMicrocycleDayIndex > 0) {
      currentMicrocycleDayIndex--;
      notifyListeners();
    }
  }

  PeriodizationDay? get currentPeriodizationDay {
    if (currentMicrocycle == null) return null;
    if (currentMicrocycleDayIndex >= currentMicrocycle!.days.length) {
      return null;
    }

    return currentMicrocycle!.days[currentMicrocycleDayIndex];
  }

  bool get hasMicrocycle => currentMicrocycle != null;

  bool get progressionBlockedByFatigue {
    if (currentMicrocycle == null) return false;

    return currentMicrocycle!.progressionBlocked;
  }

  bool get shouldReduceTraining {
    return physiologyStatus == AutoPhysiologyStatus.orange ||
        physiologyStatus == AutoPhysiologyStatus.red;
  }

  bool get shouldForceRecovery {
    return physiologyStatus == AutoPhysiologyStatus.red;
  }

  bool get shouldBlockProgression {
    return progressionBlockedByFatigue ||
        physiologyStatus == AutoPhysiologyStatus.red;
  }
}


