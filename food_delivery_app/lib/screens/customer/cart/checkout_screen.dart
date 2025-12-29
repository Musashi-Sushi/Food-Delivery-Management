import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/enums/payment_method.dart';
import '../../../models/enums/payment_status.dart';
import '../../../models/user/customer.dart';
import '../../../models/order/order.dart';
import '../../../models/user/user.dart' as domain_user;
import '../../../providers/cart_provider.dart';

import '../home/customer_home_screen.dart';
import 'stripe_checkout_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _loadingProfile = true;
  bool _placingOrder = false;
  bool _hasExistingAddress = false;
  bool _editingAddress = false;
  String _savedAddress = '';

  PaymentMethod? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    final domain = await domain_user.User.getCurrentDomainUser();
    final name = (domain?.name ?? authUser?.displayName) ?? '';
    final phone = domain?.phone ?? '';
    final address = domain?.address ?? '';

    setState(() {
      _nameController.text = name;
      _phoneController.text = phone;
      _savedAddress = address;
      _hasExistingAddress = address.isNotEmpty;
      _loadingProfile = false;
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty.')));
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    // Decide which address we are using.
    String deliveryAddress;
    if (_hasExistingAddress && !_editingAddress) {
      deliveryAddress = _savedAddress;
    } else {
      deliveryAddress = _addressController.text.trim();
      if (deliveryAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a delivery address.')),
        );
        return;
      }
    }

    var paymentStatus = PaymentStatus.pending;

    // Handle Stripe flow if needed.
    if (_selectedPaymentMethod == PaymentMethod.card) {
      final amount = cart.calculateTotal();
      final success =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => StripeCheckoutScreen(amount: amount),
            ),
          ) ??
          false;

      if (!success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment was cancelled.')));
        return;
      }

      paymentStatus = PaymentStatus.paid;
    }

    setState(() => _placingOrder = true);

    try {
      // Block placing a new order if there is already an active one.
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to place an order.'),
          ),
        );
        return;
      }

      final hasActive = await Order.hasActiveOrderForCustomer(fbUser.uid);
      if (hasActive) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You already have an active order. Please wait until it is delivered.',
            ),
          ),
        );
        return;
      }

      final domainUser = await domain_user.User.getCurrentDomainUser();
      if (domainUser is! Customer) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only customers can place orders.')),
        );
        return;
      }

      // Attach the Riverpod cart to the domain customer for placeOrder logic.
      domainUser.cart = cart;

      final order = await domainUser.placeOrder(
        deliveryAddress: deliveryAddress,
        paymentMethod: _selectedPaymentMethod!,
        paymentStatus: paymentStatus,
      );

      await order.save();

      // Persist updated address if the user changed it or had none before.
      if (!_hasExistingAddress || _editingAddress) {
        await domain_user.User.updateAddress(deliveryAddress);
      }

      // Clear Riverpod cart state.
      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;

      // Go back to the home screen; active order banner will show progress.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) {
        setState(() => _placingOrder = false);
      }
    }
  }

  Widget _buildDeliverySection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_hasExistingAddress && !_editingAddress) ...[
              Text(
                'Deliver to this address?',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _savedAddress,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _editingAddress = true;
                      _addressController.text = _savedAddress;
                    });
                  },
                  child: const Text('Change address'),
                ),
              ),
            ],
            if (!_hasExistingAddress || _editingAddress) ...[
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 2,
                validator: (value) {
                  if (!_hasExistingAddress || _editingAddress) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your delivery address';
                    }
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment method',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            RadioListTile<PaymentMethod>(
              value: PaymentMethod.cash,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value);
              },
              title: const Text('Cash on delivery'),
            ),
            RadioListTile<PaymentMethod>(
              value: PaymentMethod.card,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value);
              },
              title: const Text('Card (Stripe)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    dynamic cart,
    double subtotal,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items (${cart.totalItems})'),
                Text('\$${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox.shrink(),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: cart.totalItems == 0 || _placingOrder
                    ? null
                    : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _placingOrder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Place order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = cart.calculateTotal();
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      backgroundColor: AppColors.lightPeachBackground,
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Form(
                      key: _formKey,
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildDeliverySection(context),
                                      const SizedBox(height: 16),
                                      _buildPaymentSection(context),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: _buildSummarySection(
                                    context,
                                    cart,
                                    subtotal,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDeliverySection(context),
                                const SizedBox(height: 16),
                                _buildPaymentSection(context),
                                const SizedBox(height: 16),
                                _buildSummarySection(context, cart, subtotal),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
