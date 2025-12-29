# Food Delivery App — Class Usage Guide

This guide helps you quickly find which class is used where and how across the Flutter/Riverpod codebase. It links key classes to their files and shows primary call sites so you can trace flows end‑to‑end.

## Overview
- Entry point: `lib/main.dart:16` defines `MyApp`, sets theme and `home` to `SplashScreen`.
- Role routing: `lib/screens/splash/splash_screen.dart:52–78` sends users to Customer, Restaurant Owner, or Rider screens based on profile.
- State management: Riverpod is used for app state (`ConsumerWidget`/`ConsumerStatefulWidget`, `StateNotifierProvider`).
- Data: Firestore services under `lib/services/firestore/` handle persistence; models in `lib/models/` encapsulate domain logic.

## Entry & Routing
- `lib/main.dart:16` — `MyApp` extends `StatelessWidget`; sets `home: SplashScreen` at `lib/main.dart:25`.
- `lib/screens/splash/splash_screen.dart:15` — `SplashScreen` animates then calls `_goToHome()` at `lib/screens/splash/splash_screen.dart:52`.
  - Customer → `CustomerHomeScreen` at `lib/screens/customer/home/customer_home_screen.dart:20` (selected at `lib/screens/splash/splash_screen.dart:67`).
  - Restaurant Owner → `OwnerRestaurantSelectorScreen` at `lib/screens/restaurant/selector/owner_restaurant_selector_screen.dart:22` (selected at `lib/screens/splash/splash_screen.dart:69`).
  - Rider → `RiderDashboardScreen` at `lib/screens/rider/dashboard/rider_dashboard_screen.dart:13` (selected at `lib/screens/splash/splash_screen.dart:71`).
  - Unauthenticated → `LoginScreen` at `lib/screens/auth/login_screen.dart:15` (navigated at `lib/screens/splash/splash_screen.dart:57–60`).

## State Management (Riverpod)
- `lib/providers/cart_provider.dart:7` — `CartNotifier extends StateNotifier<Cart>` manages cart state; exposed as `cartProvider` at `lib/providers/cart_provider.dart:47`.
- `lib/providers/delivery_provider.dart:7–55` — Providers for rider deliveries:
  - `deliveriesCollectionProvider` at `:7` binds Firestore collection.
  - `currentRiderProvider` at `:13` reads `FirebaseAuth.currentUser`.
  - `deliveriesByStatusProvider` at `:18` streams deliveries by status.
  - `assignedDeliveriesProvider` at `:36` and `completedDeliveriesProvider` at `:51` used by `RiderDashboardScreen`.

## Services (Firestore, Auth, Location, Payments)
- `lib/services/auth/auth_service.dart:8` — `AuthService` wraps Firebase Auth, profile CRUD via `UserService`.
  - Used by domain `User` static methods at `lib/models/user/user.dart:27–75`.
- `lib/services/firestore/user_service.dart:13` — `UserService` handles Firestore profile docs.
- `lib/services/firestore/order_service.dart:5` — `OrderService` persists orders; `Order.save()` calls it at `lib/models/order/order.dart:74–79`.
- `lib/services/firestore/restaurant_service.dart:4` — `RestaurantRepository`; `lib/services/firestore/restaurant_service.dart:18` — `RestaurantService` for restaurant data.
- `lib/services/firestore/delivery_service.dart:5` — `DeliveryService` streams available requests; consumed by `availableRequestsProvider` at `lib/providers/delivery_provider.dart:54–56`.
- `lib/services/location/location_service.dart:13` — `LocationService` and `AppLocation` at `lib/services/location/location_service.dart:4` for rider location utilities.
- `lib/services/payment_gateway/stripe_service.dart:1` — `StripeService` used by `StripeCheckoutScreen` at `lib/screens/customer/cart/stripe_checkout_screen.dart:17`.

## Models (Domain)
- `lib/models/order/order.dart:9` — `Order` domain object
  - Persists via `OrderService.saveOrder()` at `lib/services/firestore/order_service.dart:54–100`.
  - Updates via `updateOrderFields()` at `lib/services/firestore/order_service.dart:102–109`.
- `lib/models/order/cart.dart:4` — `Cart` with items and totals; mutated by `CartNotifier`.
- `lib/models/order/cart_item.dart:3` — `CartItem` line item.
- `lib/models/order/order_item.dart:1` — `OrderItem` for persisted items.
- `lib/models/delivery/delivery.dart:5` — `Delivery` model used by rider flows.
- `lib/models/restaurant/restaurant.dart:7` — `Restaurant` (owner side; menu, approval status).
- `lib/models/restaurant/menu_item.dart:1` — `MenuItem` with price/category.
- `lib/models/restaurant/category.dart:1` and `category_registry.dart:3` — Category metadata.
- `lib/models/user/user.dart:5` — Abstract `User` with static helpers to `AuthService`.
  - `Customer` at `lib/models/user/customer.dart:16`.
  - `DeliveryPerson` at `lib/models/user/delivery_person.dart:11`.
  - `RestaurantOwner` at `lib/models/user/restaurant_owner.dart:15`.

