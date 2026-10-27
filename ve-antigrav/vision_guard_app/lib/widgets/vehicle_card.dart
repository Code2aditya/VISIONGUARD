import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../theme/glass_theme.dart';
import 'glass_card.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onSelectVehicle;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onSelectVehicle,
  });

  Color _getStatusColor() {
    switch (vehicle.status.toLowerCase()) {
      case 'online':
        return GlassTheme.successGreen;
      case 'warning':
        return GlassTheme.warningAmber;
      case 'offline':
      default:
        return GlassTheme.alertRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16.0),
      onTap: onSelectVehicle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: ID Badge & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GlassTheme.primaryCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GlassTheme.primaryCyan.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car_filled_rounded,
                      color: GlassTheme.primaryCyan,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      vehicle.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.8),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      vehicle.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Vehicle Name & Driver
          Text(
            vehicle.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                "Driver: ${vehicle.driverName}",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: GlassTheme.alertRed,
                size: 15,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  vehicle.locationAddress,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metrics Bar: Battery, Signal, Speed
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  icon: Icons.battery_charging_full_rounded,
                  label: "${vehicle.batteryLevel}%",
                  color: vehicle.batteryLevel > 20
                      ? GlassTheme.successGreen
                      : GlassTheme.alertRed,
                ),
                _buildDivider(),
                _buildMetricItem(
                  icon: Icons.wifi_rounded,
                  label: "${vehicle.signalStrength}%",
                  color: GlassTheme.primaryCyan,
                ),
                _buildDivider(),
                _buildMetricItem(
                  icon: Icons.speed_rounded,
                  label: "${vehicle.speedKmh.toStringAsFixed(0)} km/h",
                  color: GlassTheme.accentPurple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Button: Tap to Login / Access
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        GlassTheme.primaryCyan.withOpacity(0.25),
                        GlassTheme.accentPurple.withOpacity(0.25),
                      ],
                    ),
                    border: Border.all(
                      color: GlassTheme.primaryCyan.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vehicle.isAuthenticated
                            ? "Access Vehicle Dashboard"
                            : "Select Vehicle & Login",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: GlassTheme.primaryCyan,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withOpacity(0.12),
    );
  }
}
