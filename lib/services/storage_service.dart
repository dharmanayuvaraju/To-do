import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../models/telugu_quote.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class StorageService extends ChangeNotifier {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  List<Medicine> _medicines = [];
  List<MedicineLog> _logs = [];
  List<TeluguQuote> _customQuotes = [];

  String _herName = AppConstants.defaultHerName;
  String _myName = AppConstants.defaultMyName;
  String _babuPhone = '';
  String _loveNote = AppConstants.defaultLoveNote;
  int _snoozeDurationMinutes = 10;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isDarkMode = false;
  String _photoStyle = 'couple'; // 'nature' or 'couple' (Sweet Photos)
  bool _lockScreenPrivacy = false; // Always use discreet nature on lock screen / off screen

  // Getters
  bool get isInitialized => _isInitialized;
  List<Medicine> get medicines => List.unmodifiable(_medicines);
  List<MedicineLog> get logs => List.unmodifiable(_logs);
  List<TeluguQuote> get customQuotes => List.unmodifiable(_customQuotes);
  String get herName => _herName;
  String get myName => _myName;
  String get babuPhone => _babuPhone;
  String get loveNote => _loveNote;
  int get snoozeDurationMinutes => _snoozeDurationMinutes;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isDarkMode => _isDarkMode;
  String get photoStyle => _photoStyle;
  bool get lockScreenPrivacy => _lockScreenPrivacy;

  /// Initialize and load saved state from SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();

    _herName = _prefs.getString(AppConstants.keyHerName) ?? AppConstants.defaultHerName;
    _myName = _prefs.getString(AppConstants.keyMyName) ?? AppConstants.defaultMyName;
    _babuPhone = _prefs.getString(AppConstants.keyBabuPhone) ?? '';
    _loveNote = _prefs.getString(AppConstants.keyLoveNote) ?? AppConstants.defaultLoveNote;
    _snoozeDurationMinutes = _prefs.getInt(AppConstants.keySnoozeDuration) ?? 10;
    _isSoundEnabled = _prefs.getBool(AppConstants.keySoundEnabled) ?? true;
    _isVibrationEnabled = _prefs.getBool(AppConstants.keyVibrationEnabled) ?? true;
    _isDarkMode = _prefs.getBool(AppConstants.keyDarkMode) ?? false;
    _photoStyle = _prefs.getString(AppConstants.keyPhotoStyle) ?? 'couple';
    _lockScreenPrivacy = _prefs.getBool(AppConstants.keyLockScreenPrivacy) ?? false;

    // Load Medicines
    final medJson = _prefs.getString(AppConstants.keyMedicines);
    if (medJson != null && medJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(medJson);
        _medicines = decoded.map((item) => Medicine.fromJson(item)).toList();
        
        // Auto-fix spelling mistake 'tebelt' -> 'tablet'
        bool needsSave = false;
        for (int i = 0; i < _medicines.length; i++) {
          if (_medicines[i].name == 'tebelt vesuko mundu') {
            _medicines[i] = _medicines[i].copyWith(name: 'tablet vesuko mundu');
            needsSave = true;
          }
        }
        if (needsSave) {
          _saveMedicines();
        }
      } catch (e) {
        debugPrint('Error loading medicines: $e');
      }
    } else {
      // Pre-seed ONLY ONE default medicine as requested: Everyday at 9:20 AM
      _seedDefaultMedicines();
    }

    // Load Logs
    final logsJson = _prefs.getString(AppConstants.keyLogs);
    if (logsJson != null && logsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(logsJson);
        _logs = decoded.map((item) => MedicineLog.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error loading logs: $e');
      }
    }

    // Load Custom Quotes
    final quotesJson = _prefs.getString(AppConstants.keyQuotes);
    if (quotesJson != null && quotesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(quotesJson);
        _customQuotes = decoded.map((item) => TeluguQuote.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error loading custom quotes: $e');
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  void _seedDefaultMedicines() {
    _medicines = [
      Medicine(
        id: 'default_tablet_vesuko_mundu',
        name: 'tablet vesuko mundu',
        dose: '1',
        doseUnit: 'Tablet',
        times: [const TimeOfDay(hour: 9, minute: 20)],
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        note: 'Take every morning at 9:20 AM without fail ❤️',
        colorValue: 0xFFF8C8DC,
        iconIndex: 0,
      ),
    ];
    _saveMedicines();
  }

  // --- Medicine Operations ---

  Future<void> saveMedicine(Medicine medicine) async {
    final index = _medicines.indexWhere((m) => m.id == medicine.id);
    if (index >= 0) {
      _medicines[index] = medicine;
    } else {
      _medicines.add(medicine);
    }
    await _saveMedicines();
    notifyListeners();
  }

  Future<void> deleteMedicine(String id) async {
    _medicines.removeWhere((m) => m.id == id);
    await _saveMedicines();
    notifyListeners();
  }

  Future<void> toggleMedicineActive(String id) async {
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index >= 0) {
      final current = _medicines[index];
      _medicines[index] = current.copyWith(isActive: !current.isActive);
      await _saveMedicines();
      notifyListeners();
    }
  }

  Future<void> _saveMedicines() async {
    final encoded = jsonEncode(_medicines.map((m) => m.toJson()).toList());
    await _prefs.setString(AppConstants.keyMedicines, encoded);
  }

  // --- Log Operations ---

  /// Mark a medicine as Taken for a specific scheduled time
  Future<void> markAsTaken({
    required String medicineId,
    required String medicineName,
    required DateTime scheduledTime,
  }) async {
    final now = DateTime.now();
    // Check if a log already exists for this scheduled time
    final existingIndex = _logs.indexWhere(
      (l) => l.medicineId == medicineId &&
          l.scheduledTime.year == scheduledTime.year &&
          l.scheduledTime.month == scheduledTime.month &&
          l.scheduledTime.day == scheduledTime.day &&
          l.scheduledTime.hour == scheduledTime.hour &&
          l.scheduledTime.minute == scheduledTime.minute,
    );

    if (existingIndex >= 0) {
      _logs[existingIndex] = _logs[existingIndex].copyWith(
        status: 'taken',
        actionTime: now,
      );
    } else {
      _logs.add(MedicineLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
        actionTime: now,
        status: 'taken',
      ));
    }

    await _saveLogs();
    notifyListeners();
  }

  /// Mark as Snoozed
  Future<void> markAsSnoozed({
    required String medicineId,
    required String medicineName,
    required DateTime scheduledTime,
  }) async {
    final existingIndex = _logs.indexWhere(
      (l) => l.medicineId == medicineId &&
          l.scheduledTime.year == scheduledTime.year &&
          l.scheduledTime.month == scheduledTime.month &&
          l.scheduledTime.day == scheduledTime.day &&
          l.scheduledTime.hour == scheduledTime.hour &&
          l.scheduledTime.minute == scheduledTime.minute,
    );

    if (existingIndex >= 0) {
      final current = _logs[existingIndex];
      _logs[existingIndex] = current.copyWith(
        status: 'snoozed',
        snoozeCount: current.snoozeCount + 1,
      );
    } else {
      _logs.add(MedicineLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
        status: 'snoozed',
        snoozeCount: 1,
      ));
    }

    await _saveLogs();
    notifyListeners();
  }

  /// Mark as Missed after 6 repeats (60 mins)
  Future<void> markAsMissed({
    required String medicineId,
    required String medicineName,
    required DateTime scheduledTime,
  }) async {
    final existingIndex = _logs.indexWhere(
      (l) => l.medicineId == medicineId &&
          l.scheduledTime.year == scheduledTime.year &&
          l.scheduledTime.month == scheduledTime.month &&
          l.scheduledTime.day == scheduledTime.day &&
          l.scheduledTime.hour == scheduledTime.hour &&
          l.scheduledTime.minute == scheduledTime.minute,
    );

    if (existingIndex >= 0) {
      _logs[existingIndex] = _logs[existingIndex].copyWith(
        status: 'missed',
        actionTime: DateTime.now(),
      );
    } else {
      _logs.add(MedicineLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
        actionTime: DateTime.now(),
        status: 'missed',
      ));
    }

    await _saveLogs();
    notifyListeners();
  }

  Future<void> _saveLogs() async {
    final encoded = jsonEncode(_logs.map((l) => l.toJson()).toList());
    await _prefs.setString(AppConstants.keyLogs, encoded);
  }

  // --- Streak Calculation ---

  /// Calculates consecutive days where all scheduled medicines were taken
  int calculateStreak() {
    int streak = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    // If today has pending doses, don't break streak yet; check from yesterday or today if already finished
    bool todayFullyTaken = _areAllDosesTakenForDate(checkDate);
    if (todayFullyTaken) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      // Check from yesterday
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      // If there were no scheduled medicines on this day, skip or continue
      final scheduledMeds = _medicines.where((m) => m.isScheduledForDate(checkDate)).toList();
      if (scheduledMeds.isEmpty) {
        // If no meds were scheduled, don't penalize
        checkDate = checkDate.subtract(const Duration(days: 1));
        if (now.difference(checkDate).inDays > 60) break;
        continue;
      }

      if (_areAllDosesTakenForDate(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  bool _areAllDosesTakenForDate(DateTime date) {
    final scheduled = _medicines.where((m) => m.isScheduledForDate(date)).toList();
    if (scheduled.isEmpty) return true;

    for (final med in scheduled) {
      for (final time in med.times) {
        final taken = _logs.any((l) =>
            l.medicineId == med.id &&
            l.status == 'taken' &&
            l.scheduledTime.year == date.year &&
            l.scheduledTime.month == date.month &&
            l.scheduledTime.day == date.day &&
            l.scheduledTime.hour == time.hour &&
            l.scheduledTime.minute == time.minute);
        if (!taken) return false;
      }
    }
    return true;
  }

  // --- Settings & Profiles ---

  Future<void> updateNames({required String herName, required String myName}) async {
    _herName = herName.trim().isEmpty ? AppConstants.defaultHerName : herName.trim();
    _myName = myName.trim().isEmpty ? AppConstants.defaultMyName : myName.trim();
    await _prefs.setString(AppConstants.keyHerName, _herName);
    await _prefs.setString(AppConstants.keyMyName, _myName);
    notifyListeners();
  }

  Future<void> updateBabuPhone(String phone) async {
    _babuPhone = phone.trim();
    await _prefs.setString(AppConstants.keyBabuPhone, _babuPhone);
    notifyListeners();
  }

  Future<void> updateLoveNote(String note) async {
    _loveNote = note;
    await _prefs.setString(AppConstants.keyLoveNote, note);
    notifyListeners();
  }

  Future<void> updateSnoozeDuration(int minutes) async {
    _snoozeDurationMinutes = minutes;
    await _prefs.setInt(AppConstants.keySnoozeDuration, minutes);
    notifyListeners();
  }

  Future<void> toggleSound(bool enabled) async {
    _isSoundEnabled = enabled;
    await _prefs.setBool(AppConstants.keySoundEnabled, enabled);
    notifyListeners();
  }

  Future<void> toggleVibration(bool enabled) async {
    _isVibrationEnabled = enabled;
    await _prefs.setBool(AppConstants.keyVibrationEnabled, enabled);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    await _prefs.setBool(AppConstants.keyDarkMode, enabled);
    notifyListeners();
  }

  Future<void> setPhotoStyle(String style) async {
    _photoStyle = style;
    await _prefs.setString(AppConstants.keyPhotoStyle, style);
    notifyListeners();
  }

  Future<void> setLockScreenPrivacy(bool enabled) async {
    _lockScreenPrivacy = enabled;
    await _prefs.setBool(AppConstants.keyLockScreenPrivacy, enabled);
    notifyListeners();
  }

  // --- Custom Quotes ---

  Future<void> addCustomQuote(String telugu, String english) async {
    final quote = TeluguQuote(
      id: DateTime.now().millisecondsSinceEpoch,
      telugu: telugu,
      english: english,
      isCustom: true,
    );
    _customQuotes.add(quote);
    final encoded = jsonEncode(_customQuotes.map((q) => q.toJson()).toList());
    await _prefs.setString(AppConstants.keyQuotes, encoded);
    notifyListeners();
  }

  Future<void> deleteCustomQuote(int id) async {
    _customQuotes.removeWhere((q) => q.id == id);
    final encoded = jsonEncode(_customQuotes.map((q) => q.toJson()).toList());
    await _prefs.setString(AppConstants.keyQuotes, encoded);
    notifyListeners();
  }

  // --- Export / Import Backup ---

  String exportBackupJson() {
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'herName': _herName,
      'myName': _myName,
      'medicines': _medicines.map((m) => m.toJson()).toList(),
      'logs': _logs.map((l) => l.toJson()).toList(),
      'customQuotes': _customQuotes.map((q) => q.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> clearAllHistory() async {
    _logs.clear();
    await _prefs.remove(AppConstants.keyLogs);
    notifyListeners();
  }
}
