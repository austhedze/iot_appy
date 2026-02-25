class IncubatorData {
  final double temperature;
  final double humidity;
  final bool heaterOn;
  final bool fanOn;
  final bool atomizerOn;
  final int eggTurnCount;
  final bool eggTurningEnabled;
  final int incubationDay;
  final String uptime;
  final int wifiRSSI;
  final int freeHeap;
  final int? timestamp;

  IncubatorData({
    this.temperature = 0.0,
    this.humidity = 0.0,
    this.heaterOn = false,
    this.fanOn = false,
    this.atomizerOn = false,
    this.eggTurnCount = 0,
    this.eggTurningEnabled = true,
    this.incubationDay = 1,
    this.uptime = '0h 0m',
    this.wifiRSSI = 0,
    this.freeHeap = 0,
    this.timestamp,
  });

  factory IncubatorData.fromMap(Map<dynamic, dynamic> map) {
    return IncubatorData(
      temperature: (map['temperature'] ?? 0).toDouble(),
      humidity: (map['humidity'] ?? 0).toDouble(),
      heaterOn: map['heaterOn'] ?? false,
      fanOn: map['fanOn'] ?? false,
      atomizerOn: map['atomizerOn'] ?? false,
      eggTurnCount: (map['eggTurnCount'] ?? 0).toInt(),
      eggTurningEnabled: map['eggTurningEnabled'] ?? true,
      incubationDay: (map['incubationDay'] ?? 1).toInt(),
      uptime: map['uptime'] ?? '0h 0m',
      wifiRSSI: (map['wifiRSSI'] ?? 0).toInt(),
      freeHeap: (map['freeHeap'] ?? 0).toInt(),
      timestamp: map['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'heaterOn': heaterOn,
      'fanOn': fanOn,
      'atomizerOn': atomizerOn,
      'eggTurnCount': eggTurnCount,
      'eggTurningEnabled': eggTurningEnabled,
      'incubationDay': incubationDay,
      'uptime': uptime,
      'wifiRSSI': wifiRSSI,
      'freeHeap': freeHeap,
    };
  }
}

class IncubatorSettings {
  final double targetTemp;
  final double targetHumidity;
  final double tempTolerance;
  final double humidityTolerance;
  final bool eggTurning;
  final int incubationDay;

  IncubatorSettings({
    this.targetTemp = 37.5,
    this.targetHumidity = 55.0,
    this.tempTolerance = 0.5,
    this.humidityTolerance = 5.0,
    this.eggTurning = true,
    this.incubationDay = 1,
  });

  factory IncubatorSettings.fromMap(Map<dynamic, dynamic> map) {
    return IncubatorSettings(
      targetTemp: (map['targetTemp'] ?? 37.5).toDouble(),
      targetHumidity: (map['targetHumidity'] ?? 55.0).toDouble(),
      tempTolerance: (map['tempTolerance'] ?? 0.5).toDouble(),
      humidityTolerance: (map['humidityTolerance'] ?? 5.0).toDouble(),
      eggTurning: map['eggTurning'] ?? true,
      incubationDay: (map['incubationDay'] ?? 1).toInt(),
    );
  }
}

class HistoryEntry {
  final double temp;
  final double hum;
  final int? ts;

  HistoryEntry({required this.temp, required this.hum, this.ts});

  factory HistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return HistoryEntry(
      temp: (map['temp'] ?? 0).toDouble(),
      hum: (map['hum'] ?? 0).toDouble(),
      ts: map['ts'],
    );
  }
}
