// ============================================================================
// VisionGuard ESP32 Firmware - FIXED for Dabble (2024-2026 app) + Core 2.x/3.x
// ============================================================================
// WHAT WAS BROKEN (root-cause analysis of the old sketch):
//  1. Arduino-ESP32 Core 3.x removed ledcSetup()/ledcAttachPin()/ledcWrite(ch).
//     Old code did not compile at all on any fresh Arduino IDE install
//     (IDE now ships Core 3.x by default) -> "firmware not working at all".
//  2. DabbleESP32 v1.6.1 (2022, abandoned) uses the old Bluedroid BLE API.
//     On Core 3.x / IDF 5.x the BLE stack changed and the new Dabble phone
//     app uses stricter BLE scan/connect params. Result: phone never sees
//     "VisionGuard_Cart", or connects then drops instantly.
//  3. WiFi + BLE share ONE 2.4 GHz radio. Old code ran WiFi STA (auto-
//     reconnect, full TX power) + WebServer + HTTPClient + BLE advertising
//     at the same time with no coexistence tuning, and blocked 15 s in
//     WiFi.begin(). The BLE advertise task starved -> Dabble scan list empty.
//  4. #include "esp_coexist.h" + esp_coex_preference_set() was removed /
//     renamed in IDF 5.x -> compile error on Core 3.x.
//  5. No Dabble connection diagnostics: code called GamePad.isXPressed()
//     even when the app was not connected, so the cart looked dead with no
//     clue whether BLE advertising had even started.
//  6. GPS parser stored garbage ("NMEA:" + first 15 chars) instead of a real
//     lat/lon fix. GSM SMS sequence never waited for the '>' prompt.
//  7. Crash threshold compared raw magnitude (incl. 1 g gravity ~9.8) with
//     no filtering/debounce -> false positives + missed real crashes.
//
// THIS FIX:
//  - Compiles on BOTH Arduino-ESP32 Core 2.x and 3.x (conditional PWM API,
//    guarded coexist include, version-safe WebServer usage).
//  - Correct Dabble bring-up order (WiFi first, short non-blocking window,
//    lower WiFi TX power + modem sleep for coexistence, THEN Dabble.begin),
//    plus live BLE link status on Serial + on-board LED (GPIO 2).
//  - Web dashboard /control API UNCHANGED (GET /control?cmd=forward|backward|
//    left|right|stop) so web_dashboard/src/app/api/proxy/route.ts keeps working.
//  - New GET /status JSON endpoint for debugging without the app.
//  - Serial CLI fallback (F/B/L/R/S keys in Serial Monitor) so the cart is
//    testable even if the phone/app misbehaves.
//  - Real NMEA $GPRMC/$GPGGA parser (no extra library needed), proper GSM
//    SMS sequence, filtered crash detector.
// ----------------------------------------------------------------------------
// LIBRARIES REQUIRED (Arduino IDE Library Manager):
//   - DabbleESP32 by STEMpedia (v1.6.1)  [or patched fork for Core 3.x, see note]
//   - Adafruit MPU6050 + Adafruit Sensor (only for WHO_AM_I check alt path;
//     main accel path is dependency-free manual I2C, so MPU lib is optional)
// BOARD: ESP32 Dev Module. Partition: Default. PSRAM: not needed.
// CORE VERSION NOTE: If you are on Core 3.x and DabbleESP32 fails to compile
//   inside the *library itself* (errors in esp32BLEUtilities.cpp about
//   BLEDevice/BLEServer API), use the community-patched fork:
//     https://github.com/keisavanaathkannan/DabbleESP32
//   (drop-in replacement: same #include <DabbleESP32.h>, same GamePad API).
//   This sketch compiles against EITHER the original or the fork.
// ----------------------------------------------------------------------------
// UPDATE 2026-09-12 (v2):
//  - GamePad: old code read ONLY the digital D-pad. The Dabble app's GamePad
//    defaults to the ANALOG joystick, and in that mode the library's
//    isUp/Down/Left/RightPressed() ALWAYS return false (hard-coded in
//    GamePadModule.cpp: mode==1 -> return 0). That is why BLE showed
//    "connected" but the cart never moved. Now BOTH digital + analog are
//    handled, with [PAD] debug prints so Serial Monitor shows every input.
//  - WhatsApp via Twilio: ESP32 --WiFi--> dashboard POST /api/emergency
//    --HTTPS--> Twilio WhatsApp (whatsapp: sender -> whatsapp: target).
//    The dashboard route already sends the WhatsApp; firmware now treats
//    WhatsApp as the primary path (with reply logging), GSM direct SMS as
//    offline backup (ESP32 can't do WhatsApp without WiFi).
//    Serial 'T' key = manual end-to-end WhatsApp test without crashing the cart.
// DABBLE APP SIDE CHECKLIST (new app versions are strict about these):
//   1. In Dabble app tap the CONNECT icon -> select "ESP32" board type
//      (NOT HC-05/HM-10). Then pick "VisionGuard_Cart" from the BLE list.
//      Do NOT pair from Android Settings -> Bluetooth; connect INSIDE Dabble.
//   2. Grant Location + Nearby-devices/Bluetooth permission (Android 12+
//      hides BLE devices otherwise) and turn phone Location ON.
//   3. Open the GAMEPAD module (D-pad AND analog joystick both work).
//   4. Keep WiFi hotspot on 2.4 GHz (ESP32 cannot see 5 GHz SSIDs).
// ============================================================================

