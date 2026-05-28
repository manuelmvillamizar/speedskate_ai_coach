import 'package:flutter/material.dart';

import 'exercise_library.dart';
import 'exercise_model.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String search = '';
  ExerciseCategory? selectedCategory;

  List<Exercise> get filteredExercises {
    return ExerciseLibrary.exercises.where((exercise) {
      final matchesSearch =
          exercise.name.toLowerCase().contains(search.toLowerCase()) ||
          exercise.muscles.toLowerCase().contains(search.toLowerCase()) ||
          exercise.equipment.toLowerCase().contains(search.toLowerCase());

      final matchesCategory =
          selectedCategory == null || exercise.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  String categoryLabel(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        return 'Fuerza';
      case ExerciseCategory.machine:
        return 'Máquina';
      case ExerciseCategory.olympic:
        return 'Olímpico';
      case ExerciseCategory.plyometric:
        return 'Pliometría';
      case ExerciseCategory.core:
        return 'Core';
      case ExerciseCategory.mobility:
        return 'Movilidad';
    }
  }

  IconData categoryIcon(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        return Icons.fitness_center;
      case ExerciseCategory.machine:
        return Icons.precision_manufacturing;
      case ExerciseCategory.olympic:
        return Icons.flash_on;
      case ExerciseCategory.plyometric:
        return Icons.directions_run;
      case ExerciseCategory.core:
        return Icons.circle;
      case ExerciseCategory.mobility:
        return Icons.accessibility_new;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = filteredExercises;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Biblioteca de ejercicios PRO',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Busca ejercicios por nombre, músculo, equipo o categoría.',
          ),
          const SizedBox(height: 16),

          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar ejercicio',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                search = value;
              });
            },
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: selectedCategory == null,
                onSelected: (_) {
                  setState(() {
                    selectedCategory = null;
                  });
                },
              ),
              ...ExerciseCategory.values.map(
                (category) => ChoiceChip(
                  label: Text(categoryLabel(category)),
                  selected: selectedCategory == category,
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (exercises.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No se encontraron ejercicios.'),
              ),
            ),

          ...exercises.map(
            (exercise) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(categoryIcon(exercise.category)),
                ),
                title: Text(
                  exercise.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${categoryLabel(exercise.category)} · ${exercise.muscles} · ${exercise.equipment}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseDetailScreen(exercise: exercise),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  String categoryLabel(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        return 'Fuerza';
      case ExerciseCategory.machine:
        return 'Máquina';
      case ExerciseCategory.olympic:
        return 'Olímpico';
      case ExerciseCategory.plyometric:
        return 'Pliometría';
      case ExerciseCategory.core:
        return 'Core';
      case ExerciseCategory.mobility:
        return 'Movilidad';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              exercise.imagePath,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported, size: 80),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            exercise.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Chip(label: Text(categoryLabel(exercise.category))),

          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Descripción'),
              subtitle: Text(exercise.descriptionEs),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: const Text('Músculos'),
              subtitle: Text(exercise.muscles),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Nivel'),
              subtitle: Text(exercise.level),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.handyman),
              title: const Text('Equipamiento'),
              subtitle: Text(exercise.equipment),
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${exercise.name} agregado al plan.')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar al plan de gimnasio'),
          ),
        ],
      ),
    );
  }
}


