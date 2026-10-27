import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/vehicle.dart';
import '../models/emergency_facility.dart';
import '../services/emergency_service.dart';
import '../theme/glass_theme.dart';
import 'glass_card.dart';

class LocationMapCard extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback onOpenEmergencyFacilities;

  const LocationMapCard({
    super.key,
    required this.vehicle,
    required this.onOpenEmergencyFacilities,
  });

  @override
  State<LocationMapCard> createState() => _LocationMapCardState();
}

class _LocationMapCardState extends State<LocationMapCard> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    _mapController.move(
      LatLng(widget.vehicle.lat, widget.vehicle.lng),
      15.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclePos = LatLng(widget.vehicle.lat, widget.vehicle.lng);
    final hospital = EmergencyService.getNearestHospital(widget.vehicle);
    final police = EmergencyService.getNearestPolice(widget.vehicle);

    final hospitalPos = LatLng(hospital.lat, hospital.lng);
    final policePos = LatLng(police.lat, police.lng);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Overflow Protection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.map_rounded,
                      color: GlassTheme.primaryCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        "Vehicle Location & Map",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _recenterMap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: GlassTheme.primaryCyan.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GlassTheme.primaryCyan.withOpacity(0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.center_focus_strong_rounded,
                        color: GlassTheme.primaryCyan,
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: GlassTheme.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: GlassTheme.successGreen.withOpacity(0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          color: GlassTheme.successGreen,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "GPS ACTIVE",
                          style: TextStyle(
                            color: GlassTheme.successGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Real Interactive Map Widget (OpenStreetMap + FlutterMap)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1B2333),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GlassTheme.primaryCyan.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: vehiclePos,
                      initialZoom: 14.2,
                    ),
                    children: [
                      // OpenStreetMap Tile Layer
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.vision_guard_app',
                      ),
                      // Custom Markers Layer
                      MarkerLayer(
                        markers: [
                          // 🚗 Vehicle Location Marker
                          Marker(
                            point: vehiclePos,
                            width: 60,
                            height: 60,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: GlassTheme.primaryCyan,
                                    boxShadow: [
                                      BoxShadow(
                                        color: GlassTheme.primaryCyan
                                            .withOpacity(0.6),
                                        blurRadius: 12,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.directions_car_filled_rounded,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 🏥 Nearest Hospital Marker
                          Marker(
                            point: hospitalPos,
                            width: 36,
                            height: 36,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: GlassTheme.alertRed,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: GlassTheme.alertRed.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),

                          // 🚓 Nearest Police Station Marker
                          Marker(
                            point: policePos,
                            width: 36,
                            height: 36,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: GlassTheme.accentPurple,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: GlassTheme.accentPurple
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_police_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Map Legend Badge Overlay
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              color: GlassTheme.primaryCyan, size: 8),
                          SizedBox(width: 4),
                          Text("Vehicle",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10)),
                          SizedBox(width: 8),
                          Icon(Icons.circle,
                              color: GlassTheme.alertRed, size: 8),
                          SizedBox(width: 4),
                          Text("Hospital",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10)),
                          SizedBox(width: 8),
                          Icon(Icons.circle,
                              color: GlassTheme.accentPurple, size: 8),
                          SizedBox(width: 4),
                          Text("Police",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Address & Coordinates Info
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: GlassTheme.alertRed,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.vehicle.locationAddress,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26.0),
            child: Text(
              "Lat: ${widget.vehicle.lat}  •  Lng: ${widget.vehicle.lng}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Button to Open Nearest Emergency Facilities with Overflow Protection
          InkWell(
            onTap: widget.onOpenEmergencyFacilities,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: GlassTheme.alertRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: GlassTheme.alertRed.withOpacity(0.5),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_hospital_rounded,
                    color: GlassTheme.alertRed,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Nearest Hospitals & Police Stations",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: GlassTheme.alertRed,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
