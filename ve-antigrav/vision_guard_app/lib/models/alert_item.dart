class AlertItem {
  final String id;
  final String vehicleId;
  final String type; // drowsiness, distraction, crash, test, emergency_dispatch
  final String severity; // CRITICAL, HIGH, MEDIUM, LOW
  final String message;
  final String? location;
  final double? lat;
  final double? lng;
  final DateTime timestamp;
  bool acknowledged;

  AlertItem({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.severity,
    required this.message,
    this.location,
    this.lat,
    this.lng,
    required this.timestamp,
    this.acknowledged = false,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json, {String vehicleId = "VG-001"}) {
    final alertData = json['alert'] ?? json;
    final typeStr = (alertData['type'] ?? 'drowsiness').toString();
    final severityStr = (alertData['severity'] ?? 'HIGH').toString();
    final locationStr = alertData['location']?.toString();

    double? parsedLat;
    double? parsedLng;
    if (locationStr != null && locationStr.contains(',')) {
      final parts = locationStr.split(',');
      if (parts.length >= 2) {
        parsedLat = double.tryParse(parts[0].trim());
        parsedLng = double.tryParse(parts[1].trim());
      }
    }

    String messageText = "Driver alert detected";
    if (typeStr == 'drowsiness') {
      messageText = "DROWSINESS DETECTED - SEVERE DRIVER INATTENTION";
    } else if (typeStr == 'distraction') {
      messageText = "DRIVER DISTRACTED - LOOKING AWAY FROM ROAD";
    } else if (typeStr == 'crash') {
      messageText = "CRITICAL COLLISION DETECTED - WHATSAPP ALERT DISPATCHED";
    } else if (typeStr == 'test_alert' || typeStr == 'test') {
      messageText = "SYSTEM TEST ALERT - ALL SYSTEMS OPERATIONAL";
    }

    return AlertItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vehicleId: vehicleId,
      type: typeStr,
      severity: severityStr,
      message: messageText,
      location: locationStr,
      lat: parsedLat,
      lng: parsedLng,
      timestamp: DateTime.now(),
    );
  }
}
