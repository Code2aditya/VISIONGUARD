# Driver Safety Monitoring System - Hardware Integration Guide

## Overview

This document provides complete code and instructions for integrating an ESP32-based hardware device with the Driver Safety Monitoring System. The device includes:

- **Accelerometer (MPU6050)** - For accident/crash detection
- **GPS Module (NEO-6M)** - For location tracking
- **GSM Module (SIM800L)** - For SMS notifications

## Hardware Requirements

| Component | Model | Description |
|-----------|-------|-------------|
| Microcontroller | ESP32 DevKit V1 | Main controller with WiFi |
| Accelerometer | MPU6050 | 3-axis accelerometer + gyroscope |
| GPS Module | NEO-6M | GPS receiver |
| GSM Module | SIM800L | Cellular communication |
| Power | 5V 2A Power Supply | Or LiPo battery with charging circuit |

## Wiring Diagram

```
ESP32 Pin Connections:
======================

MPU6050 (Accelerometer):
- VCC  -> 3.3V
- GND  -> GND
- SCL  -> GPIO 22 (I2C SCL)
- SDA  -> GPIO 21 (I2C SDA)

NEO-6M (GPS):
- VCC  -> 3.3V
- GND  -> GND
- TX   -> GPIO 16 (RX2)
- RX   -> GPIO 17 (TX2)

SIM800L (GSM):
- VCC  -> 4.0V (use buck converter if needed)
- GND  -> GND
- TX   -> GPIO 25
- RX   -> GPIO 26
- RST  -> GPIO 27
```

## ESP32 Arduino Code

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <TinyGPS++.h>
#include <MPU6050_tockn.h>

// ==================== Configuration ====================
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Server Configuration
const char* SERVER_URL = "http://YOUR_SERVER_IP:3000";

// Device ID (unique identifier for this device)
const String DEVICE_ID = "ESP32-001";

// Impact Detection Threshold (in g-force)
const float IMPACT_THRESHOLD = 3.0;

// GPS Update Interval (milliseconds)
const unsigned long GPS_UPDATE_INTERVAL = 5000;

// Accelerometer Read Interval (milliseconds)
const unsigned long ACCEL_READ_INTERVAL = 100;

// ==================== Pin Definitions ====================
#define GPS_RX_PIN 16
#define GPS_TX_PIN 17
#define GSM_TX_PIN 25
#define GSM_RX_PIN 26
#define GSM_RST_PIN 27

// ==================== Objects ====================
MPU6050 mpu6050(Wire);
TinyGPSPlus gps;
HardwareSerial GPSSerial(2);  // UART2 for GPS
HardwareSerial GSMSerial(1);  // UART1 for GSM

// ==================== Variables ====================
unsigned long lastGpsUpdate = 0;
unsigned long lastAccelRead = 0;
float currentLat = 0.0;
float currentLng = 0.0;
bool hasGpsFix = false;
bool accidentDetected = false;

// ==================== Setup ====================
void setup() {
  Serial.begin(115200);
  
  // Initialize I2C for MPU6050
  Wire.begin();
  mpu6050.begin();
  mpu6050.calcGyroOffsets(true);
  
  // Initialize GPS Serial
  GPSSerial.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
  
  // Initialize GSM Serial
  GSMSerial.begin(9600, SERIAL_8N1, GSM_TX_PIN, GSM_RX_PIN);
  pinMode(GSM_RST_PIN, OUTPUT);
  
  // Initialize WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi!");
  
  // Initialize GSM Module
  initGSM();
  
  Serial.println("Driver Safety Device Initialized!");
}

