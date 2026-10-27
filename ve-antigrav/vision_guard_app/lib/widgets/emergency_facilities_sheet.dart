import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/emergency_facility.dart';
import '../models/vehicle.dart';
import '../services/emergency_service.dart';
import '../theme/glass_theme.dart';
import 'glass_button.dart';

class EmergencyFacilitiesSheet extends StatefulWidget {
  final Vehicle vehicle;
  final Function(String message) onTriggerDispatch;

  const EmergencyFacilitiesSheet({
    super.key,
    required this.vehicle,
    required this.onTriggerDispatch,
  });

  @override
  State<EmergencyFacilitiesSheet> createState() =>
      _EmergencyFacilitiesSheetState();
}

class _EmergencyFacilitiesSheetState extends State<EmergencyFacilitiesSheet> {
  late List<EmergencyFacility> _facilities;
  bool _isDispatchingAll = false;

  @override
  void initState() {
    super.initState();
    _facilities = EmergencyService.getFacilitiesForVehicle(widget.vehicle);
  }

  void _dispatchSingleFacility(EmergencyFacility facility) async {
    setState(() {
      facility.isAlerted = true;
      facility.lastAlertedTime = DateTime.now();
    });

    final typeLabel = facility.isHospital ? "Hospital ER" : "Police Command";
    widget.onTriggerDispatch(
      "DISPATCHED SOS to $typeLabel: ${facility.name} (${facility.distanceKm}km away)",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: facility.isHospital
            ? GlassTheme.alertRed
            : GlassTheme.accentPurple,
        content: Text("Alert sent to ${facility.name} (${facility.phone})"),
      ),
    );
  }

  void _dispatchAllEmergencyServices() async {
    setState(() {
      _isDispatchingAll = true;
    });

    final result = await EmergencyService.autoDispatchEmergencySOS(
      vehicle: widget.vehicle,
      alertType: "CRITICAL OPERATOR SOS",
      alertMessage: "Manual Emergency Triggered by Fleet Operator",
    );

    if (mounted) {
      setState(() {
        _isDispatchingAll = false;
        for (var f in _facilities) {
          f.isAlerted = true;
          f.lastAlertedTime = DateTime.now();
        }
      });

      widget.onTriggerDispatch(result.dispatchSummary);

      Navigator.of(context).pop(); // Close sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitals = _facilities.where((f) => f.isHospital).toList();
    final policeStations = _facilities.where((f) => f.isPolice).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: GlassTheme.glassBorderColor),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTheme.blurSigmaX,
            sigmaY: GlassTheme.blurSigmaY,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag indicator
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: GlassTheme.alertRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: GlassTheme.alertRed.withOpacity(0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.emergency_rounded,
                        color: GlassTheme.alertRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Emergency Response Network",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            "Vehicle Location: ${widget.vehicle.locationAddress}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Master SOS Dispatch Button
                GlassButton(
                  text: "DISPATCH SOS TO HOSPITAL & POLICE",
                  icon: Icons.campaign_rounded,
                  color: GlassTheme.alertRed,
                  isLoading: _isDispatchingAll,
                  onPressed: _dispatchAllEmergencyServices,
                ),
                const SizedBox(height: 24),

                // Nearest Hospitals Section
                Row(
                  children: [
                    const Icon(
                      Icons.local_hospital_rounded,
                      color: GlassTheme.alertRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Nearest Hospitals & Trauma Centers",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...hospitals.map((h) => _buildFacilityCard(h)),

                const SizedBox(height: 20),

                // Nearest Police Stations Section
                Row(
                  children: [
                    const Icon(
                      Icons.local_police_rounded,
                      color: GlassTheme.accentPurple,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Nearest Police Posts & Highway Patrol",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...policeStations.map((p) => _buildFacilityCard(p)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityCard(EmergencyFacility facility) {
    final iconColor =
        facility.isHospital ? GlassTheme.alertRed : GlassTheme.accentPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: facility.isAlerted
            ? iconColor.withOpacity(0.15)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: facility.isAlerted
              ? iconColor.withOpacity(0.6)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              facility.isHospital
                  ? Icons.local_hospital_rounded
                  : Icons.local_police_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        facility.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${facility.distanceKm} km • ETA ${facility.etaMinutes} min",
                        style: const TextStyle(
                          color: GlassTheme.primaryCyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Phone: ${facility.phone}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                if (facility.isAlerted) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: GlassTheme.successGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "DISPATCH ALERT SENT",
                        style: TextStyle(
                          color: GlassTheme.successGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              facility.isAlerted ? Icons.notifications_active : Icons.send_rounded,
              color: facility.isAlerted ? GlassTheme.successGreen : iconColor,
              size: 22,
            ),
            onPressed: () => _dispatchSingleFacility(facility),
          ),
        ],
      ),
    );
  }
}
