/// Account status for a user profile.
enum UserStatus {
  active,
  inactive,
  banned,
}

extension UserStatusFirestore on UserStatus {
  String get firestoreValue {
    switch (this) {
      case UserStatus.active:
        return 'active';
      case UserStatus.inactive:
        return 'inactive';
      case UserStatus.banned:
        return 'banned';
    }
  }

  static UserStatus fromFirestore(String? value) {
    switch (value) {
      case 'inactive':
        return UserStatus.inactive;
      case 'banned':
        return UserStatus.banned;
      case 'active':
      default:
        return UserStatus.active;
    }
  }
}