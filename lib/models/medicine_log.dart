class MedicineLog {
  final String id;
  final String medicineId;
  final String medicineName;
  final DateTime scheduledTime;
  final DateTime? actionTime;
  final String status; // 'taken', 'missed', 'snoozed', 'pending'
  final int snoozeCount; // 0 to 6

  MedicineLog({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.scheduledTime,
    this.actionTime,
    required this.status,
    this.snoozeCount = 0,
  });

  MedicineLog copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    DateTime? scheduledTime,
    DateTime? actionTime,
    String? status,
    int? snoozeCount,
  }) {
    return MedicineLog(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actionTime: actionTime ?? this.actionTime,
      status: status ?? this.status,
      snoozeCount: snoozeCount ?? this.snoozeCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'actionTime': actionTime?.toIso8601String(),
      'status': status,
      'snoozeCount': snoozeCount,
    };
  }

  factory MedicineLog.fromJson(Map<String, dynamic> map) {
    return MedicineLog(
      id: map['id'] as String,
      medicineId: map['medicineId'] as String,
      medicineName: (map['medicineName'] ?? '') as String,
      scheduledTime: DateTime.parse(map['scheduledTime'] as String),
      actionTime: map['actionTime'] != null
          ? DateTime.tryParse(map['actionTime'] as String)
          : null,
      status: (map['status'] ?? 'pending') as String,
      snoozeCount: (map['snoozeCount'] ?? 0) as int,
    );
  }

  bool get isTaken => status == 'taken';
  bool get isMissed => status == 'missed';
  bool get isSnoozed => status == 'snoozed';
}