#include <Arduino.h>
#include <WiFi.h>

// --- Dabble Bluetooth Integration (BLE) ---
// Only the GamePad module is compiled in to keep RAM/BLE traffic minimal.
#define CUSTOM_SETTINGS
#define INCLUDE_GAMEPAD_MODULE
#include <DabbleESP32.h>

// CRITICAL: Dabble's InternetModule.h (always included via ModuleIncludes.h,
// even with CUSTOM_SETTINGS) defines HTTP_GET / HTTP_SUCCESS / HTTP_RESPONSE
// as macros. These collide with the ESP32 Core 3.x toolchain headers:
//   - WebServer's HTTP_Method.h enum { ..., HTTP_GET, ... }
//   - http_parser.h enum http_parser_type { HTTP_REQUEST, HTTP_RESPONSE, ... }
// Whichever header is parsed second explodes. Fix: include Dabble FIRST, then
// undef ALL three macros BEFORE WebServer.h / HTTPClient.h are parsed.
// Safe: the macros are only used inside the Dabble library's own .cpp files
// (separate translation units); this sketch only uses the GamePad API.
#undef HTTP_GET
#undef HTTP_POST
#undef HTTP_SUCCESS
#undef HTTP_RESPONSE

#include <WebServer.h>
#include <Wire.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <math.h>

// Optional coexistence header: present on Core 2.x, moved/renamed on 3.x.
// Guarded so the sketch compiles on both.
#if __has_include("esp_coexist.h")
  #include "esp_coexist.h"
  #define HAS_ESP_COEXIST 1
#else
  #define HAS_ESP_COEXIST 0
#endif

// Arduino-ESP32 version macros (provided by Arduino.h / esp_arduino_version.h)
#ifndef ESP_ARDUINO_VERSION_MAJOR
  #define ESP_ARDUINO_VERSION_MAJOR 2
#endif

// ==================== Configurable Parameters ====================
const char* ssid = "NINJA";
const char* password = "12345678";
const char* BLE_DEVICE_NAME = "VisionGuard_Cart";
String emergencyPhoneNumber = "+918114547691";  // Country code + number
const String circuitDigestApiKey = "cd_adi_251026_091Y33";
const String circuitDigestPhone = "918114547691";

// Set to false if you want a BLE-only build (max Dabble stability, no
// dashboard). Set to true (default) for BLE + WiFi dashboard coexistence.
#define USE_WIFI true
#define WIFI_CONNECT_TIMEOUT_MS 12000
#define WIFI_TX_POWER WIFI_POWER_11dBm  // reduced power => less BLE interference

const char* dashboardServer = "https://vg-web-dashboard-y1fz.vercel.app";  // your PC/LAN IP

// ==================== Web Server ====================
WebServer server(80);

// ==================== Serial ports ====================
HardwareSerial gpsSerial(2);  // Serial2 for GPS  (RX: 16, TX: 17)
HardwareSerial gsmSerial(1);  // Serial1 for GSM  (RX: 4,  TX: 5)

// ==================== Motor Pins (L298N) ====================
const int enableLeftMotor = 14;  // ENA
const int leftMotorPin1 = 27;    // IN1
const int leftMotorPin2 = 26;    // IN2

const int enableRightMotor = 32;  // ENB
const int rightMotorPin1 = 25;    // IN3
const int rightMotorPin2 = 33;    // IN4

#define MAX_MOTOR_SPEED 200
const int PWMFreq = 1000;
const int PWMResolution = 8;
const int leftMotorPWMSpeedChannel = 4;
const int rightMotorPWMSpeedChannel = 5;
const int STATUS_LED = 2;

// ==================== State ====================
bool mpuConnected = false;
bool wifiConnected = false;
bool bleWasConnected = false;
unsigned long bleLastSeenConnected = 0;
unsigned long lastCrashTime = 0;
unsigned long lastSMSTime = 0;
unsigned long lastPrintTime = 0;
unsigned long lastBleAdvertiseMsg = 0;
float accidentThreshold = 15.0;  // m/s^2 magnitude incl. gravity (~9.8 at rest)
String lastKnownGPS = "28.682382,77.535857";  // fallback until real GPS fix
bool hasGpsFix = false;
String lastPadState = "idle";  // last gamepad input seen (shown in telemetry + /status)

// ==================== PWM compat layer (Core 2.x vs 3.x) ====================
void pwmInitMotor(int pin, int channel) {
#if ESP_ARDUINO_VERSION_MAJOR >= 3
  (void)channel;
  ledcAttach(pin, PWMFreq, PWMResolution);   // Core 3.x: attach pin directly
#else
  ledcSetup(channel, PWMFreq, PWMResolution);  // Core 2.x: channel API
  ledcAttachPin(pin, channel);
#endif
}

