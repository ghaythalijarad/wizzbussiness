import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service_stub.dart';
import '../widgets/map_location_picker.dart';
import '../l10n/app_localizations.dart';

class LocationSettingsWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Function(double?, double?, String?) onLocationChanged;

  const LocationSettingsWidget({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onLocationChanged,
  }) : super(key: key);

  @override
  _LocationSettingsWidgetState createState() => _LocationSettingsWidgetState();
}

class _LocationSettingsWidgetState extends State<LocationSettingsWidget> {
  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _address = widget.initialAddress;
  }

  Future<void> _openMapPicker() async {
    LatLng? initialLocation;
    if (_latitude != null && _longitude != null) {
      initialLocation = LatLng(_latitude!, _longitude!);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: initialLocation,
          onLocationSelected: (LatLng location) async {
            // Extract localization string and scaffold messenger before async operations
            final localizations = AppLocalizations.of(context)!;
            final locationSavedMessage = localizations.locationSaved;
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            setState(() {
              _isLoading = true;
              _latitude = location.latitude;
              _longitude = location.longitude;
            });

            // Get address from coordinates
            final address = await LocationService.getAddressFromCoordinates(
              latitude: location['latitude'] ?? 0.0,
              longitude: location['longitude'] ?? 0.0,
            );

            setState(() {
              _address = address;
              _isLoading = false;
            });

            // Notify parent widget
            widget.onLocationChanged(_latitude, _longitude, _address);

            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(locationSavedMessage),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
      ),
    );
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
            const SizedBox(height: 16),
            if (_latitude != null && _longitude != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          localizations.locationSet,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (_address != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _address!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${localizations.latitude}: ${_latitude!.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '${localizations.longitude}: ${_longitude!.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _openMapPicker,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.edit_location),
                      label: Text(localizations.updateLocation),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_off,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          localizations.noLocationSet,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.chooseLocationOnMap,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _openMapPicker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00c1e8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.add_location),
                  label: Text(localizations.selectLocation),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
