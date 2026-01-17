import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final int frequencyPerDay;
  final List<TimeOfDay> schedule;
  bool isTakenToday;
  final Set<DateTime> history; // Dates où le médicament a été pris
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCritical;
  final String? aiRecommendation;
  final bool isHighlighted;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequencyPerDay,
    required this.schedule,
    this.isTakenToday = false,
    Set<DateTime>? history,
    this.startDate,
    this.endDate,
    this.isCritical = false,
    this.aiRecommendation,
    this.isHighlighted = false,
  }) : history = history ?? {};

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    int? frequencyPerDay,
    List<TimeOfDay>? schedule,
    bool? isTakenToday,
    Set<DateTime>? history,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCritical,
    String? aiRecommendation,
    bool? isHighlighted,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequencyPerDay: frequencyPerDay ?? this.frequencyPerDay,
      schedule: schedule ?? this.schedule,
      isTakenToday: isTakenToday ?? this.isTakenToday,
      history: history ?? this.history,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCritical: isCritical ?? this.isCritical,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }
}
