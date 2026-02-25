/*
 * ============================================================
 *  IoT POULTRY INCUBATOR MONITORING & CONTROL SYSTEM
 *  ESP32 + Firebase Realtime Database
 * ============================================================
 *  Components:
 *    - ESP32 DevKit
 *    - DHT22 (4-pin)          -> GPIO 4
 *    - I2C LCD 16x2           -> SDA=21, SCL=22
 *    - ULN2003 + Stepper      -> GPIO 14, 27, 26, 25
 *    - Relay 1 (Bulb/Heater)  -> GPIO 18
 *    - Relay 2 (Fan/Cooling)  -> GPIO 19
 *    - Relay 3 (Atomizer/Hum) -> GPIO 23
 *    - Firebase RTDB for remote monitoring
 * ============================================================
 *  Libraries needed (install via Arduino Library Manager):
 *    1. Firebase ESP Client        (by mobizt)
 *    2. DHT sensor library         (by Adafruit)
 *    3. Adafruit Unified Sensor
 *    4. LiquidCrystal_I2C          (by Frank de Brabander)
 *    5. Stepper                    (built-in)
 * ============================================================
 */

// ==================== INCLUDES ====================
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <Stepper.h>

// Firebase helper includes
#include <addons/TokenHelper.h>   // Token generation helpers
#include <addons/RTDBHelper.h>    // RTDB payload printing helpers

// ==================== WiFi CREDENTIALS ====================
#define WIFI_SSID       "YOUR_WIFI_SSID"        // <-- Change this
#define WIFI_PASSWORD   "YOUR_WIFI_PASSWORD"     // <-- Change this

// ==================== FIREBASE CREDENTIALS ====================
// Get these from Firebase Console -> Project Settings
#define API_KEY         "YOUR_FIREBASE_API_KEY"           // <-- Change this
#define DATABASE_URL    "https://YOUR-PROJECT.firebaseio.com"  // <-- Change this

// (Optional) Firebase Auth – use anonymous or email auth
#define USER_EMAIL      "YOUR_EMAIL@example.com"  // <-- Change or remove
#define USER_PASSWORD   "YOUR_PASSWORD"           // <-- Change or remove

// ==================== PIN DEFINITIONS ====================
// DHT22 Sensor
#define DHTPIN          4
#define DHTTYPE         DHT22

// I2C LCD (address 0x27 is most common, try 0x3F if not working)
#define LCD_ADDR        0x27
#define LCD_COLS        16
#define LCD_ROWS        2

// Stepper Motor via ULN2003
#define STEPPER_IN1     14
#define STEPPER_IN2     27
#define STEPPER_IN3     26
#define STEPPER_IN4     25
#define STEPS_PER_REV   2048   // 28BYJ-48 stepper = 2048 steps/rev

// Relay Pins (Active LOW for most relay modules)
#define RELAY_BULB      18     // Relay 1 - Heating bulb
#define RELAY_FAN       19     // Relay 2 - Cooling fan
#define RELAY_ATOMIZER  23     // Relay 3 - Humidity atomizer

// ==================== INCUBATION PARAMETERS ====================
// Chicken egg incubation: ~37.5°C, 55-65% humidity
// Days 1-18: 37.5°C, 55% humidity, turn eggs every 4 hours
// Days 19-21: 37.2°C, 65% humidity, STOP turning

float TARGET_TEMP       = 37.5;   // Target temperature (°C)
float TEMP_TOLERANCE    = 0.5;    // +/- tolerance band
float TARGET_HUMIDITY   = 55.0;   // Target humidity (%)
float HUMIDITY_TOLERANCE = 5.0;   // +/- tolerance band

// ==================== TIMING CONSTANTS ====================
#define SENSOR_READ_INTERVAL    2000      // Read sensor every 2 seconds
#define LCD_UPDATE_INTERVAL     1000      // Update LCD every 1 second
#define FIREBASE_SEND_INTERVAL  5000      // Send to Firebase every 5 seconds
#define FIREBASE_GET_INTERVAL   10000     // Get settings from Firebase every 10s
#define EGG_TURN_INTERVAL       14400000  // Turn eggs every 4 hours (ms)
// #define EGG_TURN_INTERVAL    60000     // Use 1 min for testing

