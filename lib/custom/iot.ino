/*
 * ============================================================
 * IoT POULTRY INCUBATOR MONITORING & CONTROL SYSTEM
 * ESP32 + Firebase Realtime Database (DHT20 I2C VERSION)
 * ============================================================
 */

// ==================== INCLUDES ====================
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <Wire.h>
#include <DHT20.h>            // Using Rob Tillaart's DHT20 Library
#include <LiquidCrystal_I2C.h>
#include <Stepper.h>

// Firebase helper includes
#include <addons/TokenHelper.h>   
#include <addons/RTDBHelper.h>    

// ==================== WiFi CREDENTIALS ====================
#define WIFI_SSID       "austin 5G"        
#define WIFI_PASSWORD   "austin000"     

// ==================== ESP32 Access Point CREDENTIALS ====================
#define AP_SSID         "ESP32_Incubator"   
#define AP_PASSWORD     "12345678"          

// ==================== FIREBASE CREDENTIALS ====================
#define API_KEY         "AIzaSyAEM2gjNcW6t7hqPXF21AbgEUlwYfQZI-I"           
#define DATABASE_URL    "https://iot-incubator-91ebb-default-rtdb.firebaseio.com"  
#define USER_EMAIL      "austhez@gmail.com"  
#define USER_PASSWORD   "password"           

// ==================== PIN DEFINITIONS ====================
// I2C Pins (Shared by LCD and DHT20)
#define I2C_SDA         21
#define I2C_SCL         22

// I2C LCD
#define LCD_ADDR        0x27
#define LCD_COLS        16
#define LCD_ROWS        2

// Stepper Motor via ULN2003
#define STEPPER_IN1     14
#define STEPPER_IN2     27
#define STEPPER_IN3     26
#define STEPPER_IN4     25
#define STEPS_PER_REV   2048   

// Relay Pins
#define RELAY_BULB      18     
#define RELAY_FAN       19     
#define RELAY_ATOMIZER  23     

// ==================== INCUBATION PARAMETERS ====================
float TARGET_TEMP       = 37.5;   
float TEMP_TOLERANCE    = 0.5;    
float TARGET_HUMIDITY   = 55.0;   
float HUMIDITY_TOLERANCE = 5.0;   

// ==================== TIMING CONSTANTS ====================
#define SENSOR_READ_INTERVAL    3000      
#define LCD_UPDATE_INTERVAL     1000      
#define FIREBASE_SEND_INTERVAL  10000     
#define FIREBASE_GET_INTERVAL   15000     
#define EGG_TURN_INTERVAL       5000      

// ==================== OBJECT INITIALIZATION ====================
DHT20 dht; // I2C sensor
LiquidCrystal_I2C lcd(LCD_ADDR, LCD_COLS, LCD_ROWS);
Stepper stepper(STEPS_PER_REV, STEPPER_IN1, STEPPER_IN3, STEPPER_IN2, STEPPER_IN4);

FirebaseData fbdo;           
FirebaseAuth auth;           
FirebaseConfig config;       

// ==================== STATE VARIABLES ====================
float currentTemp       = 0.0;
float currentHumidity   = 0.0;
bool  bulbON            = false;
bool  fanON             = false;
bool  atomizerON        = false;
bool  firebaseReady     = false;
bool  eggTurningEnabled = true;   
int   incubationDay     = 1;      
int   eggTurnCount      = 0;      

unsigned long lastSensorRead   = 0;
unsigned long lastLCDUpdate    = 0;
unsigned long lastFirebaseSend = 0;
unsigned long lastFirebaseGet  = 0;
unsigned long lastEggTurn      = 0;
unsigned long systemStartTime  = 0;

byte degreeSymbol[8] = { 0b00110, 0b01001, 0b01001, 0b00110, 0b00000, 0b00000, 0b00000, 0b00000 };

// --- Function Prototypes ---
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
  
  pinMode(RELAY_BULB, OUTPUT);
  pinMode(RELAY_FAN, OUTPUT);
  pinMode(RELAY_ATOMIZER, OUTPUT);
  digitalWrite(RELAY_BULB, HIGH);
  digitalWrite(RELAY_FAN, HIGH);
  digitalWrite(RELAY_ATOMIZER, HIGH);

  // ---------- Initialize I2C ----------
  Wire.begin(I2C_SDA, I2C_SCL);
  
  // ---------- Initialize DHT20 ----------
  dht.begin();
  Serial.println("[OK] DHT20 I2C initialized");

  // ---------- Initialize LCD ----------
  lcd.init();
  lcd.backlight();
  lcd.createChar(0, degreeSymbol);
  lcd.setCursor(0, 0);
  lcd.print("  IoT Incubator ");
  lcd.setCursor(0, 1);
  lcd.print("  DHT20 System  ");

  stepper.setSpeed(15);  
  
  connectWiFi();
  initFirebase();

  systemStartTime = millis();
  lastEggTurn = millis();  
  
  delay(2000);
  lcd.clear();
}

// ============================================================
//                        MAIN LOOP
// ============================================================
void loop() {
  unsigned long currentMillis = millis();

  if (currentMillis - lastSensorRead >= SENSOR_READ_INTERVAL) {
    lastSensorRead = currentMillis;
    readSensors();
  }

  controlIncubator();

  if (currentMillis - lastLCDUpdate >= LCD_UPDATE_INTERVAL) {
    lastLCDUpdate = currentMillis;
    updateLCD();
  }

  if (Firebase.ready() && (currentMillis - lastFirebaseSend >= FIREBASE_SEND_INTERVAL)) {
    lastFirebaseSend = currentMillis;
    sendToFirebase();
  }

  if (Firebase.ready() && (currentMillis - lastFirebaseGet >= FIREBASE_GET_INTERVAL)) {
    lastFirebaseGet = currentMillis;
    getSettingsFromFirebase();
  }

  if (eggTurningEnabled && (currentMillis - lastEggTurn >= EGG_TURN_INTERVAL)) {
    lastEggTurn = currentMillis;
    turnEggs();
  }
}

