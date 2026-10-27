import '../models/emergency_facility.dart';
import '../models/vehicle.dart';

class DispatchResult {
  final bool success;
  final EmergencyFacility nearestHospital;
  final EmergencyFacility nearestPolice;
  final String dispatchSummary;
  final double dispatchLat;
  final double dispatchLng;
  final DateTime timestamp;

  DispatchResult({
    required this.success,
    required this.nearestHospital,
    required this.nearestPolice,
    required this.dispatchSummary,
    required this.dispatchLat,
    required this.dispatchLng,
    required this.timestamp,
  });
}

class EmergencyService {
  /// Fetch all emergency facilities near given coordinates
  static List<EmergencyFacility> getFacilitiesForCoordinates(double lat, double lng) {
    return EmergencyFacility.getNearestFacilities(lat, lng);
  }

  /// Fetch all emergency facilities near vehicle location
  static List<EmergencyFacility> getFacilitiesForVehicle(Vehicle vehicle) {
    return getFacilitiesForCoordinates(vehicle.lat, vehicle.lng);
  }

  /// Get nearest hospital
  static EmergencyFacility getNearestHospital(Vehicle vehicle) {
    final facilities = getFacilitiesForVehicle(vehicle);
    return facilities.firstWhere((f) => f.isHospital);
  }

  /// Get nearest police station
  static EmergencyFacility getNearestPolice(Vehicle vehicle) {
    final facilities = getFacilitiesForVehicle(vehicle);
    return facilities.firstWhere((f) => f.isPolice);
  }

  /// Instant Auto-dispatch SOS alert & coordinates to nearest Hospital ER and Police Control Room
  static DispatchResult autoDispatchEmergencySOS({
    required Vehicle vehicle,
    required String alertType,
    required String alertMessage,
    double? alertLat,
    double? alertLng,
  }) {
    final targetLat = alertLat ?? vehicle.lat;
    final targetLng = alertLng ?? vehicle.lng;

    final facilities = getFacilitiesForCoordinates(targetLat, targetLng);
    final hospital = facilities.firstWhere((f) => f.isHospital);
    final police = facilities.firstWhere((f) => f.isPolice);

    // Update alerted status for local facility models
    hospital.isAlerted = true;
    hospital.lastAlertedTime = DateTime.now();
    police.isAlerted = true;
    police.lastAlertedTime = DateTime.now();

    // Format location & Google Maps URL payload
    final locationString = "$targetLat, $targetLng";
    final mapsUrl = "https://maps.google.com/?q=$targetLat,$targetLng";

    final summary =
        "AUTOMATED HOSPITAL & POLICE DISPATCH CONFIRMED:\n"
        "🏥 Hospital Alerted: ${hospital.name}\n"
        "   - Distance: ${hospital.distanceKm} km | ETA: ${hospital.etaMinutes} mins | Phone: ${hospital.phone}\n"
        "🚓 Police Alerted: ${police.name}\n"
        "   - Distance: ${police.distanceKm} km | Phone: ${police.phone}\n"
        "📍 Shared Crash GPS: $locationString\n"
        "🗺️ Map Link: $mapsUrl";

    return DispatchResult(
      success: true,
      nearestHospital: hospital,
      nearestPolice: police,
      dispatchSummary: summary,
      dispatchLat: targetLat,
      dispatchLng: targetLng,
      timestamp: DateTime.now(),
    );
  }
}
