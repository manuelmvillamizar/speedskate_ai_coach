import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'training_history_service.dart';

class HistoryChartScreen extends StatelessWidget {
  const HistoryChartScreen({super.key});

  List<FlSpot> spots(List<double> values) {
    return values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final history = context.watch<TrainingHistoryService>();

    final skateValues = history.entries.map((e) => e.skateKm).toList();
    final bikeValues = history.entries.map((e) => e.bikeKm).toList();
    final gymValues = history.entries.map((e) => e.gymKg / 1000).toList();
    final minutesValues = history.entries
        .map((e) => e.minutes.toDouble())
        .toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppText.t(
              lang,
              'Gráficas de carga',
              'Load charts',
              'Belastungsdiagramme',
            ),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.t(
              lang,
              'Visualiza la evolución de kilómetros, kilos y minutos acumulados.',
              'View the evolution of kilometers, kilograms and accumulated minutes.',
              'Sieh die Entwicklung von Kilometern, Kilogramm und Minuten.',
            ),
          ),
          const SizedBox(height: 16),

          if (history.entries.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppText.t(
                    lang,
                    'Aún no hay datos. Genera un día de entrenamiento para llenar el historial.',
                    'No data yet. Generate a training day to fill the history.',
                    'Noch keine Daten. Erstelle einen Trainingstag, um den Verlauf zu füllen.',
                  ),
                ),
              ),
            )
          else ...[
            _ChartCard(
              title: AppText.t(lang, 'Km patines', 'Skating km', 'Skating-km'),
              values: skateValues,
              suffix: 'km',
            ),
            _ChartCard(
              title: AppText.t(lang, 'Km bicicleta', 'Bike km', 'Rad-km'),
              values: bikeValues,
              suffix: 'km',
            ),
            _ChartCard(
              title: AppText.t(lang, 'Gimnasio', 'Gym', 'Krafttraining'),
              values: gymValues,
              suffix: 'k kg',
            ),
            _ChartCard(
              title: AppText.t(lang, 'Minutos', 'Minutes', 'Minuten'),
              values: minutesValues,
              suffix: 'min',
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<double> values;
  final String suffix;

  const _ChartCard({
    required this.title,
    required this.values,
    required this.suffix,
  });

  double get maxY {
    if (values.isEmpty) return 10;
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 10;
    return max * 1.25;
  }

  @override
  Widget build(BuildContext context) {
    final spots = values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY,
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              'D${value.toInt() + 1}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('�sltimo: ${values.last.toStringAsFixed(1)} $suffix'),
            ],
          ),
        ),
      ),
    );
  }
}