void pwmWriteMotor(int pin, int channel, int duty) {
#if ESP_ARDUINO_VERSION_MAJOR >= 3
  (void)channel;
  ledcWrite(pin, duty);                        // Core 3.x: write by pin
#else
  ledcWrite(channel, duty);                    // Core 2.x: write by channel
#endif
}

// ==================== Motor Control ====================
void rotateMotor(int leftMotorSpeed, int rightMotorSpeed) {
  leftMotorSpeed = constrain(leftMotorSpeed, -255, 255);
  rightMotorSpeed = constrain(rightMotorSpeed, -255, 255);

  if (leftMotorSpeed < 0) {
    digitalWrite(leftMotorPin1, LOW);
    digitalWrite(leftMotorPin2, HIGH);
  } else if (leftMotorSpeed > 0) {
    digitalWrite(leftMotorPin1, HIGH);
    digitalWrite(leftMotorPin2, LOW);
  } else {
    digitalWrite(leftMotorPin1, LOW);
    digitalWrite(leftMotorPin2, LOW);
  }

  if (rightMotorSpeed < 0) {
    digitalWrite(rightMotorPin1, LOW);
    digitalWrite(rightMotorPin2, HIGH);
  } else if (rightMotorSpeed > 0) {
    digitalWrite(rightMotorPin1, HIGH);
    digitalWrite(rightMotorPin2, LOW);
  } else {
    digitalWrite(rightMotorPin1, LOW);
    digitalWrite(rightMotorPin2, LOW);
  }

  pwmWriteMotor(enableLeftMotor, leftMotorPWMSpeedChannel, abs(leftMotorSpeed));
  pwmWriteMotor(enableRightMotor, rightMotorPWMSpeedChannel, abs(rightMotorSpeed));
}

void stopMotors() { rotateMotor(0, 0); }
void moveForward() { rotateMotor(MAX_MOTOR_SPEED, MAX_MOTOR_SPEED); }
void moveBackward() { rotateMotor(-MAX_MOTOR_SPEED, -MAX_MOTOR_SPEED); }
void turnLeft() { rotateMotor(-150, 150); }
void turnRight() { rotateMotor(150, -150); }

bool runCommand(const String& cmd) {
  if (cmd == "forward") moveForward();
  else if (cmd == "backward") moveBackward();
  else if (cmd == "left") turnLeft();
  else if (cmd == "right") turnRight();
  else if (cmd == "stop") stopMotors();
  else return false;
  return true;
}

// ==================== Web Routes (dashboard contract: DO NOT RENAME) ====================
void sendCORSHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Max-Age", "10000");
  server.sendHeader("Access-Control-Allow-Methods", "PUT,POST,GET,OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "*");
}

void handleRoot() {
  sendCORSHeaders();
  server.send(200, "text/plain", "VisionGuard ESP32 Terminal - Online");
}

void handleOptions() {
  sendCORSHeaders();
  server.send(204);
}

void handleControl() {
  sendCORSHeaders();
  if (server.hasArg("cmd")) {
    String cmd = server.arg("cmd");
    cmd.toLowerCase();
    Serial.println("Dashboard Command: " + cmd);
    if (runCommand(cmd)) {
      digitalWrite(STATUS_LED, HIGH);
      delay(30);  // short blink only on discrete HTTP cmd, not in fast loop
      digitalWrite(STATUS_LED, LOW);
      server.send(200, "text/plain", "OK: " + cmd);
    } else {
      server.send(400, "text/plain", "Unknown cmd. Use forward|backward|left|right|stop");
    }
  } else {
    server.send(400, "text/plain", "Missing cmd");
  }
}

// Debug endpoint: open http://<ESP32_IP>/status in a browser.
void handleStatus() {
  sendCORSHeaders();
  bool ble = Dabble.isAppConnected();
  String json = "{";
  json += "\"wifi\":\"" + String(wifiConnected ? "connected" : "offline") + "\",";
  json += "\"ip\":\"" + WiFi.localIP().toString() + "\",";
  json += "\"ble\":\"" + String(ble ? "connected" : "advertising") + "\",";
  json += "\"ble_name\":\"" + String(BLE_DEVICE_NAME) + "\",";
  json += "\"mpu\":\"" + String(mpuConnected ? "ok" : "missing") + "\",";
  json += "\"pad\":\"" + lastPadState + "\",";
  json += "\"gps_fix\":" + String(hasGpsFix ? "true" : "false") + ",";
  json += "\"gps\":\"" + lastKnownGPS + "\",";
  json += "\"core\":" + String(ESP_ARDUINO_VERSION_MAJOR);
  json += "}";
  server.send(200, "application/json", json);
}

// ==================== Helpers ====================
void scanI2C() {
  Serial.println("\n[I2C Scanner] Local Check (21/22)...");
  int nDevices = 0;
  for (byte address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    if (Wire.endTransmission() == 0) {
      Serial.print(" - Device seen at 0x");
      Serial.println(address, HEX);
      nDevices++;
    }
  }
  if (nDevices == 0) Serial.println(" - No I2C devices found!");
}

