import 'package:cropmate/models/crop_watering_plan.dart';
import 'package:flutter/material.dart';

class GrowthStageWidget extends StatelessWidget {
  final String cropType;
  final DateTime plantingDate;
  final int currentStageIndex;

  const GrowthStageWidget({
    Key? key,
    required this.cropType,
    required this.plantingDate,
    required this.currentStageIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cropPlan = CropWateringPlan.getPlanByCropName(cropType);

    if (cropPlan == null) {
      return const SizedBox.shrink();
    }

    if (currentStageIndex >= cropPlan.growthStages.length) {
      return const Text('Plant fully grown');
    }

    final currentStage = cropPlan.growthStages[currentStageIndex];
    final daysSincePlanting = DateTime.now().difference(plantingDate).inDays;

    // Calculate progress in current stage
    final previousStagesDuration = currentStageIndex > 0
        ? cropPlan.growthStages
            .sublist(0, currentStageIndex)
            .fold<int>(0, (sum, stage) => sum + stage.durationDays)
        : 0;
    final daysInCurrentStage = daysSincePlanting - previousStagesDuration;
    final stageProgress = daysInCurrentStage / currentStage.durationDays;
    final clampedProgress = stageProgress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.trending_up,
              size: 16,
              color: Colors.green[700],
            ),
            const SizedBox(width: 4),
            Text(
              'Stage: ${currentStage.name}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: clampedProgress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        const SizedBox(height: 4),
        Text(
          'Water every ${currentStage.wateringFrequencyDays} days: ${currentStage.waterAmount}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
