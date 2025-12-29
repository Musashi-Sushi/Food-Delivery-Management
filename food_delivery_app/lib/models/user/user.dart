import 'package:firebase_auth/firebase_auth.dart' show UserCredential;
import '../../services/auth/auth_service.dart';
import '../../models/enums/user_type.dart';

abstract class User {
  String id;
  String name;
  String email;
  String phone;
  String password;
  DateTime createdAt;
  String address;
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.createdAt,
    this.address = '',
  });

  Future<void> login({required String email, required String password});
  Future<void> logout();
  Future<void> updateProfile({String? name, String? phone, String? address});

  static Future<UserCredential> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
  }) async {
    final auth = AuthService();
    return auth.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      userType: userType,
    );
  }

  static Future<void> staticLogin({
    required String email,
    required String password,
  }) async {
    final auth = AuthService();
    await auth.login(email: email, password: password);
  }

  static Future<dynamic> getCurrentDomainUser() async {
    final auth = AuthService();
    return auth.getCurrentDomainUser();
  }

  static Future<void> staticLogout() async {
    final auth = AuthService();
    await auth.logout();
  }

  static Future<void> updateAddress(String newAddress) async {
    final auth = AuthService();
    await auth.updateAddress(newAddress);
  }

  static Future<void> staticUpdateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    final auth = AuthService();
    await auth.updateProfile(name: name, phone: phone, address: address);
  }
}
