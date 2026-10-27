import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/vehicle_card.dart';
import 'vehicle_login_dialog.dart';
import 'vehicle_dashboard_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  late List<Vehicle> _fleet;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fleet = Vehicle.getInitialFleet();
  }

  int get _onlineCount =>
      _fleet.where((v) => v.status.toLowerCase() == 'online').length;

  List<Vehicle> get _filteredFleet {
    if (_searchQuery.isEmpty) return _fleet;
    return _fleet
        .where((v) =>
            v.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            v.driverName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onVehicleSelected(Vehicle vehicle) {
    if (vehicle.isAuthenticated) {
      // Already authenticated -> Open dashboard directly
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VehicleDashboardScreen(vehicle: vehicle),
        ),
      );
    } else {
      // Show Glass Login Modal for this vehicle
      showDialog(
        context: context,
        builder: (context) => VehicleLoginDialog(
          vehicle: vehicle,
          onLoginSuccess: (authenticatedVehicle) {
            setState(() {
              final index =
                  _fleet.indexWhere((v) => v.id == authenticatedVehicle.id);
              if (index != -1) {
                _fleet[index] = authenticatedVehicle;
              }
            });

            // Navigate to Dashboard
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    VehicleDashboardScreen(vehicle: authenticatedVehicle),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassTheme.buildAmbientBackground(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              GlassTheme.primaryCyan,
                              GlassTheme.accentPurple,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: GlassTheme.primaryCyan.withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "VisionGuard",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "Fleet Control Matrix",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: GlassTheme.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GlassTheme.glassBorderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: GlassTheme.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Live Sync",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Stats Card (Fleet Total & Status)
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      icon: Icons.directions_car_rounded,
                      title: "Total Vehicles",
                      value: "${_fleet.length}",
                      valueColor: GlassTheme.primaryCyan,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.12),
                    ),
                    _buildStatColumn(
                      icon: Icons.wifi_tethering_rounded,
                      title: "Active Fleet",
                      value: "$_onlineCount Online",
                      valueColor: GlassTheme.successGreen,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.12),
                    ),
                    _buildStatColumn(
                      icon: Icons.health_and_safety_rounded,
                      title: "System Status",
                      value: "Optimal",
                      valueColor: GlassTheme.accentPurple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GlassTheme.glassBorderColor),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search vehicle by ID or driver...",
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Fleet Inventory (${_filteredFleet.length})",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    "Select to Login",
                    style: TextStyle(
                      color: GlassTheme.primaryCyan.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Fleet List
              Expanded(
                child: _filteredFleet.isEmpty
                    ? Center(
                        child: Text(
                          "No vehicles match your search query",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredFleet.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final vehicle = _filteredFleet[index];
                          return VehicleCard(
                            vehicle: vehicle,
                            onSelectVehicle: () => _onVehicleSelected(vehicle),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: valueColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
