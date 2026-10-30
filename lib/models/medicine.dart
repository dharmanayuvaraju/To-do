import 'package:flutter/material.dart';

class Medicine {
  final String id;
  final String name;
  final String dose;
  final String doseUnit; // 'Tablet', 'Capsule', 'Spoon (ml)', 'Drops', 'Injection'
  final List<TimeOfDay> times;
  final List<int> daysOfWeek; // 1 = Mon ... 7 = Sun. Empty or [1..7] means daily.
  final String note;
  final int colorValue;
  final int iconIndex;
  final bool isActive;
  final DateTime createdAt;

  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    this.doseUnit = 'Tablet',
    required this.times,
    required this.daysOfWeek,
    this.note = '',
    this.colorValue = 0xFFF8C8DC,
    this.iconIndex = 0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Medicine copyWith({
    String? id,
    String? name,
    String? dose,
    String? doseUnit,
    List<TimeOfDay>? times,
    List<int>? daysOfWeek,
    String? note,
    int? colorValue,
    int? iconIndex,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      doseUnit: doseUnit ?? this.doseUnit,
      times: times ?? this.times,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      note: note ?? this.note,
      colorValue: colorValue ?? this.colorValue,
      iconIndex: iconIndex ?? this.iconIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'doseUnit': doseUnit,
      'times': times.map((t) => {'hour': t.hour, 'minute': t.minute}).toList(),
      'daysOfWeek': daysOfWeek,
      'note': note,
      'colorValue': colorValue,
      'iconIndex': iconIndex,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> map) {
    final timesRaw = (map['times'] as List<dynamic>?) ?? [];
    final parsedTimes = timesRaw.map((item) {
      final m = item as Map<String, dynamic>;
      return TimeOfDay(hour: m['hour'] as int, minute: m['minute'] as int);
    }).toList();

    return Medicine(
      id: map['id'] as String,
      name: map['name'] as String,
      dose: (map['dose'] ?? '1').toString(),
      doseUnit: (map['doseUnit'] ?? 'Tablet') as String,
      times: parsedTimes.isNotEmpty ? parsedTimes : [const TimeOfDay(hour: 9, minute: 0)],
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? [1, 2, 3, 4, 5, 6, 7]),
      note: (map['note'] ?? '') as String,
      colorValue: (map['colorValue'] ?? 0xFFF8C8DC) as int,
      iconIndex: (map['iconIndex'] ?? 0) as int,
      isActive: (map['isActive'] ?? true) as bool,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Check if this medicine is scheduled on a given DateTime
  bool isScheduledForDate(DateTime dt) {
    if (!isActive) return false;
    if (daysOfWeek.isEmpty) return true;
    return daysOfWeek.contains(dt.weekday);
  }
}
