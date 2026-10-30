import 'package:flutter_test/flutter_test.dart';
import 'package:maa_madhuram/models/medicine.dart';
import 'package:flutter/material.dart';

void main() {
  test('Medicine model JSON serialization test', () {
    final med = Medicine(
      id: 'test_1',
      name: 'Folic Acid',
      dose: '1',
      doseUnit: 'Tablet',
      times: [const TimeOfDay(hour: 8, minute: 30)],
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      note: 'After breakfast',
    );

    final json = med.toJson();
    final parsed = Medicine.fromJson(json);

    expect(parsed.id, 'test_1');
    expect(parsed.name, 'Folic Acid');
    expect(parsed.times.first.hour, 8);
    expect(parsed.times.first.minute, 30);
    expect(parsed.isScheduledForDate(DateTime.now()), true);
  });
}