## Screens — Customer
- `lib/screens/customer/home/customer_home_screen.dart:20` — `CustomerHomeScreen` root for customers.
- `lib/screens/customer/restaurant/restaurant_detail_screen.dart:12` — `RestaurantDetailScreen` shows menu and details.
- `lib/screens/customer/cart/cart_screen.dart:10` — `CartScreen` uses `cartProvider` to render and mutate cart; state updates in `CartNotifier` at `lib/providers/cart_provider.dart:10–45`.
- `lib/screens/customer/cart/checkout_screen.dart:15` — `CheckoutScreen` handles checkout flow.
- `lib/screens/customer/cart/stripe_checkout_screen.dart:6` — `StripeCheckoutScreen` triggers `StripeService.startCheckout()` at `lib/screens/customer/cart/stripe_checkout_screen.dart:22–24`.
- `lib/screens/customer/orders/track_order_screen.dart:10` — `TrackOrderScreen` displays order steps; internal `_OrderStep` at `:424`.
- `lib/screens/customer/orders/order_confirmation_screen.dart:7` — `OrderConfirmationScreen` shows success.
- `lib/screens/customer/profile/profile_screen.dart:12` — `ProfileScreen` for customer profile.
- Widgets:
  - `lib/screens/customer/cart/widgets/cart_item_card.dart:6` — `CartItemCard`.
  - `lib/screens/customer/cart/widgets/price_breakdown.dart:6` — `PriceBreakdown`.
  - `lib/screens/customer/home/widgets/order_status.dart:6` — `OrderStatusBanner`.
  - `lib/screens/customer/home/widgets/restaurant_card.dart:7` — `RestaurantCard`.
  - `lib/screens/customer/home/widgets/category_chip.dart:6` — `CategoryChip`.
  - `lib/screens/customer/home/widgets/search_bar.dart:5` — `HomeSearchBar`.

## Screens — Restaurant Owner
- `lib/screens/restaurant/selector/owner_restaurant_selector_screen.dart:22` — `OwnerRestaurantSelectorScreen` entry for owners after splash.
- `lib/screens/restaurant/dashboard/restaurant_dashboard_screen.dart:18` — `RestaurantDashboardScreen` owner analytics and charts.
  - Internal `_OwnerStats` at `:140`, `_RestaurantDashboardScreenState` at `:209`, `_LineChart` at `:1166`, `_LineChartPainter` at `:1178`.
- `lib/screens/restaurant/menu/owner_menu_screen.dart:16` — `OwnerMenuScreen` lists and edits menu items; loads via `Restaurant.getMenu()` at `lib/screens/restaurant/menu/owner_menu_screen.dart:34–41`.
- `lib/screens/restaurant/orders/owner_orders_screen.dart:57` — `OwnerOrdersScreen` lists orders.
- `lib/screens/restaurant/settings/owner_settings_screen.dart:17` — `OwnerSettingsScreen` for owner profile/settings.

## Screens — Rider
- `lib/screens/rider/dashboard/rider_dashboard_screen.dart:13` — `RiderDashboardScreen` main rider UI.
  - Consumes `assignedDeliveriesProvider` and `completedDeliveriesProvider` at `:37–38`.
  - Profile tab renders `RiderProfileScreen` at `:109`.
- `lib/screens/rider/profile/rider_profile_screen.dart:11` — `RiderProfileScreen` rider profile.

## Auth Screens
- `lib/screens/auth/login_screen.dart:15` — `LoginScreen` email/password auth.
- `lib/screens/auth/register_screen.dart:11` — `RegisterScreen`.
- `lib/screens/auth/user_type_selection_screen.dart:6` — `UserTypeSelectionScreen`.

## UI Foundation
- `lib/core/theme/app_theme.dart:4` — `AppTheme` defines `lightTheme`, used by `MyApp` at `lib/main.dart:24`.
- `lib/core/constants/app_colors.dart:4` — `AppColors` used widely for consistent colors.
- `lib/core/utils/validators.dart:1` — `Validators` helper methods for forms.
- `lib/firebase_options.dart:5` — `DefaultFirebaseOptions` platform configs for Firebase init in `main.dart:11`.

## How To Trace Usage Fast
- Use global search in your IDE for any class name to see call sites.
- For navigation targets, search `Navigator.push`/`pushReplacement` to see where screens are instantiated.
- For state, search `ref.watch(...)` to see which providers a widget reads.
- For persistence, search `FirebaseFirestore` or specific services, e.g. `OrderService`.

## Directory Map
- `lib/screens/` — UI screens and UI widgets grouped by role.
- `lib/models/` — Domain models with business logic.
- `lib/services/` — Firestore, Auth, Location, Payment integrations.
- `lib/providers/` — Riverpod providers and notifiers.
- `lib/core/` — Theme, constants, utilities.

Use the file:line references above to jump directly to definitions and primary usage points.
