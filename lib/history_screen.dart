import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'training_history_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final history = context.watch<TrainingHistoryService>();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppText.t(
              lang,
              'Historial de carga',
              'Load history',
              'Belastungsverlauf',
            ),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.t(
              lang,
              'Acumula kilómetros, kilos, minutos y ajustes realizados.',
              'Accumulates kilometers, kilograms, minutes and adjustments.',
              'Sammelt Kilometer, Kilogramm, Minuten und Anpassungen.',
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.summarize),
              title: Text(
                AppText.t(
                  lang,
                  'Totales acumulados',
                  'Accumulated totals',
                  'Gesamtsummen',
                ),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                _Row(
                  label: AppText.t(lang, 'Patines', 'Skating', 'Skaten'),
                  value: '${history.totalSkateKm.toStringAsFixed(1)} km',
                ),
                _Row(
                  label: AppText.t(lang, 'Bicicleta', 'Bike', 'Rad'),
                  value: '${history.totalBikeKm.toStringAsFixed(1)} km',
                ),
                _Row(
                  label: AppText.t(lang, 'Gimnasio', 'Gym', 'Krafttraining'),
                  value: '${history.totalGymKg.toStringAsFixed(0)} kg',
                ),
                _Row(
                  label: AppText.t(lang, 'Minutos', 'Minutes', 'Minuten'),
                  value: '${history.totalMinutes}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (history.entries.isEmpty)
            Center(
              child: Text(
                AppText.t(
                  lang,
                  'Aún no hay días guardados.',
                  'No saved days yet.',
                  'Noch keine Tage gespeichert.',
                ),
              ),
            ),

          ...history.entries.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.history)),
                title: Text(formatDate(item.date)),
                subtitle: Text(
                  'Patines: ${item.skateKm.toStringAsFixed(1)} km · '
                  'Bici: ${item.bikeKm.toStringAsFixed(1)} km · '
                  'Gym: ${item.gymKg.toStringAsFixed(0)} kg\n'
                  '${item.physiologyStatus} · ${item.adjustment}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => history.deleteEntry(index),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


