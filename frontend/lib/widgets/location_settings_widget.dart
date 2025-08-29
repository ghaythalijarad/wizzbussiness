import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../l10n/app_localizations.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import '../core/theme/app_colors.dart';

class LocationSettingsWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Function(double?, double?, String?) onLocationChanged;
  final bool isLoading;

  const LocationSettingsWidget({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onLocationChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  _LocationSettingsWidgetState createState() => _LocationSettingsWidgetState();
}

class _LocationSettingsWidgetState extends State<LocationSettingsWidget> {
  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isLoading = false;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _address = widget.initialAddress;
    _updateControllers();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LocationSettingsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLatitude != oldWidget.initialLatitude ||
        widget.initialLongitude != oldWidget.initialLongitude ||
        widget.initialAddress != oldWidget.initialAddress) {
      setState(() {
        _latitude = widget.initialLatitude;
        _longitude = widget.initialLongitude;
        _address = widget.initialAddress;
      });
      _updateControllers();
    }
  }

  void _updateControllers() {
    _latitudeController.text = _latitude?.toString() ?? '';
    _longitudeController.text = _longitude?.toString() ?? '';
  }

  void _onCoordinatesChanged() {
    final lat = double.tryParse(_latitudeController.text);
    final lng = double.tryParse(_longitudeController.text);
    
    if (lat != null && lng != null) {
      setState(() {
        _latitude = lat;
        _longitude = lng;
      });
      widget.onLocationChanged(_latitude, _longitude, _address);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentLocationMap = await LocationService.getCurrentLocation();
      if (currentLocationMap != null && mounted) {
        final latitude = currentLocationMap['latitude']!;
        final longitude = currentLocationMap['longitude']!;
        
        setState(() {
          _latitude = latitude;
          _longitude = longitude;
        });
        _updateControllers();

        // Get address from coordinates
        final address = await LocationService.getAddressFromCoordinates(
          latitude: latitude,
          longitude: longitude,
        );

        final finalAddress = (address == null ||
                address == 'Address not available (stub implementation)' ||
                address == 'Address not available')
            ? null
            : address;

        setState(() {
          _address = finalAddress;
        });

        // Notify parent widget
        widget.onLocationChanged(_latitude, _longitude, finalAddress);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location retrieved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.enableLocationServices),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.businessLocation,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              localizations.businessLocationDescription,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // GPS Coordinates Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latitudeController,
                    decoration: InputDecoration(
                      labelText: localizations.latitude,
                      hintText: '33.3152',
                      prefixIcon: const Icon(Icons.navigation),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _onCoordinatesChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    decoration: InputDecoration(
                      labelText: localizations.longitude,
                      hintText: '44.3661',
                      prefixIcon: const Icon(Icons.navigation),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _onCoordinatesChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current Location Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || widget.isLoading) 
                    ? null 
                    : _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00c1e8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: (_isLoading || widget.isLoading)
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Get Current Location'),
              ),
            ),
            
            // Location Status
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          localizations.locationSet,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    if (_address != null && _address!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _address!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localizations.noLocationSet,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
