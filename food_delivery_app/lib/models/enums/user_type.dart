/// High-level type of user in the system.
enum UserType { customer, restaurantOwner, rider }

extension UserTypeFirestore on UserType {
  String get firestoreValue {
    switch (this) {
      case UserType.customer:
        return 'customer';
      case UserType.restaurantOwner:
        return 'restaurant_owner';
      case UserType.rider:
        return 'rider';
    }
  }

  static UserType fromFirestore(String? value) {
    switch (value) {
      case 'restaurant_owner':
        return UserType.restaurantOwner;
      case 'rider':
        return UserType.rider;
      case 'customer':
      default:
        return UserType.customer;
    }
  }
}
