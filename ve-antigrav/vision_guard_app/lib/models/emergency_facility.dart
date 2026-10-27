import 'dart:math';

class EmergencyFacility {
  final String id;
  final String name;
  final String type; // 'hospital' or 'police'
  final double distanceKm;
  final String phone;
  final String address;
  final int etaMinutes;
  final double lat;
  final double lng;
  bool isAlerted;
  DateTime? lastAlertedTime;

  EmergencyFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.phone,
    required this.address,
    required this.etaMinutes,
    required this.lat,
    required this.lng,
    this.isAlerted = false,
    this.lastAlertedTime,
  });

  bool get isHospital => type.toLowerCase() == 'hospital';
  bool get isPolice => type.toLowerCase() == 'police';

  // Generate nearest hospitals and police stations based on vehicle GPS coordinates
  static List<EmergencyFacility> getNearestFacilities(double vehicleLat, double vehicleLng) {
    return [
      // Hospitals
      EmergencyFacility(
        id: "HOSP-01",
        name: "City Trauma & Emergency Super Speciality Hospital",
        type: "hospital",
        distanceKm: 1.4,
        phone: "+91 98765 43210 / 102",
        address: "Plot 12, Medical Corridor, Near Highway Toll",
        etaMinutes: 4,
        lat: vehicleLat + 0.008,
        lng: vehicleLng + 0.005,
      ),
      EmergencyFacility(
        id: "HOSP-02",
        name: "St. Jude Critical Care Center & ICU",
        type: "hospital",
        distanceKm: 2.8,
        phone: "+91 98765 11223",
        address: "Sector 44 Bypass Road, Ring Road North",
        etaMinutes: 8,
        lat: vehicleLat - 0.012,
        lng: vehicleLng + 0.010,
      ),
      EmergencyFacility(
        id: "HOSP-03",
        name: "Apex Multispeciality Trauma Center",
        type: "hospital",
        distanceKm: 4.1,
        phone: "+91 98111 22334",
        address: "Expressway Exit 7, Knowledge Park",
        etaMinutes: 11,
        lat: vehicleLat + 0.020,
        lng: vehicleLng - 0.015,
      ),

      // Police Stations
      EmergencyFacility(
        id: "POLICE-01",
        name: "Central Highway Patrol & Rapid Response HQ",
        type: "police",
        distanceKm: 0.9,
        phone: "+91 98765 99999 / 112",
        address: "Highway Junction Post 4, Grand Trunk Road",
        etaMinutes: 3,
        lat: vehicleLat - 0.004,
        lng: vehicleLng - 0.003,
      ),
      EmergencyFacility(
        id: "POLICE-02",
        name: "District Traffic & Emergency Control Command",
        type: "police",
        distanceKm: 2.2,
        phone: "+91 98100 88888",
        address: "Civil Lines, Near Metro Interchange",
        etaMinutes: 6,
        lat: vehicleLat + 0.011,
        lng: vehicleLng + 0.009,
      ),
      EmergencyFacility(
        id: "POLICE-03",
        name: "Sector 62 Police Response Station",
        type: "police",
        distanceKm: 3.5,
        phone: "+91 98700 77777",
        address: "Institutional Area, Phase 2",
        etaMinutes: 9,
        lat: vehicleLat - 0.018,
        lng: vehicleLng - 0.012,
      ),
    ];
  }
}