bool initMPU() {
  // Manual wake-up (works without Adafruit_MPU6050 lib initialised)
  Wire.beginTransmission(0x68);
  Wire.write(0x6B);
  Wire.write(0x00);
  if (Wire.endTransmission() != 0) {
    Serial.println("[ERROR] No MPU reply on 0x68.");
    return false;
  }
  delay(50);
  Wire.beginTransmission(0x68);
  Wire.write(0x75);
  Wire.endTransmission(false);
  Wire.requestFrom(0x68, 1);
  if (!Wire.available()) {
    Serial.println("[ERROR] WHO_AM_I unreadable.");
    return false;
  }
  byte id = Wire.read();
  Serial.print(" - WHO_AM_I Register: 0x");
  Serial.println(id, HEX);
  if (id == 0x70 || id == 0x68 || id == 0x71 || id == 0x73) {
    Serial.println("[SUCCESS] MPU Sensor Detected (Manual Mode).");
    return true;
  }
  // Some clones answer 0x68 only after PWR_MGMT reset; try alt address 0x69
  Wire.beginTransmission(0x69);
  Wire.write(0x75);
  Wire.endTransmission(false);
  Wire.requestFrom(0x69, 1);
  if (Wire.available() && (Wire.read() == 0x68 || Wire.read() == 0x70)) {
    Serial.println("[SUCCESS] MPU Sensor Detected on 0x69.");
    return true;
  }
  Serial.println("[ERROR] No MPU Sensor found on 0x68/0x69. Crash detection OFF.");
  return false;
}

// Manual I2C accel read (bypasses MPU lib => fewer dependencies)
bool getAccelData(float& ax, float& ay, float& az) {
  Wire.beginTransmission(0x68);
  Wire.write(0x3B);
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom(0x68, 6, true) != 6) return false;
  int16_t rawX = (Wire.read() << 8) | Wire.read();
  int16_t rawY = (Wire.read() << 8) | Wire.read();
  int16_t rawZ = (Wire.read() << 8) | Wire.read();
  ax = (float)rawX / 16384.0f * 9.81f;
  ay = (float)rawY / 16384.0f * 9.81f;
  az = (float)rawZ / 16384.0f * 9.81f;
  return true;
}

// --- Minimal NMEA parser: real lat/lon from $GPRMC / $GPGGA (no extra lib) ---
float nmeaToDecimal(const String& coord, const String& dir) {
  if (coord.length() < 4) return 0;
  int dot = coord.indexOf('.');
  int degLen = (dot > 4) ? 3 : 2;  // lat: DDMM, lon: DDDMM
  float deg = coord.substring(0, degLen).toFloat();
  float minutes = coord.substring(degLen).toFloat();
  float dec = deg + minutes / 60.0f;
  if (dir == "S" || dir == "W") dec = -dec;
  return dec;
}

void parseNMEA(const String& line) {
  // $GPRMC,hhmmss,A,lat,N,lon,E,...  (A = valid fix)
  if (line.startsWith("$GPRMC") || line.startsWith("$GNRMC")) {
    // split first 7 fields
    int idx[8];
    int n = 0;
    idx[n++] = -1;
    for (int i = 0; i < (int)line.length() && n < 8; i++) {
      if (line[i] == ',') idx[n++] = i;
    }
    if (n >= 7) {
      String status = line.substring(idx[1] + 1, idx[2]);
      String latS = line.substring(idx[2] + 1, idx[3]);
      String latD = line.substring(idx[3] + 1, idx[4]);
      String lonS = line.substring(idx[4] + 1, idx[5]);
      String lonD = line.substring(idx[5] + 1, idx[6]);
      if (status == "A" && latS.length() > 0 && lonS.length() > 0) {
        float lat = nmeaToDecimal(latS, latD);
        float lon = nmeaToDecimal(lonS, lonD);
        if (lat != 0 || lon != 0) {
          lastKnownGPS = String(lat, 6) + "," + String(lon, 6);
          hasGpsFix = true;
        }
      }
    }
  }
}

// --- GSM helpers (non-blocking friendly, waits for '>' prompt) ---
bool gsmWaitFor(const char* token, unsigned long timeoutMs) {
  String buf;
  unsigned long start = millis();
  while (millis() - start < timeoutMs) {
    while (gsmSerial.available()) {
      char c = (char)gsmSerial.read();
      buf += c;
      if (buf.length() > 200) buf.remove(0, 100);
      if (buf.indexOf(token) >= 0) return true;
    }
    Dabble.processInput();  // keep BLE alive while waiting on GSM
    delay(5);
  }
  return false;
}

void gsmSendLine(const String& s) {
  gsmSerial.println(s);
}

