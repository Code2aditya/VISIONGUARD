# 🚗 VisionGuard – AI Driver Monitoring System

## 📌 Overview
VisionGuard is an AI-powered driver monitoring system designed to enhance road safety by detecting driver drowsiness, distraction, and unsafe behavior in real-time. The system uses computer vision and machine learning techniques to analyze facial features and trigger alerts to prevent accidents.

## 🎯 Features
- 1.👁️ Drowsiness Detection (eye closure, blinking rate)
- 2.😴 Fatigue Monitoring (long eye closure, head tilt)
- 3.📱 Distraction Detection (looking away, phone usage)
- 4.🚨 Real-time Alerts (buzzer / notification system)
- 5.🌙 Low-light Adaptability (works in dim conditions)
- 6.📊 Performance Metrics (precision, recall optimization)

## 🛠️ Tech Stack
- Programming Language: Python
- Libraries & Frameworks:
    - OpenCV (Computer Vision)
    - Dlib / Mediapipe (Face & landmark detection)
    - NumPy
- Hardware (Optional):
    - ESP32 (for alert system)
    - Webcam
    - Buzzer / LEDs

## ⚙️ How It Works
- 1.Capture live video feed using a camera.
- 2.Detect face and facial landmarks.
- 3.Track eye aspect ratio (EAR) and head position.
- 4.Analyze:
   - Eye closure duration;
   - Blink frequency;
   - Head movement;
- 5.Trigger alert if thresholds exceed safe limits.
