import 'package:firebase_auth/firebase_auth.dart';

import '../firestore/user_service.dart';
import '../../models/enums/user_type.dart';
import '../../models/user/user.dart' as domain_user;

/// Simple wrapper around [FirebaseAuth] for authentication + user profile.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, UserService? userService})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _userService = userService ?? UserService();

  final FirebaseAuth _auth;
  final UserService _userService;

  /// Stream of auth state changes (user logged in/out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Register a new user with email and password and create a Firestore
  /// profile document.
  Future<UserCredential> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: trimmedPassword,
    );

    final uid = credential.user!.uid;

    await _userService.createUserProfile(
      uid: uid,
      name: name,
      email: trimmedEmail,
      phone: phone,
      userType: userType,
    );

    return credential;
  }

  /// Login using email and password.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    final credential = await _auth.signInWithEmailAndPassword(
      email: trimmedEmail,
      password: trimmedPassword,
    );

    return credential;
  }

  /// Fetch the Firestore user profile for the current user.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _userService.getUserProfile(user.uid);
  }

  /// Get the typed domain user (Customer, RestaurantOwner, etc.).
  Future<domain_user.User?> getCurrentDomainUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _userService.getDomainUser(user.uid);
  }

  /// Log out the current user.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Update the current user's address in Firestore.
  Future<void> updateAddress(String newAddress) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-logged-in',
        message: 'No user is currently logged in.',
      );
    }

    await _userService.updateAddress(user.uid, newAddress.trim());
  }

  /// Update the current user's profile fields.
  Future<void> updateProfile({String? name, String? phone, String? address}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-logged-in',
        message: 'No user is currently logged in.',
      );
    }

    await _userService.updateProfileFields(
      user.uid,
      name: name?.trim(),
      phone: phone?.trim(),
      address: address?.trim(),
    );
  }

  /// Change the current user's password in Firebase Auth.
  ///
  /// Requires the current password for re-authentication.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-logged-in',
        message: 'No user is currently logged in.',
      );
    }

    final email = user.email;
    if (email == null) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'Current user does not have an email address.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword.trim(),
    );

    // Re-authenticate, then update password.
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword.trim());
  }
}
