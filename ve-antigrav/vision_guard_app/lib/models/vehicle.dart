class Vehicle {
  final String id;
  final String name;
  final String accessId;
  final String status; // Online, Warning, Offline
  final String driverName;
  final int batteryLevel;
  final int signalStrength;
  final String ipAddress;
  final double lat;
  final double lng;
  final String locationAddress;
  final double speedKmh;
  final bool isLocked;
  bool isAuthenticated;

  Vehicle({
    required this.id,
    required this.name,
    required this.accessId,
    required this.status,
    required this.driverName,
    required this.batteryLevel,
    required this.signalStrength,
    required this.ipAddress,
    required this.lat,
    required this.lng,
    required this.locationAddress,
    required this.speedKmh,
    this.isLocked = true,
    this.isAuthenticated = false,
  });

  Vehicle copyWith({
    String? id,
    String? name,
    String? accessId,
    String? status,
    String? driverName,
    int? batteryLevel,
    int? signalStrength,
    String? ipAddress,
    double? lat,
    double? lng,
    String? locationAddress,
    double? speedKmh,
    bool? isLocked,
    bool? isAuthenticated,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      accessId: accessId ?? this.accessId,
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      signalStrength: signalStrength ?? this.signalStrength,
      ipAddress: ipAddress ?? this.ipAddress,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      locationAddress: locationAddress ?? this.locationAddress,
      speedKmh: speedKmh ?? this.speedKmh,
      isLocked: isLocked ?? this.isLocked,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  // Pre-configured Fleet Mock Data
  static List<Vehicle> getInitialFleet() {
    return [
      Vehicle(
        id: "VG-001",
        name: "Autonomous Heavy Hauler",
        accessId: "admin123",
        status: "Online",
        driverName: "Alex Mercer",
        batteryLevel: 84,
        signalStrength: 92,
        ipAddress: "10.46.201.95",
        lat: 28.7041,
        lng: 77.1025,
        locationAddress: "Grand Trunk Expressway, Sector 62, New Delhi",
        speedKmh: 42.5,
        isAuthenticated: false,
      ),
      Vehicle(
        id: "VG-002",
        name: "Express Delivery Van",
        accessId: "admin123",
        status: "Online",
        driverName: "Sarah Jenkins",
        batteryLevel: 91,
        signalStrength: 88,
        ipAddress: "10.46.201.96",
        lat: 28.7011,
        lng: 77.4425,
        locationAddress: "Knowledge Park III, Outer Ring Road, Noida",
        speedKmh: 58.0,
        isAuthenticated: false,
      ),
      Vehicle(
        id: "VG-003",
        name: "City Transit Cruiser",
        accessId: "transit2026",
        status: "Warning",
        driverName: "David Vance",
        batteryLevel: 34,
        signalStrength: 65,
        ipAddress: "10.46.201.97",
        lat: 28.6139,
        lng: 77.2090,
        locationAddress: "Connaught Place Circle, Central District",
        speedKmh: 24.0,
        isAuthenticated: false,
      ),
      Vehicle(
        id: "VG-004",
        name: "Emergency Logistics Truck",
        accessId: "rescue99",
        status: "Offline",
        driverName: "Elena Rostova",
        batteryLevel: 12,
        signalStrength: 0,
        ipAddress: "10.46.201.98",
        lat: 28.5355,
        lng: 77.3910,
        locationAddress: "Expressway Service Depot, Sector 132",
        speedKmh: 0.0,
        isAuthenticated: false,
      ),
    ];
  }
}
