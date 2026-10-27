# 🛡️ VisionGuard – Autonomous AI Driver Safety & Cyber-Physical Telematics System

## 📌 Executive Summary

Road traffic crashes claim over **1.35 million lives** globally every year, with driver fatigue and distraction accounting for more than **20–30%** of severe vehicular collisions (WHO). Traditional dashcams and passive monitoring systems merely record accidents after the damage is done without preventing them.

**VisionGuard** transforms driver monitoring into an **active intervention platform**:
1. **Edge Computer Vision:** Continuously tracks 68 facial landmarks to evaluate Eye Aspect Ratio (EAR) and head orientation, detecting micro-sleeps and distraction in real-time.
2. **Autonomous Physical Intervention:** When extreme drowsiness or sleep is confirmed, the vision system issues an instantaneous zero-latency local HTTP override to the ESP32 vehicle chassis to **halt the motors**, preventing fatal collisions before they occur.
3. **Crash & G-Force Telemetry:** An onboard MPU-6050 6-axis accelerometer/gyroscope filters transient vibrations and detects impact thresholds (> 15 m/s²).
4. **Dual Emergency Dispatch:** Immediately fires cloud emergency webhooks that deliver rich **WhatsApp emergency alerts (with Google Maps pins)** via CircuitDigest Cloud / Twilio API, backed up by **offline SIM800L GSM SMS**.
5. **Real-time Mission Control:** A centralized Next.js 16 Web Dashboard + Flutter companion mobile app delivers live telemetry, vehicle tracking on Leaflet maps, and remote tele-operation overrides.

---

## 🌟 Key Features

| Feature | Technology | Description |
| :--- | :--- | :--- |
| **👁️ Real-time Drowsiness Detection** | OpenCV + Dlib 68-pt Predictor | Calculates Eye Aspect Ratio (EAR). Triggers progressive audio-visual warnings upon EAR < 0.25. |
| **📱 Distraction & Gaze Tracking** | Face Landmark Vectorization | Detects head turns away from the windshield or driver absence for > 45 frames. |
| **🛑 Autonomous Vehicle Braking** | Direct LAN HTTP / REST | Zero-latency emergency command sent straight from the edge vision pipeline to ESP32 motor controller. |
| **💥 Impact & Crash Sensing** | MPU-6050 6-Axis IMU | High-frequency acceleration magnitude filtering with baseline gravity offset calibration. |
| **📍 High-Precision GPS Telemetry** | NEO-6M GPS Engine | Real-time NMEA string parser broadcasting precise latitude, longitude, and map coordinates. |
| **💬 Multi-Tier Emergency SOS** | CircuitDigest + Twilio + SIM800L | Primary WhatsApp alert template with live Google Maps URL; offline cellular fallback via GSM AT commands. |
| **🕹️ Tri-Mode Vehicle Control** | BLE + Web + Serial CLI | Controllable via Dabble BLE smartphone gamepad, web dashboard tele-operation interface, or USB serial CLI. |
| **🌐 Next.js 16 Mission Control** | React 19 + Tailwind CSS + Leaflet | Modern real-time web portal showing live telemetry, map tracking, vision feed, and fleet diagnostics. |
| **📱 Glassmorphic Mobile App** | Flutter + Dart + Material 3 | Driver companion app featuring vehicle selection, fleet status cards, and telemetry cards. |

---

## 🏗️ System Architecture

```mermaid
flowchart TD
    subgraph Cabin["In-Cabin Edge Monitoring"]
        CAM["Webcam / Dashcam"] -->|Live 30 FPS Video| CV["Python Vision Engine\n(OpenCV + Dlib 68 Landmarks)"]
        CV -->|Calculates EAR| EAR{"EAR < 0.25\nfor 20+ Frames?"}
        CV -->|Gaze Tracking| DIST{"Driver Absent /\nLooking Away?"}
        EAR -->|Yes: Sleep Detected| ALARM["Local Audio Buzzer\n(Winsound / Speaker)"]
        DIST -->|Yes: Distracted| ALARM
    end

    subgraph Hardware["Vehicle Chassis (ESP32 IoT Hub)"]
        ESP["ESP32 Dual-Core MCU"]
        MPU["MPU-6050 6-Axis IMU"] -->|I2C / Accel Vector > 15 m/s²| ESP
        GPS["NEO-6M GPS Module"] -->|UART2 NMEA Fix| ESP
        DABBLE["Dabble Mobile BLE App"] -->|BLE 4.2 GamePad| ESP
        ESP -->|PWM Channels 4 & 5| L298N["L298N Motor Driver"]
        L298N -->|H-Bridge Drive| MOTORS["Chassis DC Motors"]
        ESP -->|UART1 AT Commands| SIM["SIM800L GSM Module"]
    end

    subgraph Cloud["Cloud Infrastructure & APIs"]
        DASH["Next.js 16 Web Dashboard\n(Vercel Deployed)"]
        WHATSAPP["CircuitDigest / Twilio\nWhatsApp Gateway"]
        EMERGENCY_CONTACT["Emergency Contact / Fleet Admin\n(+91-XXXXXXXXXX)"]
    end

    subgraph Mobile["Driver Mobile Companion"]
        FLUTTER["Flutter Mobile App\n(Glassmorphic Dark UI)"]
    end

    %% Autonomous Intervention
    EAR -->|Autonomous Brake Command /control?cmd=stop| ESP
    CV -->|POST /api/alerts (Drowsiness/Distraction)| DASH

    %% Hardware to Cloud & Fallback
    ESP -->|WiFi HTTP POST /api/emergency\n(Crash + GPS Coordinates)| DASH
    ESP -.->|Offline GSM SMS Fallback| EMERGENCY_CONTACT
    DASH -->|REST API Dispatch| WHATSAPP
    WHATSAPP -->|WhatsApp SOS with Maps Link| EMERGENCY_CONTACT

    %% Dashboard and Mobile
    DASH <-->|Live Telemetry & Alerts| FLUTTER
    DASH -->|Remote Tele-Operation /api/proxy| ESP
```

