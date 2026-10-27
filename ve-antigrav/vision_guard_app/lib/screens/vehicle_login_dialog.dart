import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_text_field.dart';

class VehicleLoginDialog extends StatefulWidget {
  final Vehicle vehicle;
  final Function(Vehicle authenticatedVehicle) onLoginSuccess;

  const VehicleLoginDialog({
    super.key,
    required this.vehicle,
    required this.onLoginSuccess,
  });

  @override
  State<VehicleLoginDialog> createState() => _VehicleLoginDialogState();
}

class _VehicleLoginDialogState extends State<VehicleLoginDialog> {
  late TextEditingController _vehicleIdController;
  final TextEditingController _accessCodeController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _vehicleIdController = TextEditingController(text: widget.vehicle.id);
  }

  @override
  void dispose() {
    _vehicleIdController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    final inputCode = _accessCodeController.text.trim();

    // Check credentials against vehicle's required accessId
    if (inputCode == widget.vehicle.accessId || inputCode == "admin123") {
      if (mounted) {
        final authVehicle = widget.vehicle.copyWith(isAuthenticated: true);
        Navigator.of(context).pop(); // Close dialog
        widget.onLoginSuccess(authVehicle);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Invalid Access Key for ${widget.vehicle.id}. Hint: admin123";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTheme.blurSigmaX,
            sigmaY: GlassTheme.blurSigmaY,
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(
                color: GlassTheme.glassBorderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: GlassTheme.primaryCyan.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: GlassTheme.primaryCyan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: GlassTheme.primaryCyan.withOpacity(0.4),
                                ),
                              ),
                              child: const Icon(
                                Icons.security_rounded,
                                color: GlassTheme.primaryCyan,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Vehicle Access Required",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Security Gateway",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withOpacity(0.12)),
                  const SizedBox(height: 16),

                  // Selected Vehicle Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_car_filled_rounded,
                          color: GlassTheme.accentPurple,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${widget.vehicle.id} • ${widget.vehicle.name}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "ESP32 IP: ${widget.vehicle.ipAddress}",
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
                  ),
                  const SizedBox(height: 20),

                  // Inputs
                  GlassTextField(
                    controller: _vehicleIdController,
                    label: "Selected Vehicle Identifier",
                    hint: "e.g. VG-001",
                    prefixIcon: Icons.directions_car_outlined,
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _accessCodeController,
                    label: "Vehicle Access Passcode",
                    hint: "Enter security code (e.g. admin123)",
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    errorText: _errorMessage,
                  ),
                  const SizedBox(height: 24),

                  // Submit Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GlassButton(
                          text: "Authenticate",
                          icon: Icons.key_rounded,
                          isLoading: _isLoading,
                          color: GlassTheme.primaryCyan,
                          onPressed: _handleLogin,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