// ==================== OBJECT INITIALIZATION ====================
DHT dht(DHTPIN, DHTTYPE);
LiquidCrystal_I2C lcd(LCD_ADDR, LCD_COLS, LCD_ROWS);
Stepper stepper(STEPS_PER_REV, STEPPER_IN1, STEPPER_IN3, STEPPER_IN2, STEPPER_IN4);

// Firebase objects
FirebaseData fbdo;           // Firebase data object
FirebaseAuth auth;           // Firebase authentication
FirebaseConfig config;       // Firebase configuration

// ==================== STATE VARIABLES ====================
float currentTemp       = 0.0;
float currentHumidity   = 0.0;
bool  bulbON            = false;
bool  fanON             = false;
bool  atomizerON        = false;
bool  firebaseReady     = false;
bool  eggTurningEnabled = true;   // Disable on days 19-21
int   incubationDay     = 1;      // Track incubation day
int   eggTurnCount      = 0;      // Count of egg turns

// Timing trackers
unsigned long lastSensorRead   = 0;
unsigned long lastLCDUpdate    = 0;
unsigned long lastFirebaseSend = 0;
unsigned long lastFirebaseGet  = 0;
unsigned long lastEggTurn      = 0;
unsigned long systemStartTime  = 0;

// LCD custom characters for degree symbol
byte degreeSymbol[8] = {
  0b00110,
  0b01001,
  0b01001,
  0b00110,
  0b00000,
  0b00000,
  0b00000,
  0b00000
};

// ==================== FUNCTION PROTOTYPES ====================
void connectWiFi();
void initFirebase();
void readSensors();
void controlIncubator();
void updateLCD();
void sendToFirebase();
void getSettingsFromFirebase();
void turnEggs();
void disableStepperPins();
String getUptimeString();

// ============================================================
//                          SETUP
// ============================================================
void setup() {
  Serial.begin(115200);
  Serial.println();
  Serial.println("===================================");
  Serial.println(" IoT Poultry Incubator Starting... ");
  Serial.println("===================================");

  // ---------- Initialize Relay Pins ----------
  pinMode(RELAY_BULB, OUTPUT);
  pinMode(RELAY_FAN, OUTPUT);
  pinMode(RELAY_ATOMIZER, OUTPUT);

  // Start with all relays OFF (HIGH = OFF for active-low relays)
  digitalWrite(RELAY_BULB, HIGH);
  digitalWrite(RELAY_FAN, HIGH);
  digitalWrite(RELAY_ATOMIZER, HIGH);

  // ---------- Initialize DHT22 ----------
  dht.begin();
  Serial.println("[OK] DHT22 initialized");

  // ---------- Initialize LCD ----------
  lcd.init();
  lcd.backlight();
  lcd.createChar(0, degreeSymbol);
  lcd.setCursor(0, 0);
  lcd.print("  IoT Incubator ");
  lcd.setCursor(0, 1);
  lcd.print("  Starting...   ");
  Serial.println("[OK] LCD initialized");

  // ---------- Initialize Stepper ----------
  stepper.setSpeed(10);  // 10 RPM for gentle egg turning
  Serial.println("[OK] Stepper motor initialized");

  // ---------- Connect to WiFi ----------
  connectWiFi();

  // ---------- Initialize Firebase ----------
  initFirebase();

  // ---------- Record start time ----------
  systemStartTime = millis();
  lastEggTurn = millis();  // Start egg turn timer

  // ---------- Startup complete ----------
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("System Ready!");
  lcd.setCursor(0, 1);
  lcd.print("Monitoring...");
  delay(2000);
  lcd.clear();

  Serial.println("===================================");
  Serial.println(" System Ready - Monitoring Active  ");
  Serial.println("===================================");
}