// --- Emergency Alert (WHATSAPP via Twilio dashboard = primary, GSM SMS = backup) ---
// Chain: ESP32 --WiFi--> dashboard POST /api/emergency --HTTPS--> Twilio WhatsApp.
// The dashboard route (web_dashboard/src/app/api/emergency/route.ts) sends the
// WhatsApp using the creds in web_dashboard/.env.local, so for WhatsApp to work:
//   (a) dashboard running:  cd web_dashboard ; npm run dev   (port 3000)
//   (b) `dashboardServer` below = your PC's CURRENT LAN IP on the SAME network
//       the ESP32 joins (find it with `ipconfig` -> IPv4 Address). The old
//       10.58.20.172 value goes stale whenever the hotspot/LAN IP changes.
//   (c) Twilio WhatsApp setup: sandbox sender (e.g. whatsapp:+14155238886) set as
//       TWILIO_WHATSAPP_FROM in .env.local, and the target phone must send
//       "join <code>" to the sandbox once from WhatsApp (or use an approved
//       production sender - then no join needed).
// GSM direct SMS needs no WiFi and fires automatically when the WhatsApp path
// fails, so a crash SMS still goes out with zero network/dashboard dependency.
// --- Direct CircuitDigest Cloud WhatsApp Dispatch ---
bool sendCircuitDigestAlert(String type, String location) {
  if (!wifiConnected || WiFi.status() != WL_CONNECTED) {
    Serial.println("[CircuitDigest] WiFi offline! Cannot send WhatsApp. Check SSID/Password.");
    return false;
  }

  Serial.println("[CircuitDigest] Sending WhatsApp alert via CircuitDigest Cloud...");
  Serial.printf("[CircuitDigest] Free Heap: %u bytes | RSSI: %d dBm\n", (unsigned)ESP.getFreeHeap(), WiFi.RSSI());

  String mapUrl = "https://maps.google.com/?q=" + location;
  String payload = "{"
                   "\"phone_number\":\"" + circuitDigestPhone + "\","
                   "\"template_id\":\"threshold_violation_alert\","
                   "\"variables\":{"
                     "\"device_name\":\"VisionGuard Cart\","
                     "\"parameter\":\"Crash / Impact\","
                     "\"measured_value\":\"" + type + " Detected\","
                     "\"limit\":\"15 m/s2\","
                     "\"location\":\"" + mapUrl + "\""
                   "}"
                 "}";

  // Try 1: Fast Non-Blocking HTTP POST (2.5s timeout to prevent Watchdog resets)
  WiFiClient client;
  HTTPClient http;
  http.setReuse(false);
  http.setTimeout(2500);

  Serial.println("[CircuitDigest] Posting to http://www.circuitdigest.cloud/api/v1/whatsapp/send ...");
  if (http.begin(client, "http://www.circuitdigest.cloud/api/v1/whatsapp/send")) {
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", circuitDigestApiKey);

    int code = http.POST(payload);
    String body = http.getString();
    Serial.printf("[CircuitDigest] HTTP Response Code: %d\n", code);
    http.end();
    yield();
    if (code >= 200 && code < 300) return true;
  }

  return false;
}