// ==================== Main Loop ====================
void loop() {
  unsigned long currentTime = millis();
  
  // Read GPS data continuously
  while (GPSSerial.available() > 0) {
    if (gps.encode(GPSSerial.read())) {
      if (gps.location.isValid()) {
        currentLat = gps.location.lat();
        currentLng = gps.location.lng();
        hasGpsFix = true;
      }
    }
  }
  
  // Send GPS update periodically
  if (currentTime - lastGpsUpdate >= GPS_UPDATE_INTERVAL && hasGpsFix) {
    sendGpsData();
    lastGpsUpdate = currentTime;
  }
  
  // Read accelerometer data
  if (currentTime - lastAccelRead >= ACCEL_READ_INTERVAL) {
    mpu6050.update();
    float accelX = mpu6050.getAccX();
    float accelY = mpu6050.getAccY();
    float accelZ = mpu6050.getAccZ();
    
    // Calculate magnitude
    float magnitude = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
    
    // Check for impact
    if (magnitude > IMPACT_THRESHOLD) {
      handleAccident(accelX, accelY, accelZ, magnitude);
    }
    
    // Send accelerometer data (optional, for monitoring)
    if (magnitude > 2.0) {  // Significant movement
      sendAccelerometerData(accelX, accelY, accelZ, magnitude);
    }
    
    lastAccelRead = currentTime;
  }
}

// ==================== Functions ====================

void initGSM() {
  Serial.println("Initializing GSM...");
  
  // Reset GSM module
  digitalWrite(GSM_RST_PIN, LOW);
  delay(1000);
  digitalWrite(GSM_RST_PIN, HIGH);
  delay(5000);
  
  // Test GSM connection
  GSMSerial.println("AT");
  delay(1000);
  
  // Set SMS to text mode
  GSMSerial.println("AT+CMGF=1");
  delay(1000);
  
  Serial.println("GSM Initialized!");
}

void sendGpsData() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected!");
    return;
  }
  
  HTTPClient http;
  String url = String(SERVER_URL) + "/api/device/gps";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  StaticJsonDocument<256> doc;
  doc["deviceId"] = DEVICE_ID;
  doc["latitude"] = currentLat;
  doc["longitude"] = currentLng;
  doc["speed"] = gps.speed.kmph();
  doc["altitude"] = gps.altitude.meters();
  doc["heading"] = gps.course.deg();
  doc["accuracy"] = gps.hdop.value();
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  int httpResponseCode = http.POST(jsonString);
  
  if (httpResponseCode > 0) {
    Serial.printf("GPS data sent. Response: %d\n", httpResponseCode);
  } else {
    Serial.printf("Error sending GPS: %s\n", http.errorToString(httpResponseCode).c_str());
  }
  
  http.end();
}

void sendAccelerometerData(float x, float y, float z, float magnitude) {
  if (WiFi.status() != WL_CONNECTED) return;
  
  HTTPClient http;
  String url = String(SERVER_URL) + "/api/device/accelerometer";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  StaticJsonDocument<256> doc;
  doc["deviceId"] = DEVICE_ID;
  doc["x"] = x;
  doc["y"] = y;
  doc["z"] = z;
  doc["magnitude"] = magnitude;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  http.POST(jsonString);
  http.end();
}

void handleAccident(float x, float y, float z, float magnitude) {
  if (accidentDetected) return;  // Prevent multiple triggers
  
  accidentDetected = true;
  
  Serial.println("!!! ACCIDENT DETECTED !!!");
  Serial.printf("Impact magnitude: %.2fg\n", magnitude);
  
  // Send to server
  HTTPClient http;
  String url = String(SERVER_URL) + "/api/device/accident";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  StaticJsonDocument<512> doc;
  doc["deviceId"] = DEVICE_ID;
  doc["latitude"] = currentLat;
  doc["longitude"] = currentLng;
  
  JsonObject accel = doc.createNestedObject("acceleration");
  accel["x"] = x;
  accel["y"] = y;
  accel["z"] = z;
  accel["magnitude"] = magnitude;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  int httpResponseCode = http.POST(jsonString);
  
  if (httpResponseCode > 0) {
    Serial.println("Accident reported to server!");
  }
  
  http.end();
  
  // Send SMS directly via GSM module
  sendSMS("+1234567890", "ACCIDENT ALERT!\n\nLocation: " + 
           String(currentLat, 6) + ", " + String(currentLng, 6) + 
           "\n\nGoogle Maps: https://maps.google.com/?q=" + 
           String(currentLat, 6) + "," + String(currentLng, 6));
  
  // Reset after delay
  delay(30000);
  accidentDetected = false;
}

