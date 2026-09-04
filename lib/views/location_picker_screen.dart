import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_snackbar.dart';

/// Free OpenStreetMap Interactive Location Picker with device GPS permissions.
class LocationPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final MapController _mapController;
  late LatLng _selectedPoint;
  String _currentAddress = 'Locating...';
  bool _isLocating = false;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Default location (e.g. Sanaa or user initial coordinates)
    _selectedPoint = LatLng(
      widget.initialLat ?? 15.3694,
      widget.initialLng ?? 44.1910,
    );
    _currentAddress = widget.initialAddress?.isNotEmpty == true
        ? widget.initialAddress!
        : 'Select delivery pin on map';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialAddress == null || widget.initialAddress!.isEmpty) {
        _getCurrentGPSLocation();
      }
    });
  }

  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'MarioPizzaDeliveryApp/1.0 (contact: info@mario.com)',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ?? address['suburb'] ?? address['neighbourhood'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['county'] ?? address['state'] ?? '';
          final country = address['country'] ?? '';
          final parts = [road, city, country].where((p) => p.toString().isNotEmpty).toList();
          if (parts.isNotEmpty) return parts.join(', ');
        }
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName.split(',').take(3).join(',').trim();
        }
      }
    } catch (_) {}
    return 'Pin: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
  }

  Future<void> _getCurrentGPSLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) showMarioSnackBar(context, 'Please enable GPS location service');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) showMarioSnackBar(context, 'Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) showMarioSnackBar(context, 'GPS permission is permanently denied in settings');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final newPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPoint = newPoint;
        _isGeocoding = true;
      });
      _mapController.move(newPoint, 16.0);

      final addr = await _reverseGeocode(newPoint);
      if (mounted) {
        setState(() {
          _currentAddress = addr;
          _isGeocoding = false;
        });
        showMarioSnackBar(context, 'GPS location detected! 📍');
      }
    } catch (e) {
      if (mounted) {
        showMarioSnackBar(context, 'Tap on the map to set your location');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _isGeocoding = false;
        });
      }
    }
  }

  Future<void> _onMapTapped(LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _isGeocoding = true;
    });

    final addr = await _reverseGeocode(point);
    if (mounted) {
      setState(() {
        _currentAddress = addr;
        _isGeocoding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        title: Text(
          'Select Delivery Location 📍',
          style: AppTypography.titleLarge.copyWith(color: context.text, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLocating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.my_location_rounded, color: AppColors.primary),
            tooltip: 'Use GPS',
            onPressed: _isLocating ? null : _getCurrentGPSLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Free OpenStreetMap Tile Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: 15.0,
              onTap: (_, point) => _onMapTapped(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mario.pizza',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPoint,
                    width: 60,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.delivery_dining_rounded, color: AppColors.white, size: 24),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Floating GPS button on map
          Positioned(
            right: 16,
            bottom: 150,
            child: FloatingActionButton.small(
              heroTag: 'gps_fab',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              onPressed: _isLocating ? null : _getCurrentGPSLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),

          // Bottom card showing detected address & confirm button
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Spot',
                        style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_isGeocoding)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentAddress,
                    style: AppTypography.bodyMedium.copyWith(color: context.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Secondary Action: Add Apartment / Specifics (Equal 50% width)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_note_rounded, size: 19, color: AppColors.primary),
                          label: const Text(
                            'Add Details 📝',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            foregroundColor: AppColors.primary,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _showAddressDetailsModal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Primary Action: Quick Pin / Confirm (Equal 50% width)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_rounded, size: 19, color: AppColors.white),
                          label: const Text(
                            'Quick Pin 📍',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            elevation: 2,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(context, _currentAddress);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String emoji, String selected, ValueChanged<String> onSelected) {
    final isSelected = selected == label;
    return Expanded(
      child: InkWell(
        onTap: () => onSelected(label),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressDetailsModal() {
    String selectedTag = 'Apartment';
    final streetController = TextEditingController(text: _currentAddress);
    final buildingController = TextEditingController();
    final aptController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
            final subColor = isDark ? Colors.white60 : Colors.black54;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Delivery Address Details',
                          style: AppTypography.titleLarge.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Provide exact building and apartment details for the driver',
                      style: AppTypography.caption.copyWith(color: subColor),
                    ),
                    const SizedBox(height: 16),

                    // Address Type Chips
                    Text('Address Type', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeChip('House', '🏠', selectedTag, (t) => setModalState(() => selectedTag = t)),
                        const SizedBox(width: 6),
                        _buildTypeChip('Apartment', '🏢', selectedTag, (t) => setModalState(() => selectedTag = t)),
                        const SizedBox(width: 6),
                        _buildTypeChip('Office', '💼', selectedTag, (t) => setModalState(() => selectedTag = t)),
                        const SizedBox(width: 6),
                        _buildTypeChip('Other', '📍', selectedTag, (t) => setModalState(() => selectedTag = t)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Street & Area
                    Text('Street / Neighborhood', style: TextStyle(color: subColor, fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: streetController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
                        hintText: 'Street or district name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Building / Villa
                    Text(
                      selectedTag == 'House'
                          ? 'House / Villa Number'
                          : selectedTag == 'Apartment'
                              ? 'Building / Tower Name or No.'
                              : 'Building / Company Name',
                      style: TextStyle(color: subColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: buildingController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.domain_rounded, size: 20),
                        hintText: selectedTag == 'House' ? 'e.g. Villa 15' : 'e.g. Al-Noor Tower, Block B',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Apartment / Floor
                    Text('Apartment / Suite / Floor (Optional)', style: TextStyle(color: subColor, fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: aptController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.meeting_room_outlined, size: 20),
                        hintText: 'e.g. Floor 3, Apt 302',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Delivery Instructions / Landmark
                    Text('Delivery Notes / Landmark (Optional)', style: TextStyle(color: subColor, fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                        hintText: 'e.g. Ring bell twice, leave at door, gate code #1234',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final bld = buildingController.text.trim();
                        final apt = aptController.text.trim();
                        final street = streetController.text.trim();
                        final notes = notesController.text.trim();

                        final emoji = selectedTag == 'House'
                            ? '🏠'
                            : selectedTag == 'Apartment'
                                ? '🏢'
                                : selectedTag == 'Office'
                                    ? '💼'
                                    : '📍';

                        final buffer = StringBuffer('$emoji [$selectedTag] ');
                        if (bld.isNotEmpty) buffer.write('$bld, ');
                        if (apt.isNotEmpty) buffer.write('$apt, ');
                        if (street.isNotEmpty) {
                          buffer.write(street);
                        } else {
                          buffer.write(_currentAddress);
                        }
                        if (notes.isNotEmpty) buffer.write(' · Note: $notes');

                        final formatted = buffer.toString();
                        Navigator.pop(modalCtx);
                        Navigator.pop(context, formatted);
                      },
                      child: const Text(
                        'Save & Confirm Address 📍',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
