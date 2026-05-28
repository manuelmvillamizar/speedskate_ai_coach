import 'daily_training_block.dart';
import 'training_progression_engine.dart';

class TrainingProgressionBlockBuilder {
  static List<DailyTrainingBlock> buildExtraBlocks({
    required TrainingProgressionDecision decision,
  }) {
    final blocks = <DailyTrainingBlock>[];

    if (decision.targets.contains(TrainingProgressionTarget.cyclingVolume)) {
      blocks.add(
        const DailyTrainingBlock(
          type: TrainingBlockType.cycling,
          moment: TrainingBlockMoment.evening,
          title: 'Bicicleta aer�bica complementaria',
          description:
              'Rodaje Z2 de bajo impacto para aumentar volumen sin castigar tend�n.',
          durationMinutes: 40,
          km: 0,
          targetLoad: 35,
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'La fisiolog�a permite a�adir volumen aer�bico con bajo costo mec�nico.',
          stimulus: TrainingStimulus.aerobic,
          energySystem: TrainingEnergySystem.aerobic,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
      );
    }

    if (decision.targets.contains(TrainingProgressionTarget.gymStrength)) {
      blocks.add(
        const DailyTrainingBlock(
          type: TrainingBlockType.strength,
          moment: TrainingBlockMoment.afternoon,
          title: 'Gimnasio complementario de fuerza',
          description:
              'Fuerza t�cnica controlada para mejorar transferencia sin buscar fallo.',
          durationMinutes: 40,
          km: 0,
          targetLoad: 55,
          targetHeartRateZone: 1,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'El atleta tolera carga de fuerza y puede a�adir est�mulo subm�ximo.',
          stimulus: TrainingStimulus.maxStrength,
          energySystem: TrainingEnergySystem.none,
          neuromuscularLoad: NeuromuscularLoad.moderate,
        ),
      );
    }

    if (decision.targets.contains(TrainingProgressionTarget.gymPower)) {
      blocks.add(
        const DailyTrainingBlock(
          type: TrainingBlockType.strength,
          moment: TrainingBlockMoment.afternoon,
          title: 'Potencia y transferencia fuerza-velocidad',
          description:
              'Trabajo explosivo corto para convertir fuerza en velocidad espec�fica.',
          durationMinutes: 35,
          km: 0,
          targetLoad: 60,
          targetHeartRateZone: 1,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'La tolerancia neural permite a�adir potencia sin comprometer recuperaci�n.',
          stimulus: TrainingStimulus.power,
          energySystem: TrainingEnergySystem.anaerobicAlactic,
          neuromuscularLoad: NeuromuscularLoad.high,
        ),
      );
    }

    if (decision.targets.contains(TrainingProgressionTarget.plyometrics)) {
      blocks.add(
        const DailyTrainingBlock(
          type: TrainingBlockType.activation,
          moment: TrainingBlockMoment.evening,
          title: 'Pliometr�a reactiva controlada',
          description:
              'Pocos contactos de alta calidad para mejorar rigidez, reactividad y transferencia.',
          durationMinutes: 18,
          km: 0,
          targetLoad: 25,
          targetHeartRateZone: 1,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'La tolerancia reactiva y tendinosa permite a�adir est�mulo pliom�trico bajo control.',
          stimulus: TrainingStimulus.plyometric,
          energySystem: TrainingEnergySystem.anaerobicAlactic,
          neuromuscularLoad: NeuromuscularLoad.moderate,
        ),
      );
    }

    return blocks;
  }
}