// ============================================================
//                     READ SENSORS (DHT20)
// ============================================================
void readSensors() {
  int status = dht.read();

  if (status == DHT20_OK) {
    currentTemp = dht.getTemperature();
    currentHumidity = dht.getHumidity();

    Serial.printf("[SENSOR] T: %.1fC | H: %.1f%%\n", currentTemp, currentHumidity);
  } else {
    Serial.printf("[SENSOR] DHT20 Error: %d\n", status);
    // Don't reset current values to 0 to prevent Firebase overwrite
  }
}

// ============================================================
//               INCUBATOR CONTROL LOGIC
// ============================================================
void controlIncubator() {
  if (currentTemp == 0.0) return; // Wait for valid reading

  // Heater
  if (currentTemp < (TARGET_TEMP - TEMP_TOLERANCE)) {
    digitalWrite(RELAY_BULB, LOW); bulbON = true;
  } else if (currentTemp > (TARGET_TEMP + TEMP_TOLERANCE)) {
    digitalWrite(RELAY_BULB, HIGH); bulbON = false;
  }

  // Fan
  if (currentTemp > (TARGET_TEMP + TEMP_TOLERANCE)) {
    digitalWrite(RELAY_FAN, LOW); fanON = true;
  } else if (currentTemp <= TARGET_TEMP) {
    digitalWrite(RELAY_FAN, HIGH); fanON = false;
  }

  // Humidity - hysteresis control
  // When atomizer is ON: keep running until humidity reaches or exceeds target
  //   (any value >= TARGET covers the upper safety limit as well)
  // When atomizer is OFF: turn on only when humidity drops below target minus tolerance
  if (atomizerON) {
    if (currentHumidity >= TARGET_HUMIDITY) {
      digitalWrite(RELAY_ATOMIZER, HIGH); atomizerON = false;
    }
  } else if (currentHumidity < (TARGET_HUMIDITY - HUMIDITY_TOLERANCE)) {
    digitalWrite(RELAY_ATOMIZER, LOW); atomizerON = true;
  }
}

// ============================================================
//                    UPDATE LCD DISPLAY
// ============================================================
void updateLCD() {
  lcd.setCursor(0, 0);
  lcd.print("T:"); lcd.print(currentTemp, 1); lcd.write(0); lcd.print("C ");
  lcd.print("H:"); lcd.print(currentHumidity, 1); lcd.print("%");

  lcd.setCursor(0, 1);
  lcd.print(bulbON ? "HT:ON " : "HT:OFF");
  lcd.print(fanON ? " FN:ON" : " FN:OF");
  lcd.print(atomizerON ? " M:Y" : " M:N");
}

// ============================================================
//                 SEND DATA TO FIREBASE
// ============================================================
void sendToFirebase() {
  if (currentTemp == 0.0) return; // Safety check

  FirebaseJson json;
  json.set("temperature", currentTemp);
  json.set("humidity", currentHumidity);
  json.set("heaterOn", bulbON);
  json.set("fanOn", fanON);
  json.set("atomizerOn", atomizerON);
  json.set("eggTurnCount", eggTurnCount);
  json.set("uptime", getUptimeString());
  json.set("timestamp/.sv", "timestamp");

  Firebase.RTDB.setJSON(&fbdo, "/incubator/sensorData", &json);
}

// ============================================================
//            GET REMOTE SETTINGS FROM FIREBASE
// ============================================================
void getSettingsFromFirebase() {
  if (!Firebase.ready()) return;

  if (Firebase.RTDB.getFloat(&fbdo, "/incubator/settings/targetTemp")) {
    if (fbdo.floatData() > 0) TARGET_TEMP = fbdo.floatData();
  }
  if (Firebase.RTDB.getFloat(&fbdo, "/incubator/settings/targetHumidity")) {
    if (fbdo.floatData() > 0) TARGET_HUMIDITY = fbdo.floatData();
  }
  if (Firebase.RTDB.getBool(&fbdo, "/incubator/settings/eggTurning")) {
    eggTurningEnabled = fbdo.boolData();
  }
}

// ============================================================
//                     TURN EGGS
// ============================================================
void turnEggs() {
  if (!eggTurningEnabled) return;

  int stepsToTurn = 512; // 90 degrees
  if (eggTurnCount % 2 == 0) stepper.step(stepsToTurn);
  else stepper.step(-stepsToTurn);

  eggTurnCount++;
  disableStepperPins();
  
  if (Firebase.ready()) {
    Firebase.RTDB.setInt(&fbdo, "/incubator/sensorData/eggTurnCount", eggTurnCount);
  }
}

void disableStepperPins() {
  digitalWrite(STEPPER_IN1, LOW); digitalWrite(STEPPER_IN2, LOW);
  digitalWrite(STEPPER_IN3, LOW); digitalWrite(STEPPER_IN4, LOW);
}

void connectWiFi() {
  WiFi.mode(WIFI_AP_STA);
  WiFi.softAP(AP_SSID, AP_PASSWORD);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500); Serial.print("."); attempts++;
  }
  if (WiFi.status() == WL_CONNECTED) Serial.println("\nWiFi Connected");
}

void initFirebase() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  Firebase.begin(&config, &auth);
  Firebase.reconnectNetwork(true);
}

String getUptimeString() {
  unsigned long s = millis() / 1000;
  return String(s / 3600) + "h " + String((s % 3600) / 60) + "m";
}