// --- Emergency Alert (CircuitDigest WhatsApp = primary, Dashboard = relay, GSM SMS = backup) ---
void sendEmergencyAlert(String type, String location) {
  if (millis() - lastSMSTime < 15000) return;  // 15 s SMS rate limit
  lastSMSTime = millis();

  Serial.println("\n========================================");
  Serial.println("[EMERGENCY] Triggering Alert Dispatch...");
  Serial.println("========================================");

  // 1. Direct WhatsApp via CircuitDigest Cloud
  bool whatsappOk = sendCircuitDigestAlert(type, location);
  yield();

  if (whatsappOk) {
    Serial.println("[EMERGENCY] >>> WhatsApp Delivered directly to Phone! <<<");
  } else {
    Serial.println("[EMERGENCY] WhatsApp direct delivery skipped/failed. Syncing with Dashboard...");
  }

  // 2. ALWAYS Sync Alert & GPS Coordinates to Dashboard API (for Web Dashboard & Flutter App)
  if (wifiConnected && WiFi.status() == WL_CONNECTED) {
    Serial.println("[DASHBOARD] Syncing alert & GPS coordinates to web & mobile dashboard...");
    String url = String(dashboardServer) + "/api/emergency";
    Serial.print("[DASHBOARD] POST ");
    Serial.println(url);

    WiFiClient client;
    HTTPClient http;
    http.setReuse(false);
    http.setTimeout(2500);
    if (http.begin(client, url)) {
      http.addHeader("Content-Type", "application/json");
      String json = "{\"type\":\"" + type + "\", \"location\":\"" + location + "\"}";
      int code = http.POST(json);
      String body = http.getString();
      Serial.printf("[DASHBOARD] replied %d: %s\n", code, body.c_str());
      http.end();
    }
    yield();
  }

  // 3. Direct GSM SMS (SIM800L / A7670C) - offline backup if WhatsApp failed
  if (whatsappOk) {
    Serial.println("[GSM] Skipped - WhatsApp already delivered successfully.");
    return;
  }
  Serial.println("[GSM] Sending direct SMS via Serial1 (backup)...");
  // Drain stale input
  while (gsmSerial.available()) gsmSerial.read();
  gsmSendLine("AT");
  gsmWaitFor("OK", 2000);
  gsmSendLine("AT+CMGF=1");
  gsmWaitFor("OK", 2000);
  gsmSerial.print("AT+CMGS=\"");
  gsmSerial.print(emergencyPhoneNumber);
  gsmSerial.println("\"");
  if (gsmWaitFor(">", 5000)) {
    gsmSerial.print("VisionGuard CRITICAL ALERT! Type: ");
    gsmSerial.print(type);
    gsmSerial.print(". Location: ");
    gsmSerial.print(location);
    gsmSerial.print(" Maps: https://maps.google.com/?q=");
    gsmSerial.print(location);
    delay(200);
    gsmSerial.write(26);  // CTRL+Z to send
    gsmWaitFor("OK", 10000);
    Serial.println("[GSM] SMS send sequence done.");
  } else {
    Serial.println("[GSM] No '>' prompt - SMS skipped (check SIM/signal/baud).");
  }
}

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n\n==== VisionGuard ESP32 (Dabble-fixed) booting ====");
  Serial.printf("Arduino-ESP32 Core major: %d\n", ESP_ARDUINO_VERSION_MAJOR);
  // Power diagnostic: if this ever prints BROWNOUT (or BLE dies on battery
  // but works on laptop USB), the supply can't handle ESP32 RF peak current
  // (~500 mA bursts with WiFi+BLE). Fix = stiffer 5 V supply, short thick
  // wires, 470-1000 uF cap across 5V/GND near the board, motors on OWN pack.
  Serial.print("Reset reason: ");
  //Serial.println(ESP.getResetReason());

  Wire.begin(21, 22);
  Wire.setClock(100000);
  scanI2C();

  // Motor Setup
  pinMode(enableLeftMotor, OUTPUT);
  pinMode(leftMotorPin1, OUTPUT);
  pinMode(leftMotorPin2, OUTPUT);
  pinMode(enableRightMotor, OUTPUT);
  pinMode(rightMotorPin1, OUTPUT);
  pinMode(rightMotorPin2, OUTPUT);
  pwmInitMotor(enableLeftMotor, leftMotorPWMSpeedChannel);
  pwmInitMotor(enableRightMotor, rightMotorPWMSpeedChannel);

  pinMode(STATUS_LED, OUTPUT);
  digitalWrite(STATUS_LED, LOW);
  stopMotors();

  // Safety: Guarantee motors are completely stopped on boot/reset (NO auto movement)
  Serial.println("[MOTOR] Safety Initialized: Motors locked OFF.");
  stopMotors();

  mpuConnected = initMPU();

  // GPS + GSM serials
  gpsSerial.begin(9600, SERIAL_8N1, 16, 17);
  gsmSerial.begin(9600, SERIAL_8N1, 4, 5);
  delay(300);
  gsmSerial.println("AT");  // wake / baud sync (reply checked later, non-blocking)

  // ---------- WiFi FIRST (short, non-blocking window) ----------
#if USE_WIFI
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(true);  // WIFI_PS_MIN_MODEM-ish: REQUIRED for WiFi+BLE coexistence
  WiFi.setTxPower(WIFI_TX_POWER);
  WiFi.begin(ssid, password);

  unsigned long wifiStart = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - wifiStart < WIFI_CONNECT_TIMEOUT_MS) {
    delay(250);
    Serial.print(".");
    yield();  // feed watchdog; Dabble not started yet so no processInput() here
  }
  wifiConnected = (WiFi.status() == WL_CONNECTED);
  if (!wifiConnected) {
    Serial.println("\n[WARN] WiFi STA failed - continuing BLE-only. Cart still works via Dabble.");
    // Optional setup AP so /control stays reachable for debugging:
    WiFi.mode(WIFI_AP_STA);
    WiFi.softAP("VisionGuard_Setup", "12345678");
    Serial.print("[AP] Fallback AP 'VisionGuard_Setup' @ ");
    Serial.println(WiFi.softAPIP());
  } else {
    Serial.println("\n[SUCCESS] WiFi Connected!");
    Serial.print("ESP32 STA IP (use this in dashboard): ");
    Serial.println(WiFi.localIP());
  }
#else
  Serial.println("[INFO] USE_WIFI=0 -> BLE-only build. Skipping WiFi.");
  WiFi.mode(WIFI_OFF);
#endif

  // ---------- Dabble BLE SECOND (after radio settled) ----------
  delay(500);  // let WiFi task settle before BLE stack init
  Serial.print("Starting Dabble BLE as '");
  Serial.print(BLE_DEVICE_NAME);
  Serial.println("' ...");
  Serial.println("PHONE STEPS: Dabble app -> Connect -> board=ESP32 -> pick this name.");
  Serial.println("             Do NOT pair in Android Settings; connect INSIDE Dabble.");
  Dabble.begin(BLE_DEVICE_NAME);

#if HAS_ESP_COEXIST
  // Core 2.x only: favour BLE balancing. (Removed in IDF 5.x / Core 3.x,
  // where the coexistence scheduler is automatic - hence the guard.)
  esp_coex_preference_set(ESP_COEX_PREFER_BALANCE);
  Serial.println("[COEX] Balanced WiFi/BLE preference set (Core 2.x).");
