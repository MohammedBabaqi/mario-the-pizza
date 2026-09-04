import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../utils/app_snackbar.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/order_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/mario_button.dart';

/// Checkout Screen — Address, Phone Number, Free Map/GPS, and Payment Method.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _aptController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLocatingGPS = false;

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'Credit / Debit Card',
    'Apple Pay / Google Pay',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final checkoutVM = context.read<CheckoutViewModel>();
      final authVM = context.read<AuthViewModel>();
      final user = authVM.user;

      if (user != null) {
        if (user.defaultAddress != null && user.defaultAddress!.isNotEmpty) {
          _addressController.text = user.defaultAddress!;
        }
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          _phoneController.text = user.phoneNumber!;
        }
      }

      checkoutVM.reset();
      checkoutVM.onAddressChanged(_addressController.text);
      checkoutVM.onPhoneChanged(_phoneController.text);
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _aptController.dispose();
    _instructionsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _locateWithGPS() async {
    setState(() => _isLocatingGPS = true);
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

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'MarioPizzaDeliveryApp/1.0 (contact: info@mario.com)',
        'Accept': 'application/json',
      });

      String detected = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ?? address['suburb'] ?? address['neighbourhood'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['county'] ?? '';
          final country = address['country'] ?? '';
          final parts = [road, city, country].where((p) => p.toString().isNotEmpty).toList();
          if (parts.isNotEmpty) detected = parts.join(', ');
        }
      }

      _addressController.text = detected;
      if (mounted) {
        context.read<CheckoutViewModel>().onAddressChanged(detected);
        showMarioSnackBar(context, 'GPS location found! 📍');
      }
    } catch (_) {
      if (mounted) showMarioSnackBar(context, 'Could not get GPS location. Select on map');
    } finally {
      if (mounted) setState(() => _isLocatingGPS = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();
    final checkoutVM = context.watch<CheckoutViewModel>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text),
          onPressed: () => Navigation.goBack(context),
        ),
        title: Text(
          'Checkout',
          style: AppTypography.headlineSmall.copyWith(
            color: context.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          children: [
            // Delivery Address Card
            Text('Delivery Address', style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              color: context.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.border),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _addressController,
                      style: TextStyle(color: context.text),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter your delivery address...',
                        hintStyle: TextStyle(color: context.textSecondary),
                        prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.border),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter delivery address' : null,
                      onChanged: checkoutVM.onAddressChanged,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.map_rounded, color: AppColors.primary, size: 18),
                            label: const Text('Pick on Map 🗺️', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () async {
                              final selectedAddress = await Navigation.goToLocationPicker(
                                context,
                                initialAddress: _addressController.text,
                              );
                              if (selectedAddress != null && selectedAddress.isNotEmpty) {
                                setState(() {
                                  _addressController.text = selectedAddress;
                                });
                                if (context.mounted) {
                                  checkoutVM.onAddressChanged(selectedAddress);
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: _isLocatingGPS
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                                  )
                                : const Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 18),
                            label: const Text('GPS Auto 📍', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: _isLocatingGPS ? null : _locateWithGPS,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _aptController,
                            style: TextStyle(color: context.text, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Apt / Suite / Floor (Opt)',
                              hintStyle: TextStyle(color: context.textSecondary, fontSize: 12),
                              prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _instructionsController,
                            style: TextStyle(color: context.text, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Gate code / Driver Note (Opt)',
                              hintStyle: TextStyle(color: context.textSecondary, fontSize: 12),
                              prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Contact Phone Number Card
            Text('Contact Phone Number', style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              color: context.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.border),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: context.text),
                  decoration: InputDecoration(
                    hintText: '+966 50 123 4567 or +967 771 234 567',
                    hintStyle: TextStyle(color: context.textSecondary),
                    prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your phone number';
                    if (val.replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
                      return 'Phone number must have at least 7 digits';
                    }
                    return null;
                  },
                  onChanged: checkoutVM.onPhoneChanged,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment Method Card (Meets Card requirement)
            Text('Payment Method', style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              color: context.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.border),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: _paymentMethods.map((method) {
                    final isSelected = checkoutVM.paymentMethod == method;
                    IconData icon;
                    if (method.contains('Cash')) {
                      icon = Icons.payments_rounded;
                    } else if (method.contains('Card')) {
                      icon = Icons.credit_card_rounded;
                    } else {
                      icon = Icons.account_balance_wallet_rounded;
                    }

                    return RadioListTile<String>(
                      value: method,
                      // ignore: deprecated_member_use
                      groupValue: checkoutVM.paymentMethod,
                      activeColor: AppColors.primary,
                      title: Row(
                        children: [
                          Icon(icon, color: isSelected ? AppColors.primary : context.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            method,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected ? context.text : context.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                        if (val != null) checkoutVM.onPaymentMethodChanged(val);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Order Summary Card (Meets Card requirement)
            Text('Order Summary', style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              color: context.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.border),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...cartVM.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}x ${item.pizza.name} (${item.size.label})',
                                  style: AppTypography.bodyMedium.copyWith(color: context.text),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '\$${item.itemTotal.toStringAsFixed(2)}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: context.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: AppTypography.bodyMedium.copyWith(color: context.textSecondary)),
                        Text('\$${cartVM.subtotal.toStringAsFixed(2)}', style: AppTypography.bodyMedium.copyWith(color: context.text)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery', style: AppTypography.bodyMedium.copyWith(color: context.textSecondary)),
                        Text(
                          cartVM.deliveryFee == 0 ? 'FREE' : '\$${cartVM.deliveryFee.toStringAsFixed(2)}',
                          style: AppTypography.bodyMedium.copyWith(color: cartVM.deliveryFee == 0 ? AppColors.secondary : context.text),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: AppTypography.titleMedium.copyWith(color: context.text, fontWeight: FontWeight.bold)),
                        Text('\$${cartVM.total.toStringAsFixed(2)}', style: AppTypography.price.copyWith(fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            if (checkoutVM.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  checkoutVM.errorMessage!,
                  style: const TextStyle(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            MarioButton(
              label: 'Place Order (\$${cartVM.total.toStringAsFixed(2)})',
              isLoading: checkoutVM.isLoading,
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  String finalAddress = _addressController.text.trim();
                  final apt = _aptController.text.trim();
                  final note = _instructionsController.text.trim();
                  if (apt.isNotEmpty && !finalAddress.contains(apt)) {
                    finalAddress += ' (Apt: $apt)';
                  }
                  if (note.isNotEmpty && !finalAddress.contains(note)) {
                    finalAddress += ' · Note: $note';
                  }
                  checkoutVM.onAddressChanged(finalAddress);

                  await checkoutVM.placeOrder(
                    cartItems: cartVM.items,
                    subtotal: cartVM.subtotal,
                    deliveryFee: cartVM.deliveryFee,
                    total: cartVM.total,
                  );

                  if (context.mounted && checkoutVM.isSuccess && checkoutVM.order != null) {
                    final placedOrder = checkoutVM.order!;
                    context.read<OrderViewModel>().addOrder(placedOrder);
                    cartVM.clear();
                    Navigation.goToOrderTracking(context, placedOrder.id);
                  }
                }
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