void sendSMS(String phoneNumber, String message) {
  Serial.println("Sending SMS to: " + phoneNumber);
  
  GSMSerial.println("AT+CMGS=\"" + phoneNumber + "\"");
  delay(1000);
  GSMSerial.print(message);
  delay(1000);
  GSMSerial.write(26);  // Ctrl+Z to send
  
  delay(5000);
  Serial.println("SMS sent!");
}

// ==================== Helper Functions ====================

void checkWiFiConnection() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Reconnecting to WiFi...");
    WiFi.reconnect();
    delay(5000);
  }
}
```

## Computer Vision Integration (Python)

The following Python script demonstrates how to integrate computer vision for drowsiness/distraction detection:

```python
import cv2
import dlib
import numpy as np
from scipy.spatial import distance
import requests
import time

# Configuration
SERVER_URL = "http://YOUR_SERVER_IP:3000"
DEVICE_ID = "ESP32-001"

# Drowsiness detection parameters
EYE_AR_THRESHOLD = 0.25
EYE_AR_CONSEC_FRAMES = 20  # 20 frames ~ 1 second at 20fps

# Distraction detection parameters  
HEAD_YAW_THRESHOLD = 30  # degrees

# Initialize dlib face detector and predictor
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")

# Eye landmarks indices
LEFT_EYE_INDICES = list(range(36, 42))
RIGHT_EYE_INDICES = list(range(42, 48))

# Variables
eye_closed_frames = 0
looking_away_start = None
last_alert_time = 0

def eye_aspect_ratio(eye):
    """Calculate Eye Aspect Ratio (EAR)"""
    vertical_1 = distance.euclidean(eye[1], eye[5])
    vertical_2 = distance.euclidean(eye[2], eye[4])
    horizontal = distance.euclidean(eye[0], eye[3])
    
    return (vertical_1 + vertical_2) / (2.0 * horizontal)

def get_head_pose(shape):
    """Estimate head pose using facial landmarks"""
    # 2D image points
    image_points = np.array([
        shape[30],  # Nose tip
        shape[8],   # Chin
        shape[36],  # Left eye left corner
        shape[45],  # Right eye right corner
        shape[48],  # Left mouth corner
        shape[54],  # Right mouth corner
    ], dtype="double")
    
    # 3D model points (simplified)
    model_points = np.array([
        (0.0, 0.0, 0.0),
        (0.0, -330.0, -65.0),
        (-225.0, 170.0, -135.0),
        (225.0, 170.0, -135.0),
        (-150.0, -150.0, -125.0),
        (150.0, -150.0, -125.0),
    ])
    
    # Camera matrix (approximation)
    size = frame.shape
    focal_length = size[1]
    center = (size[1] / 2, size[0] / 2)
    camera_matrix = np.array([
        [focal_length, 0, center[0]],
        [0, focal_length, center[1]],
        [0, 0, 1]
    ], dtype="double")
    
    # Solve for pose
    _, rotation_vector, _ = cv2.solvePnP(
        model_points, image_points, camera_matrix, None
    )
    
    # Convert to angles
    rmat, _ = cv2.Rodrigues(rotation_vector)
    angles, _, _, _, _, _ = cv2.RQDecomp3x3(rmat)
    
    return angles[1]  # Yaw angle

def send_vision_alert(alert_type, severity, data):
    """Send detection alert to server"""
    try:
        payload = {
            "deviceId": DEVICE_ID,
            **data
        }
        response = requests.post(
            f"{SERVER_URL}/api/vision/detect",
            json=payload,
            timeout=5
        )
        print(f"Alert sent: {response.status_code}")
    except Exception as e:
        print(f"Failed to send alert: {e}")

