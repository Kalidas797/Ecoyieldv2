class WateringSchedule {
  final String plant;
  final String frequency;
  final DateTime lastWatered;
  final DateTime nextWatering;
  final String? imagePath;
  final String? cropType;
  final DateTime? plantingDate;
  final int? currentStageIndex;

  WateringSchedule({
    required this.plant,
    required this.frequency,
    required this.lastWatered,
    required this.nextWatering,
    this.imagePath,
    this.cropType,
    this.plantingDate,
    this.currentStageIndex,
  });

  factory WateringSchedule.fromJson(Map<String, dynamic> json) {
    return WateringSchedule(
      plant: json['plant'],
      frequency: json['frequency'],
      lastWatered: DateTime.parse(json['lastWatered']),
      nextWatering: DateTime.parse(json['nextWatering']),
      imagePath: json['imagePath'],
      cropType: json['cropType'],
      plantingDate: json['plantingDate'] != null
          ? DateTime.parse(json['plantingDate'])
          : null,
      currentStageIndex: json['currentStageIndex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plant': plant,
      'frequency': frequency,
      'lastWatered': lastWatered.toIso8601String(),
      'nextWatering': nextWatering.toIso8601String(),
      'imagePath': imagePath,
      'cropType': cropType,
      'plantingDate': plantingDate?.toIso8601String(),
      'currentStageIndex': currentStageIndex,
    };
  }

  WateringSchedule copyWith({
    String? plant,
    String? frequency,
    DateTime? lastWatered,
    DateTime? nextWatering,
    String? imagePath,
    String? cropType,
    DateTime? plantingDate,
    int? currentStageIndex,
  }) {
    return WateringSchedule(
      plant: plant ?? this.plant,
      frequency: frequency ?? this.frequency,
      lastWatered: lastWatered ?? this.lastWatered,
      nextWatering: nextWatering ?? this.nextWatering,
      imagePath: imagePath ?? this.imagePath,
      cropType: cropType ?? this.cropType,
      plantingDate: plantingDate ?? this.plantingDate,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
    );
  }
}
