import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

// ============================================================
// DAILY SUMMARY MODEL
// ============================================================
class GarminImportedDailySummary {
  final DateTime? date;
  final int? restingHeartRate;
  final int? stress;
  final int? sleepMinutes;
  final double? hrv;
  final int? bodyBattery;

  const GarminImportedDailySummary({
    required this.date,
    required this.restingHeartRate,
    required this.stress,
    required this.sleepMinutes,
    required this.hrv,
    required this.bodyBattery,
  });

  factory GarminImportedDailySummary.fromMap(Map<String, dynamic> map) {
    return GarminImportedDailySummary(
      date: DateTime.tryParse(map['date']?.toString() ?? ''),
      restingHeartRate: _toInt(map['restingHeartRate']),
      stress: _toInt(map['stress']),
      sleepMinutes: _toInt(map['sleepMinutes']),
      hrv: _toDouble(map['hrv']),
      bodyBattery: _toInt(map['bodyBattery']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

// ============================================================
// TRAINING MODEL
// ============================================================
class GarminImportedTraining {
  final String source;
  final String file;
  final String sportType;
  final DateTime? startTime;
  final DateTime? endTime;

  final double durationMinutes;
  final double distanceKm;
  final double averageHeartRate;
  final double maxHeartRate;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double averageCadence;
  final double maxCadence;
  final double zone1Minutes;
  final double zone2Minutes;
  final double zone3Minutes;
  final double zone4Minutes;
  final double zone5Minutes;
  final double highIntensityMinutes;
  final double highIntensityRatio;
  final double internalLoad;
  final int recordCount;

  const GarminImportedTraining({
    required this.source,
    required this.file,
    required this.sportType,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.distanceKm,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.averageCadence,
    required this.maxCadence,
    required this.zone1Minutes,
    required this.zone2Minutes,
    required this.zone3Minutes,
    required this.zone4Minutes,
    required this.zone5Minutes,
    required this.highIntensityMinutes,
    required this.highIntensityRatio,
    required this.internalLoad,
    required this.recordCount,
  });

  factory GarminImportedTraining.fromMap(Map<String, dynamic> map) {
    return GarminImportedTraining(
      source: map['source']?.toString() ?? 'garmin',
      file: map['file']?.toString() ?? '',
      sportType: map['sportType']?.toString() ?? 'unknown',
      startTime: DateTime.tryParse(map['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(map['endTime']?.toString() ?? ''),
      durationMinutes: _toDouble(map['durationMinutes']),
      distanceKm: _toDouble(map['distanceKm']),
      averageHeartRate: _toDouble(map['averageHeartRate']),
      maxHeartRate: _toDouble(map['maxHeartRate']),
      averageSpeedKmh: _toDouble(map['averageSpeedKmh']),
      maxSpeedKmh: _toDouble(map['maxSpeedKmh']),
      averageCadence: _toDouble(map['averageCadence']),
      maxCadence: _toDouble(map['maxCadence']),
      zone1Minutes: _toDouble(map['zone1Minutes']),
      zone2Minutes: _toDouble(map['zone2Minutes']),
      zone3Minutes: _toDouble(map['zone3Minutes']),
      zone4Minutes: _toDouble(map['zone4Minutes']),
      zone5Minutes: _toDouble(map['zone5Minutes']),
      highIntensityMinutes: _toDouble(map['highIntensityMinutes']),
      highIntensityRatio: _toDouble(map['highIntensityRatio']),
      internalLoad: _toDouble(map['internalLoad']),
      recordCount: _toInt(map['recordCount']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// ============================================================
// RESULT MODEL
// ============================================================
class GarminJsonImportResult {
  final DateTime? generatedAt;
  final GarminImportedDailySummary? dailySummary;
  final GarminImportedTraining? latestTraining;
  final List<GarminImportedTraining> recentTrainings;

  const GarminJsonImportResult({
    required this.generatedAt,
    required this.dailySummary,
    required this.latestTraining,
    required this.recentTrainings,
  });
}

// ============================================================
// IMPORTER
// ============================================================
class GarminJsonImporter {
  static Future<GarminJsonImportResult> readFromPath(String path) async {
    String raw;

    final file = File(path);

    if (await file.exists()) {
      raw = await file.readAsString();
    } else {
      raw = await rootBundle.loadString(path);
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final dailyRaw = decoded['dailySummary'];
    final latestRaw = decoded['latestTraining'];
    final recentRaw = decoded['recentTrainings'];

    final dailySummary = dailyRaw is Map
        ? GarminImportedDailySummary.fromMap(
            Map<String, dynamic>.from(dailyRaw),
          )
        : null;

    final latest = latestRaw is Map
        ? GarminImportedTraining.fromMap(Map<String, dynamic>.from(latestRaw))
        : null;

    final recent = recentRaw is List
        ? recentRaw.whereType<Map>().map((item) {
            return GarminImportedTraining.fromMap(
              Map<String, dynamic>.from(item),
            );
          }).toList()
        : <GarminImportedTraining>[];

    return GarminJsonImportResult(
      generatedAt: DateTime.tryParse(decoded['generatedAt']?.toString() ?? ''),
      dailySummary: dailySummary,
      latestTraining: latest,
      recentTrainings: recent,
    );
  }
}