// ============================================================
//                        MAIN LOOP
// ============================================================
void loop() {
  unsigned long currentMillis = millis();

  // ----- 1. Read sensors periodically -----
  if (currentMillis - lastSensorRead >= SENSOR_READ_INTERVAL) {
    lastSensorRead = currentMillis;
    readSensors();
  }

  // ----- 2. Control incubator devices -----
  controlIncubator();

  // ----- 3. Update LCD display -----
  if (currentMillis - lastLCDUpdate >= LCD_UPDATE_INTERVAL) {
    lastLCDUpdate = currentMillis;
    updateLCD();
  }

  // ----- 4. Send data to Firebase -----
  if (Firebase.ready() && (currentMillis - lastFirebaseSend >= FIREBASE_SEND_INTERVAL)) {
    lastFirebaseSend = currentMillis;
    sendToFirebase();
  }

  // ----- 5. Get remote settings from Firebase -----
  if (Firebase.ready() && (currentMillis - lastFirebaseGet >= FIREBASE_GET_INTERVAL)) {
    lastFirebaseGet = currentMillis;
    getSettingsFromFirebase();
  }

  // ----- 6. Turn eggs periodically -----
  if (eggTurningEnabled && (currentMillis - lastEggTurn >= EGG_TURN_INTERVAL)) {
    lastEggTurn = currentMillis;
    turnEggs();
  }
}

// ============================================================
//                     WiFi CONNECTION
// ============================================================
void connectWiFi() {
  Serial.print("[WiFi] Connecting to ");
  Serial.println(WIFI_SSID);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting WiFi");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 40) {
    delay(500);
    Serial.print(".");
    // Animate dots on LCD
    lcd.setCursor(attempts % 16, 1);
    lcd.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.print("[WiFi] Connected! IP: ");
    Serial.println(WiFi.localIP());

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi Connected!");
    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP());
    delay(2000);
  } else {
    Serial.println();
    Serial.println("[WiFi] FAILED - Running offline mode");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi FAILED!");
    lcd.setCursor(0, 1);
    lcd.print("Offline Mode");
    delay(2000);
  }
}

// ============================================================
//                   FIREBASE INITIALIZATION
// ============================================================
void initFirebase() {
  Serial.println("[Firebase] Initializing...");

  // Set Firebase configuration
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Set Firebase authentication (email/password)
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  // Set token status callback (for debugging)
  config.token_status_callback = tokenStatusCallback;  // from TokenHelper.h

  // Set maximum retry on network errors
  config.max_token_generation_retry = 5;

  // Initialize Firebase
  Firebase.begin(&config, &auth);

  // Enable auto-reconnect
  Firebase.reconnectNetwork(true);

  // Wait for Firebase to be ready (with timeout)
  Serial.print("[Firebase] Signing in");
  unsigned long fbStart = millis();
  while (!Firebase.ready() && (millis() - fbStart < 15000)) {
    Serial.print(".");
    delay(500);
  }

  if (Firebase.ready()) {
    firebaseReady = true;
    Serial.println();
    Serial.println("[Firebase] Connected and ready!");

    // Set initial structure in Firebase
    Firebase.RTDB.setString(&fbdo, "/incubator/status", "online");
    Firebase.RTDB.setFloat(&fbdo, "/incubator/settings/targetTemp", TARGET_TEMP);
    Firebase.RTDB.setFloat(&fbdo, "/incubator/settings/targetHumidity", TARGET_HUMIDITY);
    Firebase.RTDB.setFloat(&fbdo, "/incubator/settings/tempTolerance", TEMP_TOLERANCE);
    Firebase.RTDB.setFloat(&fbdo, "/incubator/settings/humidityTolerance", HUMIDITY_TOLERANCE);
    Firebase.RTDB.setBool(&fbdo, "/incubator/settings/eggTurning", eggTurningEnabled);
    Firebase.RTDB.setInt(&fbdo, "/incubator/settings/incubationDay", incubationDay);
  } else {
    Serial.println();
    Serial.println("[Firebase] FAILED - Running without cloud");
  }
}

// ============================================================
//                     READ SENSORS
// ============================================================
void readSensors() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();  // Celsius

  // Validate readings
  if (isnan(h) || isnan(t)) {
    Serial.println("[SENSOR] DHT22 read FAILED! Using last known values.");
    return;  // Keep previous values
  }

  currentTemp = t;
  currentHumidity = h;

  // Serial output for debugging
  Serial.print("[SENSOR] Temp: ");
  Serial.print(currentTemp, 1);
  Serial.print("°C  |  Humidity: ");
  Serial.print(currentHumidity, 1);
  Serial.println("%");
}

