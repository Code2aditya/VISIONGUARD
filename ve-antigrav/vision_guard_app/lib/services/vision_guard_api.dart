import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert_item.dart';

class VisionGuardApiService {
  // Primary production Next.js API URL
  static String baseUrl = "https://vg-web-dashboard-y1fz.vercel.app";
  static String secretToken = "secret_token_123";

  // List of fallback endpoint candidates for local dev & emulator compatibility
  static final List<String> _candidateUrls = [
    "https://vg-web-dashboard-y1fz.vercel.app",
    "http://10.0.2.2:3000",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
  ];

  /// Poll server for latest Vision alerts across candidate URLs
  static Future<AlertItem?> fetchLatestAlert(String vehicleId) async {
    for (String targetUrl in _candidateUrls) {
      try {
        final response = await http
            .get(Uri.parse('$targetUrl/api/alerts'))
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data != null && data['alert'] != null) {
            return AlertItem.fromJson(data, vehicleId: vehicleId);
          }
        }
      } catch (e) {
        // Fallthrough to next candidate URL
      }
    }
    return null;
  }

  /// Send emergency crash alert to backend (triggers WhatsApp notification)
  static Future<bool> triggerEmergencyAlert({
    required String type,
    required String location,
  }) async {
    for (String targetUrl in _candidateUrls) {
      try {
        final response = await http
            .post(
              Uri.parse('$targetUrl/api/emergency'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'type': type,
                'location': location,
              }),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) return true;
        }
      } catch (e) {
        // Fallthrough
      }
    }
    return false;
  }

  /// Send RC control command to ESP32 via Next.js proxy endpoint
  static Future<bool> sendEsp32Command({
    required String command,
    required String espIp,
  }) async {
    for (String targetUrl in _candidateUrls) {
      try {
        final response = await http
            .post(
              Uri.parse('$targetUrl/api/proxy'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'cmd': command,
                'ip': espIp,
              }),
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) return true;
        }
      } catch (e) {
        // Fallthrough
      }
    }
    return false;
  }
}
