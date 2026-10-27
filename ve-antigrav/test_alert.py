import requests
import time

DASHBOARD_URL = "http://localhost:3000/api/alerts"
SECRET_TOKEN = "secret_token_123"

def test_send_alert():
    payload = {
        "token": SECRET_TOKEN,
        "type": "test_alert",
        "severity": "low",
        "timestamp": time.time()
    }
    try:
        print(f"Sending POST to {DASHBOARD_URL}...")
        response = requests.post(DASHBOARD_URL, json=payload, timeout=5)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_send_alert()