// ============================================================
//               INCUBATOR CONTROL LOGIC
// ============================================================
void controlIncubator() {
  // ---- HEATING CONTROL (Bulb via Relay 1) ----
  // Turn ON bulb if temperature is below target
  if (currentTemp < (TARGET_TEMP - TEMP_TOLERANCE)) {
    if (!bulbON) {
      digitalWrite(RELAY_BULB, LOW);   // Active LOW = relay ON
      bulbON = true;
      Serial.println("[CTRL] Heater ON - Temp too low");
    }
  }
  // Turn OFF bulb if temperature reaches target
  else if (currentTemp > (TARGET_TEMP + TEMP_TOLERANCE)) {
    if (bulbON) {
      digitalWrite(RELAY_BULB, HIGH);  // Active LOW = relay OFF
      bulbON = false;
      Serial.println("[CTRL] Heater OFF - Temp reached");
    }
  }

  // ---- FAN CONTROL (Fan via Relay 2) ----
  // Turn ON fan if temperature is too high (for cooling & air circulation)
  if (currentTemp > (TARGET_TEMP + TEMP_TOLERANCE)) {
    if (!fanON) {
      digitalWrite(RELAY_FAN, LOW);
      fanON = true;
      Serial.println("[CTRL] Fan ON - Cooling needed");
    }
  }
  // Turn OFF fan when temperature drops back
  else if (currentTemp <= TARGET_TEMP) {
    if (fanON) {
      digitalWrite(RELAY_FAN, HIGH);
      fanON = false;
      Serial.println("[CTRL] Fan OFF - Temp normal");
    }
  }

  // ---- HUMIDITY CONTROL (Atomizer via Relay 3) ----
  // Turn ON atomizer if humidity is too low
  if (currentHumidity < (TARGET_HUMIDITY - HUMIDITY_TOLERANCE)) {
    if (!atomizerON) {
      digitalWrite(RELAY_ATOMIZER, LOW);
      atomizerON = true;
      Serial.println("[CTRL] Atomizer ON - Humidity low");
    }
  }
  // Turn OFF atomizer when humidity reaches target
  else if (currentHumidity > (TARGET_HUMIDITY + HUMIDITY_TOLERANCE)) {
    if (atomizerON) {
      digitalWrite(RELAY_ATOMIZER, HIGH);
      atomizerON = false;
      Serial.println("[CTRL] Atomizer OFF - Humidity OK");
    }
  }
}

// ============================================================
//                    UPDATE LCD DISPLAY
// ============================================================
void updateLCD() {
  // ---- Line 1: Temperature and Humidity ----
  lcd.setCursor(0, 0);
  lcd.print("T:");
  lcd.print(currentTemp, 1);
  lcd.write(0);  // Degree symbol
  lcd.print("C ");

  lcd.print("H:");
  lcd.print(currentHumidity, 1);
  lcd.print("%");

  // Pad remaining spaces to clear old chars
  int len = 16;  // Already filled most of 16 chars
  lcd.print(" ");

  // ---- Line 2: Device status indicators ----
  lcd.setCursor(0, 1);

  // Show which devices are active
  lcd.print(bulbON     ? "HT:" : "HT:");
  lcd.print(bulbON     ? "ON " : "OFF");

  lcd.print(fanON      ? " FN:" : " FN:");
  lcd.print(fanON      ? "ON"  : "OF");

  lcd.print(atomizerON ? " M:Y" : " M:N");
}