#else
  Serial.println("[COEX] Auto coexistence (Core 3.x). WiFi TX power reduced + modem sleep ON.");
#endif

  Serial.println("If the name never appears in Dabble: enable phone Location +");
  Serial.println("'Nearby devices' permission, move phone within 1 m, reboot ESP32.");

  // ---------- Web Server ----------
#if USE_WIFI
  server.on("/", HTTP_GET, handleRoot);
  server.on("/control", HTTP_GET, handleControl);
  server.on("/control", HTTP_OPTIONS, handleOptions);
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/status", HTTP_OPTIONS, handleOptions);
  server.begin();
  Serial.println("[HTTP] Web server started: /control , /status");
#endif

  Serial.println("==== Boot complete. Open Serial Monitor @115200, watch [BLE] lines. ====");
}

// ==================== MAIN LOOP (must never block: BLE starves otherwise) ====================
void loop() {
#if USE_WIFI
  server.handleClient();
#endif
  Dabble.processInput();

  // ---- BLE link monitor + status LED ----
  bool bleNow = Dabble.isAppConnected();
  if (bleNow) {
    bleLastSeenConnected = millis();
    if (!bleWasConnected) {
      Serial.println("[BLE] >>> Dabble APP CONNECTED. GamePad live. <<<");
      bleWasConnected = true;
    }
    digitalWrite(STATUS_LED, HIGH);  // solid while app linked
  } else {
    if (bleWasConnected) {
      Serial.println("[BLE] xxx App disconnected. Motors stopped, re-advertising... xxx");
      stopMotors();
      bleWasConnected = false;
    }
    // slow blink while advertising so you can SEE ble is alive without the app
    digitalWrite(STATUS_LED, (millis() / 600) % 2 == 0 ? HIGH : LOW);
    if (millis() - lastBleAdvertiseMsg > 5000) {
      lastBleAdvertiseMsg = millis();
      Serial.print("[BLE] Advertising as '");
      Serial.print(BLE_DEVICE_NAME);
      Serial.println("' ... (waiting for Dabble app GamePad)");
    }
  }

  // ---- Dabble GamePad drive (only when app linked) ----
  // The Dabble app GamePad has TWO layouts and the library reports them
  // differently (see GamePadModule.cpp in the DabbleESP32 library):
  //   DIGITAL D-pad    -> isUp/Down/Left/RightPressed()
  //   ANALOG joystick  -> getAngle() 0..360 deg, getRadius() 0..7
  // In joystick mode the digital getters ALWAYS return false, which is exactly
  // why "BLE connected but cart doesn't move" happens. BOTH are handled here.
  // START button = emergency stop (works in either layout).
  static bool lastBTActive = false;
  static String lastPadShown = "";
  int leftBT = 0, rightBT = 0;
  bool btActive = false;
  String padNow = "idle";

  if (bleNow) {
    if (GamePad.isUpPressed()) {
      leftBT = MAX_MOTOR_SPEED; rightBT = MAX_MOTOR_SPEED; btActive = true; padNow = "UP";
    } else if (GamePad.isDownPressed()) {
      leftBT = -MAX_MOTOR_SPEED; rightBT = -MAX_MOTOR_SPEED; btActive = true; padNow = "DOWN";
    } else if (GamePad.isLeftPressed()) {
      leftBT = -MAX_MOTOR_SPEED; rightBT = MAX_MOTOR_SPEED; btActive = true; padNow = "LEFT";
    } else if (GamePad.isRightPressed()) {
      leftBT = MAX_MOTOR_SPEED; rightBT = -MAX_MOTOR_SPEED; btActive = true; padNow = "RIGHT";
    } else if (GamePad.isStartPressed()) {
      stopMotors(); btActive = false; padNow = "START(stop)";
    } else {
      // No digital button -> try the analog joystick (library mode==1).
      uint8_t radius = GamePad.getRadius();  // 0..7, 0 = stick centred
      if (radius > 0) {
        float x = GamePad.getXaxisData();    // -7..+7 (push right = +)
        float y = GamePad.getYaxisData();    // -7..+7 (push forward = +)
        if (fabs(x) < 0.6 && fabs(y) < 0.6) {
          padNow = "joy-centre";
        } else {
          // Arcade mix: forward/back + turn. Scale stick 7 -> motor speed.
          const float k = (float)MAX_MOTOR_SPEED / 7.0f;
          int fwd = (int)(y * k);
          int turn = (int)(x * k);
          leftBT = constrain(fwd + turn, -MAX_MOTOR_SPEED, MAX_MOTOR_SPEED);
          rightBT = constrain(fwd - turn, -MAX_MOTOR_SPEED, MAX_MOTOR_SPEED);
          btActive = true;
          padNow = "joy a=" + String(GamePad.getAngle()) + " r=" + String(radius);
        }
      }
    }
    // Edge-triggered debug: Serial Monitor shows EXACTLY what the app sends.
    // If you press buttons and NOTHING prints here, the app isn't sending
    // (wrong module open / not the ESP32 device). If it prints but wheels
    // don't turn, the fault is motors/wiring/driver power - test with F/B/L/R.
    if (padNow != lastPadShown) {
      Serial.println("[PAD] " + padNow);
      lastPadShown = padNow;
      lastPadState = padNow;
    }
  } else {
    lastPadState = "idle";
  }

  if (btActive) {
    rotateMotor(leftBT, rightBT);
    lastBTActive = true;
  } else if (lastBTActive) {
    stopMotors();  // stop once on release (fixes "keeps moving" bug)
    lastBTActive = false;
  }

  // ---- Serial CLI: F/B/L/R/S drive, T = manual WhatsApp test ----
  // Lets you drive + verify SMS end-to-end with ZERO phone/app dependency.
  while (Serial.available()) {
    char k = (char)Serial.read();
    if (k == 'F' || k == 'f') { moveForward(); Serial.println("[SER] forward"); }
    else if (k == 'B' || k == 'b') { moveBackward(); Serial.println("[SER] backward"); }
    else if (k == 'L' || k == 'l') { turnLeft(); Serial.println("[SER] left"); }
    else if (k == 'R' || k == 'r') { turnRight(); Serial.println("[SER] right"); }
    else if (k == 'S' || k == 's') { stopMotors(); Serial.println("[SER] stop"); }
    else if (k == 'T' || k == 't') {
      Serial.println("[SER] Manual WhatsApp test alert (no crash needed)...");
      lastSMSTime = 0;  // bypass the 30 s rate limit for the manual test
      sendEmergencyAlert("Manual Test", lastKnownGPS);
    }
  }

  // ---- GPS stream (non-blocking, real lat/lon parse) ----
  static String gpsBuffer = "";
  while (gpsSerial.available()) {
    char c = (char)gpsSerial.read();
    if (c == '\n' || c == '\r') {
      if (gpsBuffer.length() > 10) parseNMEA(gpsBuffer);
      gpsBuffer = "";
    } else {
      if (gpsBuffer.length() < 120) gpsBuffer += c;
    }
  }

  // ---- Telemetry every 2 s (non-blocking) ----
  if (millis() - lastPrintTime > 2000) {
    lastPrintTime = millis();
    Serial.println("\n--- VISIONGUARD TELEMETRY ---");
    if (mpuConnected) {
      float ax, ay, az;
      if (getAccelData(ax, ay, az)) {
        float mag = sqrt(ax * ax + ay * ay + az * az);
        Serial.printf("ACCEL [m/s^2]: X=%.2f Y=%.2f Z=%.2f | Mag=%.2f\n", ax, ay, az, mag);
      } else {
        Serial.println("ACCEL: read failed (I2C busy?)");
      }
    } else {
      Serial.println("ACCEL: Not Connected");
    }
    Serial.print("GPS: ");
    Serial.print(hasGpsFix ? "(FIX) " : "(no fix - check sky view/TX/RX) ");
    Serial.println(lastKnownGPS);
    Serial.print("WiFi: ");
    Serial.print(wifiConnected ? WiFi.localIP().toString() : "OFFLINE");
    Serial.print(" | BLE(app): ");
    Serial.print(bleNow ? "CONNECTED" : "advertising");
    Serial.print(" | PAD: ");
    Serial.println(lastPadState);
    Serial.println("----------------------------");
  }

  // ---- Crash detection: filtered (gravity-aware) + debounced ----
  // At rest magnitude ~= 9.8. Require a SPIKE well above rest AND two
  // consecutive over-threshold reads to reject pothole/brake noise.
  if (mpuConnected && (millis() - lastCrashTime > 15000)) {
    static uint8_t overCount = 0;
    float ax, ay, az;
    if (getAccelData(ax, ay, az)) {
      float mag = sqrt(ax * ax + ay * ay + az * az);
      if (mag > accidentThreshold) {
        if (++overCount >= 2) {
          overCount = 0;
          lastCrashTime = millis();
          stopMotors();
          Serial.printf("!!! CRASH DETECTED (mag=%.1f) !!!\n", mag);
          sendEmergencyAlert("Collision", lastKnownGPS);
        }
      } else {
        overCount = 0;
      }
    }
  }

  // WiFi reconnect (polite, non-blocking): retry at most every 10 s so the
  // reconnect scan does not stomp an active BLE link.
#if USE_WIFI
  static unsigned long lastWifiRetry = 0;
  if (!wifiConnected && millis() - lastWifiRetry > 10000) {
    lastWifiRetry = millis();
    if (WiFi.status() == WL_CONNECTED) {
      wifiConnected = true;
      Serial.print("[WiFi] Reconnected @ ");
      Serial.println(WiFi.localIP());
    }
  } else if (wifiConnected && WiFi.status() != WL_CONNECTED) {
    wifiConnected = false;
    Serial.println("[WiFi] Link lost - BLE control continues.");
  }
#endif

  delay(1);  // yield to BLE/WiFi tasks; NEVER increase (BLE starves)
}