# Main loop
cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = detector(gray)
    
    for face in faces:
        shape = predictor(gray, face)
        shape = np.array([[p.x, p.y] for p in shape.parts()])
        
        # Calculate EAR for both eyes
        left_eye = shape[LEFT_EYE_INDICES]
        right_eye = shape[RIGHT_EYE_INDICES]
        
        left_ear = eye_aspect_ratio(left_eye)
        right_ear = eye_aspect_ratio(right_eye)
        avg_ear = (left_ear + right_ear) / 2.0
        
        # Get head pose
        head_yaw = get_head_pose(shape)
        
        # Check for drowsiness
        if avg_ear < EYE_AR_THRESHOLD:
            eye_closed_frames += 1
            
            if eye_closed_frames >= EYE_AR_CONSEC_FRAMES:
                # Drowsiness detected
                cv2.putText(frame, "DROWSINESS ALERT!", (10, 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                
                # Send alert (with cooldown)
                if time.time() - last_alert_time > 60:
                    send_vision_alert("DROWSINESS", "HIGH", {
                        "eyeAspectRatio": avg_ear,
                        "eyesClosedDuration": eye_closed_frames / 20.0
                    })
                    last_alert_time = time.time()
        else:
            eye_closed_frames = 0
        
        # Check for distraction
        if abs(head_yaw) > HEAD_YAW_THRESHOLD:
            if looking_away_start is None:
                looking_away_start = time.time()
            elif time.time() - looking_away_start > 5:
                # Distraction detected
                cv2.putText(frame, "DISTRACTION ALERT!", (10, 60),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 165, 255), 2)
                
                if time.time() - last_alert_time > 60:
                    send_vision_alert("DISTRACTION", "MEDIUM", {
                        "headYaw": head_yaw,
                        "lookingAwayDuration": time.time() - looking_away_start
                    })
                    last_alert_time = time.time()
        else:
            looking_away_start = None
        
        # Display metrics
        cv2.putText(frame, f"EAR: {avg_ear:.2f}", (10, frame.shape[0] - 40),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        cv2.putText(frame, f"Yaw: {head_yaw:.1f}°", (10, frame.shape[0] - 20),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
    
    cv2.imshow("Driver Monitor", frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

## API Endpoints Reference

### GPS Data
- **POST** `/api/device/gps`
  - Body: `{ deviceId, latitude, longitude, speed, altitude, heading, accuracy }`
  - Purpose: Receive GPS location updates from hardware

### Accelerometer Data
- **POST** `/api/device/accelerometer`
  - Body: `{ deviceId, x, y, z }`
  - Purpose: Receive accelerometer readings, auto-detect impacts

### Accident Report
- **POST** `/api/device/accident`
  - Body: `{ deviceId, latitude, longitude, acceleration: {x, y, z} }`
  - Purpose: Report accident with full data (triggers SMS)

### Vision Detection
- **POST** `/api/vision/detect`
  - Body: `{ deviceId, eyeAspectRatio, headYaw, headPitch, blinkRate, eyesClosedDuration, lookingAwayDuration }`
  - Purpose: Report drowsiness/distraction from CV system

### Alerts
- **GET** `/api/alerts` - Get all alerts
- **POST** `/api/alerts` - Create new alert
- **POST** `/api/alerts/[id]/acknowledge` - Acknowledge alert

### Emergency Contacts
- **GET** `/api/contacts` - Get all contacts
- **POST** `/api/contacts` - Add new contact
- **DELETE** `/api/contacts?id=xxx` - Remove contact

## SMS Configuration

To enable real SMS notifications, set these environment variables:

```env
SMS_ENABLED=true
SMS_GATEWAY_URL=https://api.africastalking.com/version1/messaging
SMS_API_KEY=your_api_key
SMS_USERNAME=your_username
SMS_SENDER_ID=DriverSafety
```

### Supported SMS Gateways:
1. **Africa's Talking** - Popular in Africa
2. **Twilio** - Global coverage
3. **Vonage** - Global coverage
4. **Custom Gateway** - Implement your own

## Troubleshooting

### GPS Not Getting Fix
- Ensure antenna is connected and has clear sky view
- Wait 2-5 minutes for cold start
- Check baud rate (default 9600)

### GSM Not Sending SMS
- Check SIM card is inserted and has credit
- Verify network registration with AT+CREG?
- Check voltage (SIM800L needs 3.4-4.4V)

### Accelerometer False Triggers
- Adjust IMPACT_THRESHOLD based on testing
- Add debounce logic to prevent rapid triggers
- Consider using moving average filter

### WiFi Connection Issues
- Check credentials
- Ensure strong signal strength
- Consider using static IP for server

## License

This project is provided as-is for educational purposes. Use at your own risk.