// ============================================================
//                 SEND DATA TO FIREBASE
// ============================================================
void sendToFirebase() {
  if (!Firebase.ready()) {
    Serial.println("[Firebase] Not ready, skipping send");
    return;
  }

  Serial.println("[Firebase] Sending data...");

  // Create a JSON object for efficient batch write
  FirebaseJson json;

  // Sensor readings
  json.set("temperature", currentTemp);
  json.set("humidity", currentHumidity);

  // Device states
  json.set("heaterOn", bulbON);
  json.set("fanOn", fanON);
  json.set("atomizerOn", atomizerON);

  // System info
  json.set("eggTurnCount", eggTurnCount);
  json.set("eggTurningEnabled", eggTurningEnabled);
  json.set("incubationDay", incubationDay);
  json.set("uptime", getUptimeString());
  json.set("wifiRSSI", WiFi.RSSI());
  json.set("freeHeap", (int)ESP.getFreeHeap());
  json.set("timestamp/.sv", "timestamp");  // Firebase server timestamp

  // Send all data as one JSON update (efficient!)
  if (Firebase.RTDB.setJSON(&fbdo, "/incubator/sensorData", &json)) {
    Serial.println("[Firebase] Data sent successfully");
  } else {
    Serial.print("[Firebase] SEND FAILED: ");
    Serial.println(fbdo.errorReason());
  }

  // Also push to history log (for graphs/charts in your app)
  FirebaseJson historyJson;
  historyJson.set("temp", currentTemp);
  historyJson.set("hum", currentHumidity);
  historyJson.set("ts/.sv", "timestamp");

  if (Firebase.RTDB.pushJSON(&fbdo, "/incubator/history", &historyJson)) {
    Serial.println("[Firebase] History logged");
  } else {
    Serial.print("[Firebase] History FAILED: ");
    Serial.println(fbdo.errorReason());
  }
}

// ============================================================
//            GET REMOTE SETTINGS FROM FIREBASE
// ============================================================
void getSettingsFromFirebase() {
  if (!Firebase.ready()) return;

  Serial.println("[Firebase] Checking remote settings...");

  // --- Read target temperature ---
  if (Firebase.RTDB.getFloat(&fbdo, "/incubator/settings/targetTemp")) {
    float newTarget = fbdo.floatData();
    if (newTarget >= 30.0 && newTarget <= 42.0 && newTarget != TARGET_TEMP) {
      TARGET_TEMP = newTarget;
      Serial.print("[Firebase] Target temp updated: ");
      Serial.println(TARGET_TEMP);
    }
  }

  // --- Read target humidity ---
  if (Firebase.RTDB.getFloat(&fbdo, "/incubator/settings/targetHumidity")) {
    float newHum = fbdo.floatData();
    if (newHum >= 30.0 && newHum <= 90.0 && newHum != TARGET_HUMIDITY) {
      TARGET_HUMIDITY = newHum;
      Serial.print("[Firebase] Target humidity updated: ");
      Serial.println(TARGET_HUMIDITY);
    }
  }

  // --- Read egg turning enabled/disabled ---
  if (Firebase.RTDB.getBool(&fbdo, "/incubator/settings/eggTurning")) {
    bool newTurning = fbdo.boolData();
    if (newTurning != eggTurningEnabled) {
      eggTurningEnabled = newTurning;
      Serial.print("[Firebase] Egg turning: ");
      Serial.println(eggTurningEnabled ? "ENABLED" : "DISABLED");
    }
  }

  // --- Read incubation day ---
  if (Firebase.RTDB.getInt(&fbdo, "/incubator/settings/incubationDay")) {
    int newDay = fbdo.intData();
    if (newDay >= 1 && newDay <= 21 && newDay != incubationDay) {
      incubationDay = newDay;
      Serial.print("[Firebase] Incubation day: ");
      Serial.println(incubationDay);

      // Auto-adjust for lockdown period (days 19-21)
      if (incubationDay >= 19) {
        eggTurningEnabled = false;
        TARGET_HUMIDITY = 65.0;  // Higher humidity for hatching
        TARGET_TEMP = 37.2;     // Slightly lower temp

        // Update Firebase with lockdown settings
        Firebase.RTDB.setBool(&fbdo, "/incubator/settings/eggTurning", false);
        Firebase.RTDB.setFloat(&fbdo, "/incubator/settings/targetHumidity", 65.0);
        Firebase.RTDB.setFloat(&fbdo, "/incubator/settings/targetTemp", 37.2);

        Serial.println("[CTRL] LOCKDOWN MODE - Day 19+ settings applied");
      }
    }
  }

  // --- Check for manual relay overrides ---
  if (Firebase.RTDB.getBool(&fbdo, "/incubator/manualOverride/heater")) {
    bool override = fbdo.boolData();
    if (override != bulbON) {
      bulbON = override;
      digitalWrite(RELAY_BULB, bulbON ? LOW : HIGH);
      Serial.print("[Firebase] Manual heater: ");
      Serial.println(bulbON ? "ON" : "OFF");
    }
    // Clear the override after applying
    Firebase.RTDB.deleteNode(&fbdo, "/incubator/manualOverride/heater");
  }

  if (Firebase.RTDB.getBool(&fbdo, "/incubator/manualOverride/fan")) {
    bool override = fbdo.boolData();
    if (override != fanON) {
      fanON = override;
      digitalWrite(RELAY_FAN, fanON ? LOW : HIGH);
      Serial.print("[Firebase] Manual fan: ");
      Serial.println(fanON ? "ON" : "OFF");
    }
    Firebase.RTDB.deleteNode(&fbdo, "/incubator/manualOverride/fan");
  }

  if (Firebase.RTDB.getBool(&fbdo, "/incubator/manualOverride/atomizer")) {
    bool override = fbdo.boolData();
    if (override != atomizerON) {
      atomizerON = override;
      digitalWrite(RELAY_ATOMIZER, atomizerON ? LOW : HIGH);
      Serial.print("[Firebase] Manual atomizer: ");
      Serial.println(atomizerON ? "ON" : "OFF");
    }
    Firebase.RTDB.deleteNode(&fbdo, "/incubator/manualOverride/atomizer");
  }
}

