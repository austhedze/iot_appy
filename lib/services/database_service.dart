import 'package:firebase_database/firebase_database.dart';
import '../models/incubator_data.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Reference to the incubator root node.
  DatabaseReference get _incubatorRef => _db.ref('incubator');

  // ── SENSOR DATA (real-time stream) ──

  /// Stream live sensor data from /incubator/sensorData.
  Stream<IncubatorData> get sensorDataStream {
    return _incubatorRef.child('sensorData').onValue.map((event) {
      if (event.snapshot.value != null) {
        return IncubatorData.fromMap(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
      }
      return IncubatorData();
    });
  }

  // ── SETTINGS ──

  /// Stream live settings from /incubator/settings.
  Stream<IncubatorSettings> get settingsStream {
    return _incubatorRef.child('settings').onValue.map((event) {
      if (event.snapshot.value != null) {
        return IncubatorSettings.fromMap(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
      }
      return IncubatorSettings();
    });
  }

  /// Update a specific setting.
  Future<void> updateSetting(String key, dynamic value) async {
    await _incubatorRef.child('settings/$key').set(value);
  }

  /// Update target temperature.
  Future<void> setTargetTemp(double temp) async {
    await updateSetting('targetTemp', temp);
  }

  /// Update target humidity.
  Future<void> setTargetHumidity(double humidity) async {
    await updateSetting('targetHumidity', humidity);
  }

  /// Toggle egg turning.
  Future<void> setEggTurning(bool enabled) async {
    await updateSetting('eggTurning', enabled);
  }

  /// Update incubation day.
  Future<void> setIncubationDay(int day) async {
    await updateSetting('incubationDay', day);
  }

  // ── MANUAL OVERRIDES ──

  /// Send a manual override command for a device.
  Future<void> setManualOverride(String device, bool state) async {
    await _incubatorRef.child('manualOverride/$device').set(state);
  }

  // ── STATUS ──

  /// Stream online/offline status.
  Stream<String> get statusStream {
    return _incubatorRef.child('status').onValue.map((event) {
      return (event.snapshot.value ?? 'offline') as String;
    });
  }

  // ── HISTORY (for charts) ──

  /// Fetch the last N history entries for charting.
  Future<List<HistoryEntry>> getHistory({int limit = 50}) async {
    final snapshot = await _incubatorRef
        .child('history')
        .orderByKey()
        .limitToLast(limit)
        .get();

    if (snapshot.value == null) return [];

    final map = snapshot.value as Map<dynamic, dynamic>;
    final entries = <HistoryEntry>[];

    map.forEach((key, value) {
      if (value is Map) {
        entries.add(HistoryEntry.fromMap(value));
      }
    });

    // Sort by timestamp
    entries.sort((a, b) => (a.ts ?? 0).compareTo(b.ts ?? 0));
    return entries;
  }

  /// Stream history updates for live chart.
  Stream<List<HistoryEntry>> get historyStream {
    return _incubatorRef
        .child('history')
        .orderByKey()
        .limitToLast(30)
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return <HistoryEntry>[];

          final map = event.snapshot.value as Map<dynamic, dynamic>;
          final entries = <HistoryEntry>[];

          map.forEach((key, value) {
            if (value is Map) {
              entries.add(HistoryEntry.fromMap(value));
            }
          });

          entries.sort((a, b) => (a.ts ?? 0).compareTo(b.ts ?? 0));
          return entries;
        });
  }
}
