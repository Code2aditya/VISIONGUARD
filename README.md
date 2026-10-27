# 🛡️ VisionGuard – Autonomous AI Driver Safety & Cyber-Physical Telematics System

<div align="center">

[![Next.js](https://img.shields.io/badge/Next.js-16.1.7-black?style=for-the-badge&logo=next.js)](https://nextjs.org/)
[![React](https://img.shields.io/badge/React-19.2.3-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev/)
[![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![OpenCV](https://img.shields.io/badge/OpenCV-4.x-5C3EE8?style=for-the-badge&logo=opencv&logoColor=white)](https://opencv.org/)
[![ESP32](https://img.shields.io/badge/Hardware-ESP32%20SoC-E7352C?style=for-the-badge&logo=espressif&logoColor=white)](https://www.espressif.com/)
[![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.style?style=for-the-badge)](LICENSE)

**An intelligent end-to-end edge AI and IoT ecosystem that monitors driver alertness in real-time, actively halts the vehicle upon micro-sleep detection, detects physical collisions with 6-axis IMU sensors, and dispatches automated WhatsApp & SMS SOS alerts with live GPS telemetry.**

[🚀 Live Web Dashboard](https://vg-web-dashboard-y1fz.vercel.app) • [📖 Architecture](#-system-architecture) • [⚡ Quickstart](#-step-by-step-quickstart) • [🔌 Hardware Pinouts](#-hardware-bill-of-materials--pinout) • [🧪 Test Commands](#-testing--simulation)

---

</div>

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
│   │   └── esp32_firmware.ino        # Full Arduino sketch (BLE, WiFi, GPS, GSM, MPU, PWM)
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

## ⚡ Step-by-Step Quickstart

### 1. Edge Computer Vision (Laptop / In-Cabin PC)

```bash
# 1. Navigate to laptop vision directory
cd ve-antigrav/laptop_vision

# 2. Create and activate a Python virtual environment
python -m venv venv
# On Windows:
venv\Scripts\activate
# On Linux/macOS:
source venv/bin/activate

# 3. Install core dependencies
pip install opencv-python dlib numpy scipy imutils requests

# 4. Verify facial landmark model exists (download if missing)
# Download link: http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2
# Extract shape_predictor_68_face_landmarks.dat into laptop_vision/

# 5. Launch driver monitor
python vision_integration.py
```

> **Note:** Edit `DASHBOARD_URL` and `ESP32_CONTROL_URL` inside `vision_integration.py` to point to your deployed dashboard URL and local ESP32 IP address.

---

### 2. Cloud Web Dashboard (Next.js 16)

```bash
# 1. Navigate to web dashboard directory
cd ve-antigrav/web_dashboard

# 2. Install dependencies
npm install

# 3. Configure environment variables (.env.local)
cp .env.example .env.local
```

Populate `.env.local` with your credentials:
```ini
# WhatsApp Provider 1: CircuitDigest Cloud (Primary)
CIRCUITDIGEST_API_KEY=your_circuitdigest_api_key

# WhatsApp Provider 2: Twilio Fallback
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_FROM_NUMBER=+18128044497

# Emergency Target Recipient (Admin / Family)
EMERGENCY_TARGET_NUMBER=+91XXXXXXXXXX

# Internal API Bearer Token
DASHBOARD_API_TOKEN=secret_token_123
```

```bash
# 4. Run development server
npm run dev
```
Open **[http://localhost:3000/dashboard](http://localhost:3000/dashboard)** in your browser.

---

### 3. ESP32 Firmware Flashing

1. Open **Arduino IDE** (version 2.x or 1.8.x).
2. Install the **ESP32 Board Package** via Boards Manager: `esp32 by Espressif Systems`.
3. Install required libraries via Library Manager:
   - `DabbleESP32` by STEMpedia (v1.6.1 or Core 3.x community patch)
   - `Adafruit MPU6050` & `Adafruit Unified Sensor`
4. Open [`ve-antigrav/esp32_firmware/esp32_firmware.ino`](ve-antigrav/esp32_firmware/esp32_firmware.ino).
5. Update your local WiFi credentials:
   ```cpp
   const char* ssid = "YOUR_WIFI_HOTSPOT";
   const char* password = "YOUR_WIFI_PASSWORD";
   const char* dashboardServer = "https://your-dashboard.vercel.app";
   ```
6. Select Board **"ESP32 Dev Module"**, connect via USB, and click **Upload**.
7. Open **Serial Monitor** at **115200 baud** to verify sensor initialization, WiFi link, and BLE advertising.

---

### 4. Mobile App (Flutter)

```bash
cd ve-antigrav/vision_guard_app

# Fetch Flutter dependencies
flutter pub get

# Run on connected Android / iOS device or emulator
flutter run
```

---

## 🧪 Testing & Simulation

### Instant Crash & Emergency Dispatch Test
You can test the end-to-end WhatsApp and dashboard emergency pipeline without physically crashing the vehicle using PowerShell or cURL:

#### Via PowerShell:
```powershell
Invoke-RestMethod -Uri "https://vg-web-dashboard-y1fz.vercel.app/api/emergency" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"type":"simulated_crash","location":"28.7041,77.1025"}'
```

#### Via cURL:
```bash
curl -X POST https://vg-web-dashboard-y1fz.vercel.app/api/emergency \
  -H "Content-Type: application/json" \
  -d '{"type":"high_g_force_collision","location":"28.7041,77.1025"}'
```

#### Via Python CLI Script:
```bash
python ve-antigrav/test_alert.py
```

#### Via Serial Monitor:
Type `T` in the Arduino IDE Serial Monitor (115200 baud) to trigger a manual end-to-end WhatsApp crash dispatch straight from the ESP32!

---

## 📊 Detection Logic & Mathematical Formulations

### 1. Eye Aspect Ratio (EAR)
The Eye Aspect Ratio quantifies eye openness by computing Euclidean distances between vertical eyelid landmarks normalized by horizontal eye width:

$$\text{EAR} = \frac{||p_2 - p_6|| + ||p_3 - p_5||}{2 \cdot ||p_1 - p_4||}$$

- **Normal Open Eyes:** $\text{EAR} \approx 0.30 - 0.38$
- **Blink / Closed Eyes:** $\text{EAR} < 0.25$
- **Drowsiness Trigger:** $\text{EAR} < 0.25$ persisting continuously for $\ge 20$ frames.

### 2. Crash Impact Acceleration Vector
To eliminate false positives from static gravity ($1g \approx 9.8\text{ m/s}^2$), the system evaluates the resultant magnitude vector:

$$a_{\text{magnitude}} = \sqrt{a_x^2 + a_y^2 + a_z^2}$$

A severe impact is verified when $a_{\text{magnitude}} \ge 15.0\text{ m/s}^2$ with consecutive debounce samples.

---

## 🏆 Hackathon Innovation Highlights

1. **Closed-Loop Cyber-Physical Defense:** Most vision systems stop at sounding an alarm. VisionGuard takes immediate mechanical action by cutting motor torque over LAN to stop the vehicle from driving off the road.
2. **Dual-Network Redundancy:** Combines Internet of Things (WiFi + Cloud Webhooks) with Cellular Telephony (SIM800L GSM SMS) so that remote rural areas without data connectivity can still dispatch emergency SOS coordinates.
3. **Hardware-Software Coexistence:** Custom engineered ESP32 firmware running WiFi station mode, Bluetooth Low Energy (BLE 4.2), dual hardware serial UARTs, and high-frequency I2C on a single low-cost dual-core SoC without radio starvation.
4. **Zero-Friction Emergency Response:** WhatsApp emergency dispatches include instantaneous one-tap Google Maps coordinates, allowing first responders and family members to locate the vehicle in seconds.

---

## 👥 Team VisionGuard

*Developed with ❤️ for road safety and life preservation.*

- **AI & Computer Vision Engineering:** Facial landmark detection, EAR optimization, autonomous brake control.
- **Embedded IoT & Firmware Systems:** ESP32 RTOS, BLE/WiFi coexistence, IMU crash filtering, GPS/GSM drivers.
- **Full-Stack & Cloud Architecture:** Next.js 16 real-time dashboard, REST telematics APIs, Twilio & CircuitDigest integration.
- **Mobile Development:** Cross-platform Flutter glassmorphic telematics companion application.

---

## 📄 License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.
#   V I S I O N G U A R D  
 #   V I S I O N G U A R D  
 