---

## 📁 Repository Structure

```
vg-web_hosted/
│
├── ve-antigrav/
│   ├── esp32_firmware/               # ESP32 Dual-Radio Core Firmware
│   │   └── esp32_firmware.ino        # Complete Arduino sketch (BLE, WiFi, GPS, GSM, MPU, PWM)
│   │
│   ├── laptop_vision/                # Edge Computer Vision AI Pipeline
│   │   ├── vision_integration.py     # Real-time EAR + Head Pose + Auto-brake script
│   │   ├── shape_predictor_68_face_landmarks.dat      # Dlib 68-point facial model
│   │   └── shape_predictor_68_face_landmarks.dat.bz2  # Compressed model archive
│   │
│   ├── web_dashboard/                # Next.js 16 Fleet Mission Control
│   │   ├── src/app/
│   │   │   ├── api/alerts/           # Real-time alert polling & storage endpoint
│   │   │   ├── api/emergency/        # WhatsApp dispatch (CircuitDigest & Twilio)
│   │   │   ├── api/proxy/            # Tele-operation relay to ESP32 local server
│   │   │   ├── dashboard/page.tsx    # Live map, alert feed, vehicle controls
│   │   │   └── page.tsx              # Landing & vehicle authentication portal
│   │   ├── src/components/           # Leaflet Map & Vision Feed components
│   │   ├── package.json              # Web dependencies (Next 16, React 19, Lucide, Tailwind)
│   │   ├── .env.example              # Environment credentials template
│   │   └── .env.local                # Local API keys & webhook secrets
│   │
│   ├── vision_guard_app/             # Flutter Mobile Companion App
│   │   ├── lib/screens/              # Vehicle selector & telemetry dashboards
│   │   ├── lib/theme/glass_theme.dart# Ultra-modern glassmorphic UI system
│   │   └── pubspec.yaml              # Flutter dependencies (Google Fonts, etc.)
│   │
│   └── test_alert.py                 # CLI test script to trigger synthetic alerts
│
├── ESP32_INTEGRATION.md              # Detailed hardware schematics & circuit wiring
├── postSMS.txt                       # Sample PowerShell emergency API invocation
└── README.md                         # Project documentation
```

---

## 🔌 Hardware Bill of Materials & Pinout

### Components Required

| Item | Model | Function |
| :--- | :--- | :--- |
| **Microcontroller** | ESP32 DevKit V1 (30 or 38 pin) | Dual Core 240MHz, WiFi 802.11 b/g/n + BLE 4.2 |
| **Motion Sensor** | MPU-6050 Module | 3-axis accelerometer + 3-axis gyroscope (I2C) |
| **Satellite Positioning** | NEO-6M GPS Engine | Fast TTFF satellite receiver with ceramic antenna |
| **Cellular Transceiver**| SIM800L GPRS/GSM Module | Quad-band 2G cellular SMS transmitter |
| **Motor Driver** | L298N Dual H-Bridge | Handles 7–12V DC motor control with PWM speed channels |
| **Vehicle Chassis** | 2WD / 4WD Smart Robot Kit | 3–6V DC geared motors + wheels + caster |
| **Power Supply** | 7.4V Li-Po / 18650 Battery Pack | Separate high-current motor feed + regulated 5V MCU rail |

### ESP32 Pin Allocation Map

```
========================================================================
ESP32 Pin     Connected Device     Signal / Interface
========================================================================
GPIO 21       MPU-6050             I2C SDA (Data Line)
GPIO 22       MPU-6050             I2C SCL (Clock Line)
------------------------------------------------------------------------
GPIO 16 (RX2) NEO-6M GPS           GPS TX (Serial NMEA In)
GPIO 17 (TX2) NEO-6M GPS           GPS RX (Serial Config Out)
------------------------------------------------------------------------
GPIO 4  (RX1) SIM800L GSM          GSM TX (AT Response In)
GPIO 5  (TX1) SIM800L GSM          GSM RX (AT Command Out)
------------------------------------------------------------------------
GPIO 14       L298N Motor Driver   ENA (Left Motor PWM Channel 4)
GPIO 27       L298N Motor Driver   IN1 (Left Motor Direction A)
GPIO 26       L298N Motor Driver   IN2 (Left Motor Direction B)
GPIO 32       L298N Motor Driver   ENB (Right Motor PWM Channel 5)
GPIO 25       L298N Motor Driver   IN3 (Right Motor Direction A)
GPIO 33       L298N Motor Driver   IN4 (Right Motor Direction B)
------------------------------------------------------------------------
GPIO 2        Onboard LED          Status & BLE / WiFi Indicator
========================================================================
```

---

## 👥 Team VisionGuard

*Developed with ❤️ for road safety and life preservation.*

- **AI & Computer Vision Engineering:** Facial landmark detection, EAR optimization, autonomous brake control.
- **Embedded IoT & Firmware Systems:** ESP32 RTOS, BLE/WiFi coexistence, IMU crash filtering, GPS/GSM drivers.
- **Full-Stack & Cloud Architecture:** Next.js 16 real-time dashboard, REST telematics APIs, Twilio & CircuitDigest integration.
- **Mobile Development:** Cross-platform Flutter glassmorphic telematics companion application.