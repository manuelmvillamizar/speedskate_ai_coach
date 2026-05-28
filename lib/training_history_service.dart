import 'package:flutter/material.dart';

class TrainingHistoryEntry {
  final DateTime date;
  final double skateKm;
  final double bikeKm;
  final double gymKg;
  final int minutes;
  final String physiologyStatus;
  final String adjustment;

  TrainingHistoryEntry({
    required this.date,
    required this.skateKm,
    required this.bikeKm,
    required this.gymKg,
    required this.minutes,
    required this.physiologyStatus,
    required this.adjustment,
  });
}

class TrainingHistoryService extends ChangeNotifier {
  final List<TrainingHistoryEntry> _entries = [];

  List<TrainingHistoryEntry> get entries => List.unmodifiable(_entries);

  void addEntry(TrainingHistoryEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }

  void deleteEntry(int index) {
    _entries.removeAt(index);
    notifyListeners();
  }

  double get totalSkateKm {
    return _entries.fold(0, (sum, e) => sum + e.skateKm);
  }

  double get totalBikeKm {
    return _entries.fold(0, (sum, e) => sum + e.bikeKm);
  }

  double get totalGymKg {
    return _entries.fold(0, (sum, e) => sum + e.gymKg);
  }

  int get totalMinutes {
    return _entries.fold(0, (sum, e) => sum + e.minutes);
  }
}


