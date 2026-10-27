import cv2
import numpy as np
import dlib
from scipy.spatial import distance
from imutils import face_utils
import winsound
import time
import os
import requests

print("ULTIMATE PC DROWSINESS DETECTOR + VISIONGUARD")
print("Real Eye Aspect Ratio + Face Tracking")
print("Press Q to quit")

# --- Configuration ---
DASHBOARD_URL = "https://vg-web-dashboard-y1fz.vercel.app/api/alerts"   # Deployed Dashboard API
ESP32_CONTROL_URL = "http://REPLACE_WITH_ESP32_IP/control" # <--- Update this with current ESP32 IP
SECRET_TOKEN = "secret_token_123"

def send_alert_to_dashboard(alert_type, severity):
    """
    Sends the detection alert (Drowsiness/Distraction) to your centralized web dashboard.
    """
    payload = {
        "token": SECRET_TOKEN,
        "type": alert_type,  
        "severity": severity, 
        "timestamp": time.time()
    }
    try:
        # Timeout is short to avoid lagging the video feed
        response = requests.post(DASHBOARD_URL, json=payload, timeout=1) 
        if response.status_code == 200:
             print(f"[Dashboard] Alert sent successfully: {alert_type}") 
    except Exception as e:
        print(f"[Dashboard Error]: {e}")

def trigger_esp32_action(action):
    """
    Sends a request directly to the ESP32 to perform an action (like stopping the cart).
    """
    url = f"{ESP32_CONTROL_URL}?cmd={action}"
    try:
        response = requests.get(url, timeout=3)
        if response.status_code == 200:
             print(f"[ESP32] Command '{action}' executed successfully.")
    except Exception as e:
        print(f"[ESP32 Error] Could not connect to ESP32: {e}")

# Check if dlib model exists (download from http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2)
model_path = "shape_predictor_68_face_landmarks.dat"
if not os.path.exists(model_path):
    print("MISSING: shape_predictor_68_face_landmarks.dat")
    print("Download: http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2")
    print("Please download and extract it in this folder to run.")
    exit()

cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

detect = dlib.get_frontal_face_detector()
predict = dlib.shape_predictor(model_path)

(lStart, lEnd) = face_utils.FACIAL_LANDMARKS_68_IDXS["left_eye"]
(rStart, rEnd) = face_utils.FACIAL_LANDMARKS_68_IDXS["right_eye"]

EYE_AR_THRESH = 0.25
EYE_AR_CONSEC_FRAMES = 20
flag = 0
no_face_count = 0
status = "ACTIVE"
status_color = (0, 255, 0)
last_alert_time = 0 # Throttle alerts to dashboard to prevent network spam

def eye_aspect_ratio(eye):
    A = distance.euclidean(eye[1], eye[5])
    B = distance.euclidean(eye[2], eye[4])
    C = distance.euclidean(eye[0], eye[3])
    ear = (A + B) / (2.0 * C)
    return ear

print("Camera ready! Close eyes to test!")

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    frame = cv2.resize(frame, (640, 480))
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    
    faces = detect(gray, 0)
    
    # Track current state for this frame for VisionGuard network pinging
    current_state = "ACTIVE"
    
    for face in faces:
        shape = predict(gray, face)
        shape = face_utils.shape_to_np(shape)
        
        # Face box
        x1 = face.left()
        y1 = face.top()
        x2 = face.right()
        y2 = face.bottom()
        cv2.rectangle(frame, (x1, y1), (x2, y2), (255, 0, 0), 2)
        
        # Eyes
        leftEye = shape[lStart:lEnd]
        rightEye = shape[rStart:rEnd]
        
        leftEAR = eye_aspect_ratio(leftEye)
        rightEAR = eye_aspect_ratio(rightEye)
        ear = (leftEAR + rightEAR) / 2.0
        
        leftEyeHull = cv2.convexHull(leftEye)
        rightEyeHull = cv2.convexHull(rightEye)
        cv2.drawContours(frame, [leftEyeHull], -1, (0, 255, 0), 2)
        cv2.drawContours(frame, [rightEyeHull], -1, (0, 255, 0), 2)
        
        cv2.putText(frame, f"EAR: {ear:.2f}", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        
        if ear < EYE_AR_THRESH:
            flag += 1
            if flag >= EYE_AR_CONSEC_FRAMES:
                status = "SLEEPING - WAKE UP!"
                current_state = "SLEEPING"
                status_color = (0, 0, 255)
                winsound.Beep(1000, 800)
                print("SLEEP DETECTED!")
            else:
                status = "DROWSY"
                current_state = "DROWSY"
                status_color = (0, 165, 255)
        else:
            flag = 0
            status = "ACTIVE"
            status_color = (0, 255, 0)
    
    if len(faces) == 0:
        no_face_count += 1
        if no_face_count > 45:
            status = "LOOKING AWAY!"
            current_state = "DISTRACTED"
            status_color = (0, 255, 255)
            winsound.Beep(800, 500)
            print("DISTRACTION!")
            no_face_count = 0
        else:
            status = "NO FACE"
            status_color = (0, 165, 255)
    
    # --- VisionGuard Integration Logic ---
    # Send alerts to dashboard/ESP32 if in critical state
    # Throttle sending to avoid spamming the network (e.g., max 1 alert per 3 seconds)
    if current_state in ["SLEEPING", "DISTRACTED"] and (time.time() - last_alert_time) > 3.0:
        if current_state == "SLEEPING":
            send_alert_to_dashboard("drowsiness", "high")
            trigger_esp32_action("stop") # Halt RC Car to prevent accident
        elif current_state == "DISTRACTED":
            send_alert_to_dashboard("distraction", "medium")
        last_alert_time = time.time()

    cv2.putText(frame, status, (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 1, status_color, 3)
    cv2.putText(frame, f"Frames: {flag}", (10, 110), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255,255,255), 2)
    cv2.putText(frame, "Q=Quit", (10, frame.shape[0]-20), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255,255,255), 2)
    
    cv2.imshow("Ultimate Driver Monitor", frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
print("Monitor stopped")