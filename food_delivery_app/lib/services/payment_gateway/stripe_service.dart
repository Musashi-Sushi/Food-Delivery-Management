class StripeService {
  const StripeService();

  Future<bool> startCheckout({required double amount}) async {
    await Future.delayed(const Duration(seconds: 1));
    return true; // Always succeed for this demo.
  }
}
