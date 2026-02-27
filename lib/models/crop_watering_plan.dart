
class CropWateringPlan {
  final String cropName;
  final List<GrowthStage> growthStages;

  CropWateringPlan({
    required this.cropName,
    required this.growthStages,
  });

  static List<CropWateringPlan> getDefaultPlans() {
    return [
      CropWateringPlan(
        cropName: 'Tomato',
        growthStages: [
          GrowthStage(
            name: 'Seedling',
            durationDays: 21,
            wateringFrequencyDays: 1,
            waterAmount: 'Light watering, keep soil moist',
            tips: 'Ensure soil is consistently moist but not waterlogged',
          ),
          GrowthStage(
            name: 'Vegetative',
            durationDays: 30,
            wateringFrequencyDays: 2,
            waterAmount: 'Moderate watering, 1-2 inches per week',
            tips: 'Water at the base to avoid wetting foliage',
          ),
          GrowthStage(
            name: 'Flowering',
            durationDays: 30,
            wateringFrequencyDays: 3,
            waterAmount: 'Regular watering, 2 inches per week',
            tips: 'Consistent watering prevents blossom end rot',
          ),
          GrowthStage(
            name: 'Fruiting',
            durationDays: 45,
            wateringFrequencyDays: 2,
            waterAmount: 'Deep watering, 2-3 inches per week',
            tips: 'Reduce watering when fruits begin to ripen',
          ),
        ],
      ),
      CropWateringPlan(
        cropName: 'Lettuce',
        growthStages: [
          GrowthStage(
            name: 'Seedling',
            durationDays: 14,
            wateringFrequencyDays: 1,
            waterAmount: 'Light, frequent watering',
            tips: 'Keep soil consistently moist for germination',
          ),
          GrowthStage(
            name: 'Leaf development',
            durationDays: 21,
            wateringFrequencyDays: 2,
            waterAmount: 'Moderate watering, 1 inch per week',
            tips: 'Water in the morning to prevent disease',
          ),
          GrowthStage(
            name: 'Harvest',
            durationDays: 15,
            wateringFrequencyDays: 2,
            waterAmount: 'Regular watering, 1-1.5 inches per week',
            tips: 'Reduce watering 2-3 days before harvest for better flavor',
          ),
        ],
      ),
      CropWateringPlan(
        cropName: 'Cucumber',
        growthStages: [
          GrowthStage(
            name: 'Seedling',
            durationDays: 14,
            wateringFrequencyDays: 1,
            waterAmount: 'Light watering, keep soil moist',
            tips: 'Consistent moisture is crucial for germination',
          ),
          GrowthStage(
            name: 'Vegetative',
            durationDays: 21,
            wateringFrequencyDays: 2,
            waterAmount: 'Moderate watering, 1-2 inches per week',
            tips: 'Avoid overhead watering to prevent leaf diseases',
          ),
          GrowthStage(
            name: 'Flowering & Fruiting',
            durationDays: 45,
            wateringFrequencyDays: 2,
            waterAmount: 'Deep watering, 2 inches per week',
            tips: 'Consistent watering prevents bitter cucumbers',
          ),
        ],
      ),
      CropWateringPlan(
        cropName: 'Rose',
        growthStages: [
          GrowthStage(
            name: 'Early growth',
            durationDays: 30,
            wateringFrequencyDays: 3,
            waterAmount: 'Moderate watering, 1 inch per week',
            tips: 'Water at the base to keep foliage dry',
          ),
          GrowthStage(
            name: 'Budding',
            durationDays: 21,
            wateringFrequencyDays: 3,
            waterAmount: 'Regular watering, 1-2 inches per week',
            tips: 'Consistent moisture helps bud development',
          ),
          GrowthStage(
            name: 'Flowering',
            durationDays: 60,
            wateringFrequencyDays: 4,
            waterAmount: 'Deep watering, 2 inches per week',
            tips: 'Water deeply but less frequently during blooming',
          ),
        ],
      ),
      CropWateringPlan(
        cropName: 'Succulent',
        growthStages: [
          GrowthStage(
            name: 'Dormant',
            durationDays: 90,
            wateringFrequencyDays: 14,
            waterAmount: 'Minimal watering, only when soil is completely dry',
            tips: 'Reduce watering in winter months',
          ),
          GrowthStage(
            name: 'Active growth',
            durationDays: 180,
            wateringFrequencyDays: 7,
            waterAmount: 'Light watering, allow soil to dry between waterings',
            tips: 'Water only when the soil is completely dry to the touch',
          ),
          GrowthStage(
            name: 'Flowering',
            durationDays: 30,
            wateringFrequencyDays: 7,
            waterAmount: 'Slightly more water during flowering',
            tips: 'Return to normal watering after flowering period',
          ),
        ],
      ),
    ];
  }

  static CropWateringPlan? getPlanByCropName(String cropName) {
    try {
      return getDefaultPlans().firstWhere(
        (plan) => plan.cropName == cropName,
      );
    } catch (e) {
      return null;
    }
  }
}

class GrowthStage {
  final String name;
  final int durationDays; // Ensure this is non-nullable
  final int wateringFrequencyDays;
  final String waterAmount;
  final String tips;

  GrowthStage({
    required this.name,
    required this.durationDays, // Ensure this is required
    required this.wateringFrequencyDays,
    required this.waterAmount,
    required this.tips,
  });
}
