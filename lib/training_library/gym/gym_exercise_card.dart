import 'package:flutter/material.dart';

import 'gym_exercise_parser.dart';

class GymExerciseCard extends StatelessWidget {
  final GymExerciseParsed exercise;

  const GymExerciseCard({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercise.imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      exercise.imagePath!,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            exercise.explosive
                                ? 'Power'
                                : 'Strength',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (exercise.prescription != null)
                      _MetricChip(
                        icon: Icons.format_list_numbered,
                        text: exercise.prescription!,
                      ),

                    if (exercise.percentage != null)
                      _MetricChip(
                        icon: Icons.speed,
                        text: exercise.percentage!,
                      ),

                    if (exercise.rpe != null)
                      _MetricChip(
                        icon: Icons.bolt,
                        text: exercise.rpe!,
                      ),

                    if (exercise.rir != null)
                      _MetricChip(
                        icon: Icons.fitness_center,
                        text: exercise.rir!,
                      ),

                    if (exercise.rest != null)
                      _MetricChip(
                        icon: Icons.timer,
                        text: exercise.rest!,
                      ),
                  ],
                ),

                const SizedBox(height: 22),

                if (exercise.physiologicalGoal != null)
                  _Section(
                    title: 'Objetivo fisiológico',
                    child: Text(
                      exercise.physiologicalGoal!,
                      style: const TextStyle(
                        height: 1.45,
                        fontSize: 15,
                      ),
                    ),
                  ),

                if (exercise.contrastExercise != null)
                  _ContrastFlow(
                    mainExercise: exercise.name,
                    contrastExercise:
                        exercise.contrastExercise!,
                  ),

                if (exercise.explosive)
                  const _Highlight(
                    icon: Icons.bolt,
                    text:
                        'Priorizar máxima velocidad de ejecución y producción neural.',
                  ),

                if (exercise.unilateral)
                  const _Highlight(
                    icon: Icons.balance,
                    text:
                        'Trabajo unilateral orientado a estabilidad específica de patinaje.',
                  ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: exercise.hasVideo
                      ? ElevatedButton.icon(
                          onPressed: () {
                            // FUTURE VIDEO PLAYER
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Ver video'),
                        )
                      : OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text(
                            'Video próximamente',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContrastFlow extends StatelessWidget {
  final String mainExercise;
  final String contrastExercise;

  const _ContrastFlow({
    required this.mainExercise,
    required this.contrastExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _FlowNode(
            icon: Icons.fitness_center,
            text: mainExercise,
          ),

          const _FlowArrow(),

          _FlowNode(
            icon: Icons.bolt,
            text: contrastExercise,
          ),

          const _FlowArrow(),

          const _FlowNode(
            icon: Icons.speed,
            text: 'Transferencia a velocidad',
          ),
        ],
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FlowNode({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Icon(
        Icons.arrow_downward,
        color: Colors.orange,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetricChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: Colors.black.withOpacity(0.04),
      avatar: Icon(icon, size: 17),
      label: Text(text),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Highlight({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