// ============================================================
//                     TURN EGGS
// ============================================================
void turnEggs() {
  if (!eggTurningEnabled) {
    Serial.println("[EGG] Turning disabled (lockdown period)");
    return;
  }

  Serial.println("[EGG] Turning eggs...");

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Turning Eggs...");
  lcd.setCursor(0, 1);
  lcd.print("Please wait");

  // Rotate stepper 180 degrees (half revolution)
  // 2048 steps = 360°, so 1024 = 180°
  int stepsToTurn = STEPS_PER_REV / 2;

  // Alternate direction each time for natural egg movement
  if (eggTurnCount % 2 == 0) {
    stepper.step(stepsToTurn);   // Clockwise
    Serial.println("[EGG] Turned CW 180°");
  } else {
    stepper.step(-stepsToTurn);  // Counter-clockwise
    Serial.println("[EGG] Turned CCW 180°");
  }

  eggTurnCount++;

  // Disable stepper coils after turning (saves power, reduces heat)
  disableStepperPins();

  // Log to Firebase
  if (Firebase.ready()) {
    Firebase.RTDB.setInt(&fbdo, "/incubator/sensorData/eggTurnCount", eggTurnCount);

    FirebaseJson turnLog;
    turnLog.set("turnNumber", eggTurnCount);
    turnLog.set("direction", (eggTurnCount % 2 == 0) ? "CCW" : "CW");
    turnLog.set("ts/.sv", "timestamp");
    Firebase.RTDB.pushJSON(&fbdo, "/incubator/eggTurnLog", &turnLog);
  }

  Serial.print("[EGG] Total turns: ");
  Serial.println(eggTurnCount);

  lcd.clear();  // Clear so normal display resumes
}

// ============================================================
//            DISABLE STEPPER PINS (save power)
// ============================================================
void disableStepperPins() {
  digitalWrite(STEPPER_IN1, LOW);
  digitalWrite(STEPPER_IN2, LOW);
  digitalWrite(STEPPER_IN3, LOW);
  digitalWrite(STEPPER_IN4, LOW);
}

// ============================================================
//                   GET UPTIME STRING
// ============================================================
String getUptimeString() {
  unsigned long totalSeconds = (millis() - systemStartTime) / 1000;
  unsigned long days    = totalSeconds / 86400;
  unsigned long hours   = (totalSeconds % 86400) / 3600;
  unsigned long minutes = (totalSeconds % 3600) / 60;
  unsigned long seconds = totalSeconds % 60;

  String uptime = "";
  if (days > 0) {
    uptime += String(days) + "d ";
  }
  uptime += String(hours) + "h ";
  uptime += String(minutes) + "m ";
  uptime += String(seconds) + "s";

  return uptime;
}
