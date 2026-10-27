import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/alert_item.dart';
import '../models/emergency_facility.dart';
import '../services/vision_guard_api.dart';
import '../services/emergency_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import '../widgets/location_map_card.dart';
import '../widgets/emergency_facilities_sheet.dart';

class VehicleDashboardScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDashboardScreen({super.key, required this.vehicle});

  @override
  State<VehicleDashboardScreen> createState() => _VehicleDashboardScreenState();
}

class _VehicleDashboardScreenState extends State<VehicleDashboardScreen> {
  Timer? _alertPollTimer;
  AlertItem? _currentActiveAlert;
  final List<AlertItem> _alertLogs = [];
  bool _isConnected = true;
  bool _isSendingCommand = false;
  String _lastCommandStatus = "Ready for telemetry";
  DispatchResult? _lastDispatchResult;

  @override
  void initState() {
    super.initState();
    _startAlertPolling();
  }

  @override
  void dispose() {
    _alertPollTimer?.cancel();
    super.dispose();
  }

  void _startAlertPolling() {
    _alertPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final alert = await VisionGuardApiService.fetchLatestAlert(widget.vehicle.id);
      if (alert != null) {
        _triggerAlert(alert);
      }
    });
  }

  void _triggerAlert(AlertItem alert) {
    if (alert.type == "emergency_dispatch") {
      setState(() {
        _alertLogs.insert(0, alert);
      });
      return;
    }

    // AUTOMATIC INSTANT DISPATCH: Calculate nearest Hospital & Police Station using alert coordinates
    final dispatchRes = EmergencyService.autoDispatchEmergencySOS(
      vehicle: widget.vehicle,
      alertType: alert.type.toUpperCase(),
      alertMessage: alert.message,
      alertLat: alert.lat,
      alertLng: alert.lng,
    );

    setState(() {
      _currentActiveAlert = alert;
      _lastDispatchResult = dispatchRes;
      _alertLogs.insert(0, alert);
      _alertLogs.insert(
        1,
        AlertItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          vehicleId: widget.vehicle.id,
          type: "emergency_dispatch",
          severity: "CRITICAL",
          message:
              "HOSPITAL DISPATCH: GPS Coordinates (${dispatchRes.dispatchLat}, ${dispatchRes.dispatchLng}) shared with ${dispatchRes.nearestHospital.name} (Phone: ${dispatchRes.nearestHospital.phone})",
          timestamp: DateTime.now(),
        ),
      );
    });

    // Auto dismiss alert banner after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _currentActiveAlert?.id == alert.id) {
        setState(() {
          _currentActiveAlert = null;
        });
      }
    });
  }

  void _openEmergencyFacilitiesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmergencyFacilitiesSheet(
        vehicle: widget.vehicle,
        onTriggerDispatch: (summaryMsg) {
          final alert = AlertItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            vehicleId: widget.vehicle.id,
            type: "emergency_dispatch",
            severity: "HIGH",
            message: summaryMsg,
            timestamp: DateTime.now(),
          );
          _triggerAlert(alert);
        },
      ),
    );
  }

  void _sendRCCommand(String cmd) async {
    setState(() {
      _isSendingCommand = true;
      _lastCommandStatus = "Executing command: ${cmd.toUpperCase()}...";
    });

    final success = await VisionGuardApiService.sendEsp32Command(
      command: cmd,
      espIp: widget.vehicle.ipAddress,
    );

    if (mounted) {
      setState(() {
        _isSendingCommand = false;
        _lastCommandStatus = success
            ? "Command '${cmd.toUpperCase()}' delivered to ESP32."
            : "ESP32 timeout or unreachable (${widget.vehicle.ipAddress}).";
      });
    }
  }

  void _triggerEmergencySMS() async {
    setState(() {
      _lastCommandStatus = "Triggering CRITICAL Emergency Alert...";
    });

    final crashLocation = "${widget.vehicle.lat}, ${widget.vehicle.lng}";

    // Dispatch WhatsApp alert payload to backend asynchronously
    VisionGuardApiService.triggerEmergencyAlert(
      type: "Manual Operator Emergency",
      location: crashLocation,
    );

    final alert = AlertItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vehicleId: widget.vehicle.id,
      type: "crash",
      severity: "CRITICAL",
      message: "CRITICAL IMPACT DETECTED - WHATSAPP & HOSPITAL SOS DISPATCHED",
      location: crashLocation,
      lat: widget.vehicle.lat,
      lng: widget.vehicle.lng,
      timestamp: DateTime.now(),
    );
    _triggerAlert(alert);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GlassTheme.alertRed,
          content: Text(
            "GPS Coordinates Shared with Nearest Hospital ER & Police Control Room!",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearestHospital = EmergencyService.getNearestHospital(widget.vehicle);
    final nearestPolice = EmergencyService.getNearestPolice(widget.vehicle);

    return Scaffold(
      body: GlassTheme.buildAmbientBackground(
        Column(
          children: [
            // Top App Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GlassTheme.glassSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GlassTheme.glassBorderColor),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.vehicle.id,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: GlassTheme.successGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      GlassTheme.successGreen.withOpacity(0.5),
                                ),
                              ),
                              child: const Text(
                                "Authenticated",
                                style: TextStyle(
                                  color: GlassTheme.successGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.vehicle.name,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: GlassTheme.glassSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GlassTheme.glassBorderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_rounded,
                          color: _isConnected
                              ? GlassTheme.successGreen
                              : GlassTheme.alertRed,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.vehicle.ipAddress,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Alert Banner (If triggered)
                    if (_currentActiveAlert != null) ...[
                      _buildAlertBanner(_currentActiveAlert!),
                      const SizedBox(height: 16),
                    ],

                    // Emergency Auto-Dispatch Confirmation Badge
                    if (_lastDispatchResult != null) ...[
                      _buildDispatchStatusCard(_lastDispatchResult!),
                      const SizedBox(height: 16),
                    ],

                    // NEW FEATURE: Location Map & Geolocation Card
                    LocationMapCard(
                      vehicle: widget.vehicle,
                      onOpenEmergencyFacilities: _openEmergencyFacilitiesModal,
                    ),
                    const SizedBox(height: 16),

                    // NEW FEATURE: Nearest Emergency Services Quick Card (Hospital & Police)
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.emergency_rounded,
                                    color: GlassTheme.alertRed,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Nearest Emergency Units",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _openEmergencyFacilitiesModal,
                                child: const Text(
                                  "View All >",
                                  style: TextStyle(
                                    color: GlassTheme.primaryCyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Nearest Hospital Unit
                          _buildQuickFacilityRow(
                            facility: nearestHospital,
                            accentColor: GlassTheme.alertRed,
                            icon: Icons.local_hospital_rounded,
                          ),
                          const SizedBox(height: 10),

                          // Nearest Police Unit
                          _buildQuickFacilityRow(
                            facility: nearestPolice,
                            accentColor: GlassTheme.accentPurple,
                            icon: Icons.local_police_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Telemetry Glass Box
                    GlassCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.sensors_rounded,
                                    color: GlassTheme.primaryCyan,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Live Telemetry Stream",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "GPS Fix: Active",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricTile(
                                label: "Speed",
                                value:
                                    "${widget.vehicle.speedKmh.toStringAsFixed(1)} km/h",
                                icon: Icons.speed_rounded,
                                color: GlassTheme.primaryCyan,
                              ),
                              _buildMetricTile(
                                label: "Battery",
                                value: "${widget.vehicle.batteryLevel}%",
                                icon: Icons.battery_charging_full_rounded,
                                color: GlassTheme.successGreen,
                              ),
                              _buildMetricTile(
                                label: "Coordinates",
                                value:
                                    "${widget.vehicle.lat}, ${widget.vehicle.lng}",
                                icon: Icons.location_on_rounded,
                                color: GlassTheme.accentPurple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Remote Control Override Panel
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.gamepad_rounded,
                                    color: GlassTheme.accentPurple,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Remote Override Control",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              if (_isSendingCommand)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: GlassTheme.primaryCyan,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _lastCommandStatus,
                            style: TextStyle(
                              color: GlassTheme.primaryCyan.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // D-Pad Directional Controls
                          Center(
                            child: Column(
                              children: [
                                // Forward
                                _buildPadButton(
                                  icon: Icons.keyboard_arrow_up_rounded,
                                  label: "FORWARD",
                                  onPressed: () => _sendRCCommand("forward"),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Left
                                    _buildPadButton(
                                      icon: Icons.keyboard_arrow_left_rounded,
                                      label: "LEFT",
                                      onPressed: () => _sendRCCommand("left"),
                                    ),
                                    const SizedBox(width: 12),
                                    // STOP Button
                                    GestureDetector(
                                      onTap: () => _sendRCCommand("stop"),
                                      child: Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: GlassTheme.alertRed
                                              .withOpacity(0.25),
                                          border: Border.all(
                                            color: GlassTheme.alertRed,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: GlassTheme.alertRed
                                                  .withOpacity(0.4),
                                              blurRadius: 16,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "STOP",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Right
                                    _buildPadButton(
                                      icon: Icons.keyboard_arrow_right_rounded,
                                      label: "RIGHT",
                                      onPressed: () => _sendRCCommand("right"),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Backward
                                _buildPadButton(
                                  icon: Icons.keyboard_arrow_down_rounded,
                                  label: "REVERSE",
                                  onPressed: () => _sendRCCommand("backward"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Manual Emergency SOS Trigger Button
                    GlassButton(
                      text: "DISPATCH EMERGENCY SOS (HOSPITAL & POLICE)",
                      icon: Icons.warning_amber_rounded,
                      color: GlassTheme.alertRed,
                      height: 56,
                      onPressed: _triggerEmergencySMS,
                    ),
                    const SizedBox(height: 24),

                    // Real-Time Alert Log Feed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Alert & Dispatch Feed (${_alertLogs.length})",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_alertLogs.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _alertLogs.clear()),
                            child: Text(
                              "Clear Feed",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_alertLogs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: GlassTheme.successGreen.withOpacity(0.6),
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "No Safety Alerts Triggered",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Polling vision detector service...",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._alertLogs.map((alert) => _buildAlertTile(alert)),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFacilityRow({
    required EmergencyFacility facility,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Dist: ${facility.distanceKm} km • ETA: ${facility.etaMinutes} mins • ${facility.phone}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: GlassTheme.successGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "READY",
              style: TextStyle(
                color: GlassTheme.successGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchStatusCard(DispatchResult result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GlassTheme.alertRed.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GlassTheme.alertRed.withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: GlassTheme.alertRed.withOpacity(0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: GlassTheme.alertRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GPS COORDINATES SHARED WITH HOSPITAL ER",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      "Automated Hospital Response Active",
                      style: TextStyle(
                        color: GlassTheme.primaryCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "🏥 Hospital Alerted: ${result.nearestHospital.name} (${result.nearestHospital.distanceKm} km away • ETA ${result.nearestHospital.etaMinutes} mins)",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "📍 Shared Crash GPS: ${result.dispatchLat}, ${result.dispatchLng}",
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
          ),
          const SizedBox(height: 4),
          Text(
            "📞 Hospital Contact: ${result.nearestHospital.phone}",
            style: TextStyle(color: GlassTheme.primaryCyan, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(AlertItem alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: GlassTheme.neonGlowDecoration(color: GlassTheme.alertRed),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GlassTheme.alertRed.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CRITICAL ALERT • AUTO-SOS DISPATCHED",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "🚨 Nearest Hospital & Police Station notified automatically!",
                  style: TextStyle(
                    color: GlassTheme.primaryCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildPadButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 68,
        height: 52,
        decoration: BoxDecoration(
          color: GlassTheme.glassSurfaceHover,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GlassTheme.glassBorderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(AlertItem alert) {
    final isDispatch = alert.type == "emergency_dispatch";

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            isDispatch
                ? Icons.local_hospital_rounded
                : alert.severity == "CRITICAL"
                    ? Icons.error_rounded
                    : Icons.warning_amber_rounded,
            color: isDispatch
                ? GlassTheme.successGreen
                : alert.severity == "CRITICAL"
                    ? GlassTheme.alertRed
                    : GlassTheme.warningAmber,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}:${alert.timestamp.second.toString().padLeft(2, '0')} • Type: ${alert.type}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
